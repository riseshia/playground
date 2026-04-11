#!/usr/bin/env ruby
# Hot Reload PoC: fork checkpoint 方式で
# ファイル変更時に型情報を再構築する

require "prism"
require "json"
require_relative "type_world"
require_relative "type_inferrer"

RAILS_ROOT = File.expand_path("../sample_app", __dir__)

module TypeGuess
  class HotReloadServer
    def initialize(rails_root)
      @rails_root = rails_root
      @type_store = nil       # 最新の型情報
      @last_mtimes = {}       # ファイルの最終更新時刻
    end

    def start
      # === Phase 0: Rails ブート (1回だけ) ===
      puts "[boot] Rails をブート中..."
      t0 = now
      boot_rails
      puts "[boot] 完了 (#{elapsed(t0)}ms)"

      # === 初回の型情報構築 ===
      puts "[init] 初回型情報構築中..."
      t0 = now
      @type_store = fork_and_collect
      puts "[init] 完了 (#{elapsed(t0)}ms)"
      print_summary(@type_store)
      record_mtimes

      # === ファイル監視ループ ===
      puts
      puts "[watch] ファイル変更を監視中... (Ctrl+C で終了)"
      puts "[watch] 試しにモデルファイルを編集してみてください"
      puts

      loop do
        changed = detect_changes
        if changed.any?
          puts "[change] 変更検出: #{changed.map { |f| File.basename(f) }.join(', ')}"
          t0 = now

          new_store = fork_and_collect
          if new_store
            @type_store = new_store
            puts "[reload] 型情報更新完了 (#{elapsed(t0)}ms)"
            print_diff(changed)
          else
            puts "[reload] 失敗 — 前の型情報を維持"
          end

          record_mtimes
        end
        sleep 1
      end
    rescue Interrupt
      puts "\n[exit] 終了"
    end

    private

    def boot_rails
      ENV["RAILS_ENV"] ||= "development"
      require File.join(@rails_root, "config", "environment")
      Rails.application.eager_load!
    end

    # fork して子プロセスで型情報を収集、パイプで返す
    def fork_and_collect
      reader, writer = IO.pipe
      reader.binmode
      writer.binmode

      pid = fork do
        reader.close

        begin
          # モデルファイルを文単位で再評価
          reload_models

          # reflection で型情報を収集
          world = build_world
          # AST 解析で本文内型推論
          inferrer = run_inference(world)

          # シリアライズして親に送信
          result = serialize(world, inferrer)
          writer.write(result)
        rescue => e
          $stderr.puts "[child] エラー: #{e.message}"
          $stderr.puts e.backtrace.first(5).join("\n")
        ensure
          writer.close
          exit!(0)  # 子プロセスを即座に終了
        end
      end

      writer.close
      data = reader.read
      reader.close
      Process.wait(pid)

      return nil if data.empty?
      deserialize(data)
    rescue => e
      $stderr.puts "[fork] エラー: #{e.message}"
      nil
    end

    # モデルを再読み込み
    def reload_models
      if defined?(Rails) && Rails.application
        # Zeitwerk: 変更されたファイルを再読み込み
        Rails.application.reloader.reload!
        Rails.application.eager_load!
      end
    end

    def build_world
      world = TypeWorld.new
      classes = ApplicationRecord.descendants
      world.build_from_runtime(classes)
      world
    end

    def run_inference(world)
      inferrer = TypeInferrer.new(world)
      Dir.glob(File.join(@rails_root, "app", "models", "*.rb")).each do |file|
        inferrer.analyze_file(file)
      end
      inferrer
    end

    # 型情報をシリアライズ（子→親のパイプ通信用）
    def serialize(world, inferrer)
      data = {
        classes: world.classes.transform_values { |info|
          {
            name: info.name,
            superclass: info.superclass,
            ancestors: info.ancestors.first(8),
            instance_methods: info.instance_methods.keys.map(&:to_s),
            singleton_methods: info.singleton_methods.keys.map(&:to_s),
            associations: info.associations.transform_values { |a|
              { macro: a.macro.to_s, target_class: a.target_class }
            }.transform_keys(&:to_s),
            column_types: info.column_types,
          }
        },
        type_map: inferrer.type_map.transform_values { |info|
          {
            file: info.file,
            line: info.line,
            column: info.column,
            expression: info.expression,
            type: info.type
          }
        }
      }
      Marshal.dump(data)
    end

    def deserialize(data)
      Marshal.load(data)
    end

    def model_files
      Dir.glob(File.join(@rails_root, "app", "models", "**", "*.rb"))
    end

    def record_mtimes
      model_files.each do |f|
        @last_mtimes[f] = File.mtime(f) rescue nil
      end
    end

    def detect_changes
      changed = []
      model_files.each do |f|
        current_mtime = File.mtime(f) rescue nil
        if @last_mtimes[f] != current_mtime
          changed << f
        end
      end
      changed
    end

    def print_summary(store)
      return unless store
      puts
      store[:classes].each do |name, info|
        puts "  #{name}: #{info[:instance_methods].size} methods, #{info[:associations].size} assoc, #{info[:column_types].size} columns"
      end
      puts
    end

    def print_diff(changed_files)
      return unless @type_store
      changed_files.each do |file|
        basename = File.basename(file)
        puts "  [#{basename}] 型情報:"

        @type_store[:type_map].each do |key, info|
          next unless info[:file] == file && info[:type]
          printf "    %-30s  %-30s  → %s\n",
            "#{basename}:#{info[:line]}:#{info[:column]}",
            info[:expression].to_s[0..29],
            info[:type]
        end
      end
      puts
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def elapsed(t0)
      ((now - t0) * 1000).round
    end
  end
end

TypeGuess::HotReloadServer.new(RAILS_ROOT).start
