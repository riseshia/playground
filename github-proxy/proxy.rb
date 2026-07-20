#!/usr/bin/env ruby
# frozen_string_literal: true

# GitHub pull-through cache proxy (이해용 프로토타입).
#
# 구조:
#   runner --insteadOf--> 이 서버 --+-- public/internal: 로컬 미러 + git http-backend
#                                   +-- private: github.com 리버스 프록시 (캐시 없음)
#
# 실행:
#   GITHUB_SERVICE_TOKEN=ghp_xxx ruby proxy.rb
#
# runner 쪽 설정 (이걸로 투과화):
#   git config --global url."http://localhost:8080/".insteadOf "https://github.com/"
#   git clone https://github.com/rack/rack.git   # 프록시를 거쳐 clone 된다
#
# 주의: insteadOf 이후 git은 프록시 호스트 기준으로 credential을 찾으므로,
# private repo를 쓰려면 runner의 credential helper가 프록시 URL에 토큰을 줘야 한다.
#
# 프로토타입이라 생략한 것: 응답 스트리밍(전부 메모리 버퍼링), 미러 eviction,
# 디스크 잠금(멀티 프로세스), push 지원(receive-pack은 전부 스루).

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "webrick"
end

require "json"
require "net/http"
require "open3"
require "webrick"

CACHE_ROOT = File.expand_path(ENV.fetch("CACHE_ROOT", "./mirror-cache"))
SERVICE_TOKEN = ENV["GITHUB_SERVICE_TOKEN"]
MIRROR_TTL = Integer(ENV.fetch("MIRROR_TTL", "60"))
VISIBILITY_TTL = Integer(ENV.fetch("VISIBILITY_TTL", "300"))
PORT = Integer(ENV.fetch("PORT", "8080"))
UPSTREAM_HOST = "github.com"

# GET /repos/{owner}/{repo} 의 visibility 필드로 public/internal/private을 판별한다.
# 토큰이 없으면 internal과 private을 구별할 수 없으므로(둘 다 404) private 취급 → 스루.
class VisibilityResolver
  def initialize(token:, ttl:)
    @token = token
    @ttl = ttl
    @cache = {}
    @mutex = Mutex.new
  end

  def visibility(owner, repo)
    key = "#{owner}/#{repo}"
    @mutex.synchronize do
      cached = @cache[key]
      return cached.fetch(:value) if cached && cached.fetch(:expires_at) > Time.now
    end

    value = fetch_visibility(owner, repo)
    @mutex.synchronize do
      @cache[key] = { value:, expires_at: Time.now + @ttl }
    end
    value
  end

  private

  def fetch_visibility(owner, repo)
    uri = URI("https://api.github.com/repos/#{owner}/#{repo}")
    req = Net::HTTP::Get.new(uri)
    req["Accept"] = "application/vnd.github+json"
    req["Authorization"] = "Bearer #{@token}" if @token

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    return "private" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body).fetch("visibility")
  end
end

# bare mirror의 확보와 갱신. repo별 mutex로 동시 fetch를 single-flight로 만든다.
class MirrorStore
  def initialize(root:, ttl:)
    @root = root
    @ttl = ttl
    @locks = {}
    @fetched_at = {}
    @mutex = Mutex.new
  end

  def ensure_fresh(owner, repo, token: nil)
    key = "#{owner}/#{repo}"
    lock_for(key).synchronize do
      path = mirror_path(owner, repo)
      if !Dir.exist?(path)
        run_git(["clone", "--mirror", "https://#{UPSTREAM_HOST}/#{key}.git", path], token:)
      elsif stale?(key)
        run_git(["--git-dir", path, "remote", "update", "--prune"], token:)
      else
        return
      end
      @mutex.synchronize { @fetched_at[key] = Time.now }
    end
  end

  def mirror_path(owner, repo)
    File.join(@root, owner, "#{repo}.git")
  end

  private

  def lock_for(key)
    @mutex.synchronize { @locks[key] ||= Mutex.new }
  end

  def stale?(key)
    fetched = @mutex.synchronize { @fetched_at[key] }
    fetched.nil? || Time.now - fetched > @ttl
  end

  # 토큰은 argv에 노출되지 않도록 GIT_CONFIG_* 환경변수로 주입한다.
  def run_git(args, token:)
    env = {}
    if token
      env["GIT_CONFIG_COUNT"] = "1"
      env["GIT_CONFIG_KEY_0"] = "http.extraheader"
      env["GIT_CONFIG_VALUE_0"] = "Authorization: Bearer #{token}"
    end
    _out, err, status = Open3.capture3(env, "git", *args)
    raise "git #{args.first} failed: #{err}" unless status.success?
  end
