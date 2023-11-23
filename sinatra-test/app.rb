# frozen_string_literal: true

require 'csv'
require 'json'
require 'set'
require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/json'

module Isuports
  class App < Sinatra::Base
    enable :logging
    set :show_exceptions, :after_handler

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end
    helpers Sinatra::Cookies

    before do
      cache_control :private
    end

    class HttpError < StandardError
      attr_reader :code

      def initialize(code, message)
        super(message)
        @code = code
      end
    end

    # エラー処理
    error HttpError do
      e = env['sinatra.error']
      logger.error("error at #{request.path}: #{e.message}")
      content_type :json
      status e.code
      JSON.dump(status: false)
    end

    class MemoryCacheStore
      def initialize
        @cache = {}
      end

      def get(key)
        @cache[key]
      end

      def del(key)
        @cache.delete(key)
      end

      def set(key, value)
        @cache[key] = value
      end

      def clear
        @cache = {}
      end
    end

    helpers do
      def cache_client
        Thread.current[:cache_client] ||= MemoryCacheStore.new
      end
    end

    # 参加者を失格にする
    get '/api/player/:player_id/disqualified' do
      cache_client.del("player:#{player_id}")
      json(
        status: true,
        data: {
          player: {
            id: 1,
            display_name: 'name',
            is_disqualified: true,
          },
        },
      )
    end

    before '/api/player/:player_id' do
      if request["role"] != 'player'
        raise HttpError.new(403, 'role player required')
      end

      player_id = params[:player_id]
      if value = cache_client.get("player:#{player_id}")
        puts "Cache hit: player:#{player_id}"
        value = JSON.parse(value)

        body = value['body']
        headers = value['headers']
        status = value['status']

        halt status, headers, body
      else
        puts "Cache missed: player:#{player_id}"
      end
    end

    after '/api/player/:player_id' do
      player_id = params[:player_id]
      value = {
        body: response.body,
        headers: response.headers,
        status: response.status,
      }
      cache_client.set("player:#{player_id}", JSON.dump(value))
    end

    get '/api/player/:player_id' do
      res = {
        status: true,
        data: {
          player: {
            id: 1,
            display_name: 'name',
            is_disqualified: true,
          },
          scores: [
            { competition_title: 'title', score: 100 },
          ],
        },
      }

      content_type :json
      JSON.dump(res)
      # json(
      #   status: true,
      #   data: {
      #     player: {
      #       id: 1,
      #       display_name: 'name',
      #       is_disqualified: true,
      #     },
      #     scores: [
      #       { competition_title: 'title', score: 100 },
      #     ],
      #   },
      # )
    end

    get '/initialize' do
      cache_client.clear

      json(
        status: true,
        data: {
          lang: 'ruby',
        },
      )
    end
  end
end
