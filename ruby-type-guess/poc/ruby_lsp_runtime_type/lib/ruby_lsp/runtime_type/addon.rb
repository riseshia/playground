# frozen_string_literal: true

require "ruby_lsp/addon"
require_relative "runtime_world"
require_relative "type_inferrer"
require_relative "hover"

module RubyLsp
  module RuntimeType
    class Addon < ::RubyLsp::Addon
      def name
        "RuntimeType"
      end

      def version
        "0.1.0"
      end

      def activate(global_state, message_queue)
        @global_state = global_state
        @message_queue = message_queue
        @world = RuntimeWorld.new
        @original_type_inferrer = nil

        log("Activated. Starting background Rails boot...")

        # バックグラウンドで Rails 環境をブートして型情報を収集
        Thread.new { boot_and_index }
      end

      def deactivate
        restore_type_inferrer
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        return unless @world && @world.classes.any?

        Hover.new(@world, response_builder, node_context, dispatcher, @global_state)
      end

      # ファイル変更時に型情報を再構築
      def workspace_did_change_watched_files(changes)
        rb_changed = changes.any? do |change|
          uri = URI(change[:uri])
          path = uri.path
          path&.end_with?(".rb") && path&.include?("/app/models/")
        end

        if rb_changed
          log("Model file changed. Rebuilding type world...")
          Thread.new { rebuild_world }
        end
      end

      private

      def boot_and_index
        rails_root = detect_rails_root
        unless rails_root
          log("Rails root not found. Addon inactive.")
          return
        end

        log("Rails root: #{rails_root}")
        @rails_root = rails_root

        @world.build_from_rails(rails_root)

        if @world.errors.any?
          @world.errors.each { |e| log("Error: #{e}") }
        end

        class_count = @world.classes.size
        log("Type world built: #{class_count} classes (#{@world.build_time_ms}ms)")

        # TypeInferrer を差し替え
        swap_type_inferrer

        # クラス情報のサマリーをログ
        @world.classes.each do |name, info|
          assoc_count = info.associations&.size || 0
          col_count = info.column_types&.size || 0
          log("  #{name}: #{assoc_count} assoc, #{col_count} columns")
        end
      rescue => e
        log("Boot failed: #{e.class}: #{e.message}")
        log(e.backtrace&.first(5)&.join("\n").to_s)
      end

      def rebuild_world
        return unless @rails_root

        @world.build_from_rails(@rails_root)
        log("World rebuilt: #{@world.classes.size} classes (#{@world.build_time_ms}ms)")

        # TypeInferrer を再差し替え
        swap_type_inferrer
      rescue => e
        log("Rebuild failed: #{e.message}")
      end

      def swap_type_inferrer
        return unless @global_state.respond_to?(:type_inferrer)

        @original_type_inferrer ||= @global_state.type_inferrer
        custom = TypeInferrer.new(@global_state.index, @world)
        @global_state.instance_variable_set(:@type_inferrer, custom)
        log("TypeInferrer swapped")
      rescue => e
        log("TypeInferrer swap failed: #{e.message}")
      end

      def restore_type_inferrer
        return unless @original_type_inferrer

        @global_state.instance_variable_set(:@type_inferrer, @original_type_inferrer)
        @original_type_inferrer = nil
      rescue => e
        log("TypeInferrer restore failed: #{e.message}")
      end

      def detect_rails_root
        workspace = @global_state.workspace_path
        return nil unless workspace

        # config/environment.rb の存在で Rails プロジェクトを判定
        if File.exist?(File.join(workspace, "config", "environment.rb"))
          return workspace
        end

        nil
      end

      def log(message)
        return unless @message_queue
        return if @message_queue.closed?

        @message_queue << RubyLsp::Notification.window_log_message(
          "[RuntimeType] #{message}",
          type: RubyLsp::Constant::MessageType::LOG
        )
      rescue
        # メッセージキューが閉じている場合は無視
      end
    end
  end
end
