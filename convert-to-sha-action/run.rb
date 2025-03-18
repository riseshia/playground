#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

class ActionConverter
  USES_PATTERN = /uses:\s*([^@\s]+)@([^#\s]+)/

  def initialize(workflow_path)
    @workflow_path = workflow_path
    @content = File.read(workflow_path)
  end

  def convert_to_sha!
    modified_content = @content.dup
    
    # タグ参照を見つけて置換
    @content.scan(USES_PATTERN).each do |repo, ref|
      # 既にSHA参照の場合はスキップ（40文字の16進数）
      next if ref.match?(/^[0-9a-f]{40}$/)
      
      # タグからSHAとフルバージョンを取得
      sha, full_version = get_sha_and_full_version(repo, ref)
      next unless sha

      # 置換処理
      original = "uses: #{repo}@#{ref}"
      # フルバージョンがあればそれを使用、なければ元のタグをそのまま使用
      version_comment = full_version || ref
      replacement = "uses: #{repo}@#{sha} # #{version_comment}"
      modified_content = modified_content.gsub(original, replacement)
    end

    # ファイルに書き戻す
    File.write(@workflow_path, modified_content)
    modified_content
  end

  # タグからSHAとフルバージョンを取得
  def get_sha_and_full_version(repo, tag)
    owner, repo_name = repo.split('/')
    return [nil, nil] unless owner && repo_name

    # タグのSHAを取得
    sha = get_sha_from_tag(repo, tag)
    return [nil, nil] unless sha

    # SHA から対応する詳細なバージョンタグを取得
    if tag.match?(/^v\d+$/)
      full_version = find_detailed_version_from_sha(owner, repo_name, sha, tag)
      return [sha, full_version || ensure_semantic_version(tag)]
    end

    # 既に詳細なバージョンタグが指定されている場合も完全なセマンティックバージョン形式にする
    [sha, ensure_semantic_version(tag)]
  end

  # バージョン番号を完全なセマンティックバージョン形式（メジャー.マイナー.パッチ）に変換
  def ensure_semantic_version(version)
    return version unless version.match?(/^v\d+/)

    parts = version.sub(/^v/, '').split('.')
    while parts.size < 3
      parts << '0'
    end
    "v#{parts.join('.')}"
  end

  # コミットSHAから対応する詳細なバージョンタグを取得
  def find_detailed_version_from_sha(owner, repo_name, sha, major_version)
    # コミットSHAに紐づくタグを取得
    stdout, stderr, status = Open3.capture3("gh", "api", "repos/#{owner}/#{repo_name}/tags")
    return nil unless status.success?

    begin
      tags = JSON.parse(stdout)
      
      # コミットSHAに紐づくタグをフィルタリング
      matching_tags = tags.select { |tag| tag['commit']['sha'] == sha }
      return nil if matching_tags.empty?
      
      # メジャーバージョンに一致するタグのみをフィルタリング
      matching_version_tags = matching_tags.map { |tag| tag['name'] }.select do |name|
        (name.start_with?("#{major_version}.") && name.split('.').size == 3) \
        || name == major_version
      end
      
      return nil if matching_version_tags.empty?
      
      # バージョン番号を解析してソート用の配列に変換
      version_objects = matching_version_tags.map do |ver|
        parts = ver.sub(/^v/, '').split('.').map(&:to_i)
        # 配列の長さを揃える
        while parts.size < 3
          parts << 0
        end
        { version: ver, parts: parts }
      end
      
      # セマンティックバージョニングに基づいてソートし、最新のバージョンを取得
      latest_version = version_objects.sort_by { |obj| obj[:parts] }.last[:version]
      
      # 完全なセマンティックバージョン形式で返す
      return ensure_semantic_version(latest_version)
    rescue JSON::ParserError, KeyError => e
      puts "Error parsing tags response: #{e.message}"
      return nil
    end
  end

  # テスト用にパブリックメソッドへ変更
  def get_sha_from_tag(repo, tag)
    owner, repo_name = repo.split('/')
    return nil unless owner && repo_name

    # gh apiコマンドを使用してタグ情報を取得
    stdout, stderr, status = Open3.capture3("gh", "api", "repos/#{owner}/#{repo_name}/git/refs/tags/#{tag}")
    return nil unless status.success?

    begin
      data = JSON.parse(stdout)
      
      # タグがcommitオブジェクトを指している場合とタグオブジェクトを指している場合の両方に対応
      if data['object']['type'] == 'commit'
        return data['object']['sha']
      elsif data['object']['type'] == 'tag'
        # タグオブジェクトの場合は、さらにそのオブジェクトを取得
        tag_url = data['object']['url']
        stdout, stderr, status = Open3.capture3("gh", "api", tag_url)
        return nil unless status.success?
        
        tag_data = JSON.parse(stdout)
        return tag_data['object']['sha']
      end
    rescue JSON::ParserError, KeyError => e
      puts "Error parsing response: #{e.message}"
      return nil
    end
    
    nil
  end
end

# コマンドラインから実行された場合
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: #{$PROGRAM_NAME} <workflow_file_path>"
    exit 1
  end

  # GitHub CLIがインストールされていることを確認
  unless system("which gh > /dev/null 2>&1")
    puts "Error: GitHub CLI (gh) is not installed. Please install it from https://cli.github.com/"
    exit 1
  end

  # ログイン状態を確認
  unless system("gh auth status > /dev/null 2>&1")
    puts "Error: You are not logged in to GitHub CLI. Please run 'gh auth login' first."
    exit 1
  end

  workflow_path = ARGV[0]
  unless File.exist?(workflow_path)
    puts "Error: Workflow file '#{workflow_path}' does not exist."
    exit 1
  end

  converter = ActionConverter.new(workflow_path)
  converter.convert_to_sha!
  puts "Workflow file '#{workflow_path}' has been updated with SHA references."
end
