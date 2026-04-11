# RailsWorldBuilder: 実際の Rails アプリを起動して TypeWorld を構築する
# Phase 1: Rails ブート → eager_load → reflection

require_relative "type_world"

module TypeGuess
  class RailsWorldBuilder
    attr_reader :world, :errors

    def initialize
      @world = TypeWorld.new
      @errors = []
    end

    # Rails アプリをブートして世界を構築
    # rails_root: Rails アプリのルートディレクトリ
    def build(rails_root:)
      # Rails 環境をブート
      boot_rails(rails_root)

      # 全モデルを eager load して DSL を実行させる
      eager_load_models

      # ランタイム reflection で世界を構築
      target_classes = discover_model_classes
      @world.build_from_runtime(target_classes)

      @world
    end

    private

    def boot_rails(rails_root)
      # Rails の環境変数を設定
      ENV["RAILS_ENV"] ||= "development"

      # config/environment.rb を読み込んで Rails をブート
      require File.join(rails_root, "config", "environment")
    rescue => e
      @errors << { phase: :boot, error: e.message }
      raise
    end

    def eager_load_models
      # Zeitwerk で全モデルをロード
      Rails.application.eager_load!
    rescue => e
      @errors << { phase: :eager_load, error: e.message }
      # eager_load が失敗しても個別ロードを試みる
      load_models_individually
    end

    def load_models_individually
      model_dir = Rails.root.join("app", "models")
      Dir.glob(model_dir.join("**", "*.rb")).each do |file|
        begin
          require file
        rescue => e
          @errors << { phase: :model_load, file: file, error: e.message }
        end
      end
    end

    # ApplicationRecord を継承するクラスを探索
    def discover_model_classes
      ApplicationRecord.descendants
    rescue
      ObjectSpace.each_object(Class).select do |klass|
        klass < ActiveRecord::Base rescue false
      end
    end
  end
end
