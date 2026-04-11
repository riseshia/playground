# WorldBuilder: ターゲットコードを eval して TypeWorld を構築する
# Phase 1 の実装: 実行 + reflection

require "prism"
require_relative "type_world"

module TypeGuess
  class WorldBuilder
    attr_reader :world, :errors

    def initialize
      @world = TypeWorld.new
      @errors = []
    end

    # ターゲットプロジェクトを読み込んで世界を構築
    def build(framework_files:, schema_files:, model_files:)
      # 1. フレームワークコードをロード（安定コード）
      framework_files.each { |f| safe_require(f) }

      # 2. スキーマをロード
      schema_files.each { |f| safe_require(f) }

      # 3. モデルファイルを文単位で eval（エラー耐性あり）
      model_files.each { |f| eval_with_tolerance(f) }

      # 4. ランタイム reflection で世界を構築
      target_classes = discover_model_classes
      @world.build_from_runtime(target_classes)

      @world
    end

    private

    def safe_require(file)
      require_relative(file)
    rescue => e
      @errors << { file: file, error: e.message }
    end

    # Prism でパースし、文単位で eval する（エラー耐性）
    def eval_with_tolerance(file)
      source = File.read(file)
      result = Prism.parse(source)

      if result.errors.any?
        # 構文エラーがある場合、文単位で部分評価を試みる
        eval_statements_individually(result.value, source, file)
      else
        # 構文エラーなし → 全体を eval
        begin
          eval(source, TOPLEVEL_BINDING, file)
        rescue => e
          @errors << { file: file, error: e.message, type: :runtime }
          # フォールバック: 文単位で再試行
          eval_statements_individually(result.value, source, file)
        end
      end
    end

    # AST のトップレベル文を個別に eval
    def eval_statements_individually(program_node, source, file)
      return unless program_node.respond_to?(:statements)
      stmts = program_node.statements&.body || []

      stmts.each do |stmt|
        stmt_source = stmt.slice
        begin
          eval(stmt_source, TOPLEVEL_BINDING, file, stmt.location.start_line)
        rescue => e
          @errors << {
            file: file,
            line: stmt.location.start_line,
            error: e.message,
            type: :statement_eval
          }
        end
      end
    end

    # ApplicationRecord を継承するクラスを探索
    def discover_model_classes
      ObjectSpace.each_object(Class).select do |klass|
        klass < ApplicationRecord rescue false
      end
    end
  end
end