end

# git http-backend(CGI)를 실행해 smart HTTP 프로토콜 처리를 전부 맡긴다.
# refs 광고, pack 협상, gzip 해제까지 이 CGI가 해주므로 여기서는 env 구성과
# CGI 응답 파싱만 한다.
class GitBackend
  def initialize(project_root:)
    @project_root = project_root
  end

  def call(req, res, path_info)
    env = {
      "GIT_PROJECT_ROOT" => @project_root,
      "GIT_HTTP_EXPORT_ALL" => "1",
      "REQUEST_METHOD" => req.request_method,
      "PATH_INFO" => path_info,
      "QUERY_STRING" => req.query_string.to_s,
      "CONTENT_TYPE" => req.content_type.to_s,
      "REMOTE_ADDR" => req.peeraddr[3].to_s,
    }
    body = req.body.to_s
    env["CONTENT_LENGTH"] = body.bytesize.to_s unless body.empty?
    # Git-Protocol(v2 협상), Content-Encoding(gzip 요청 본문) 헤더는
    # HTTP_* CGI 변수로 넘겨야 http-backend가 처리한다.
    req.each do |name, value|
      env["HTTP_#{name.upcase.tr('-', '_')}"] = value
    end

    out, err, status = Open3.capture3(env, "git", "http-backend", stdin_data: body)
    raise "http-backend failed: #{err}" unless status.success?

    # packfile이 섞인 바이너리 출력이므로 UTF-8로 다루면 파싱에서 터진다.
    write_cgi_response(out.b, res)
  end

  private

  def write_cgi_response(out, res)
    header_blob, body = out.split("\r\n\r\n", 2)
    header_blob.split("\r\n").each do |line|
      name, value = line.split(": ", 2)
      if name == "Status"
        res.status = Integer(value.split(" ").first)
      else
        res[name] = value
      end
    end
    res.body = body.to_s
  end
end

# private repo용 패스스루. 클라이언트의 Authorization을 그대로 업스트림에 전달하고
# 아무것도 저장하지 않는다.
class UpstreamProxy
  HOP_BY_HOP = %w[connection keep-alive transfer-encoding host accept-encoding].freeze

  def call(req, res)
    uri = URI("https://#{UPSTREAM_HOST}#{req.path}")
    uri.query = req.query_string if req.query_string

    upstream_req = Net::HTTP.const_get(req.request_method.capitalize).new(uri)
    req.each do |name, value|
      upstream_req[name] = value unless HOP_BY_HOP.include?(name.downcase)
    end
    upstream_req.body = req.body.to_s if req.request_method == "POST"

    upstream_res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(upstream_req)
    end

    res.status = Integer(upstream_res.code)
    upstream_res.each_header do |name, value|
      res[name] = value unless HOP_BY_HOP.include?(name.downcase)
    end
    res.body = upstream_res.body.to_s
  end
end

resolver = VisibilityResolver.new(token: SERVICE_TOKEN, ttl: VISIBILITY_TTL)
mirrors = MirrorStore.new(root: CACHE_ROOT, ttl: MIRROR_TTL)
backend = GitBackend.new(project_root: CACHE_ROOT)
passthrough = UpstreamProxy.new

ROUTE = %r{\A/([\w.-]+)/([\w.-]+?)(?:\.git)?/(info/refs|git-upload-pack|git-receive-pack)\z}

server = WEBrick::HTTPServer.new(Port: PORT)
server.mount_proc("/") do |req, res|
  match = ROUTE.match(req.path)
  unless match
    res.status = 404
    next
  end
  owner, repo, action = match.captures

  # push는 캐시 대상이 아니므로 무조건 업스트림으로.
  push = action == "git-receive-pack" || req.query_string.to_s.include?("git-receive-pack")

  visibility = push ? "private" : resolver.visibility(owner, repo)
  case visibility
  when "public"
    mirrors.ensure_fresh(owner, repo)
    backend.call(req, res, "/#{owner}/#{repo}.git/#{action}")
  when "internal"
    mirrors.ensure_fresh(owner, repo, token: SERVICE_TOKEN)
    backend.call(req, res, "/#{owner}/#{repo}.git/#{action}")
  else
    passthrough.call(req, res)
  end
rescue StandardError => e
  warn "#{req.path}: #{e.message}"
  res.status = 502
end

trap("INT") { server.shutdown }
server.start
