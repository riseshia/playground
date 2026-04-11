# frozen_string_literal: true

module RubyLsp
  module RuntimeType
    # RuntimeWorld: fork で Rails を起動し、reflection で型情報を収集する
    # TypeWorld のデータ構造を LSP 用に保持
    class RuntimeWorld
      AssociationInfo = Struct.new(:macro, :name, :target_class, keyword_init: true)

      ClassInfo = Struct.new(
        :name,
        :superclass,
        :ancestors,
        :instance_method_names,
        :singleton_method_names,
        :associations,    # { Symbol => AssociationInfo }
        :column_types,    # { String => String }
        keyword_init: true
      )

      attr_reader :classes, :build_time_ms, :errors

      def initialize
        @classes = {}
        @build_time_ms = 0
        @errors = []
      end

      def class_info(name)
        @classes[name.to_s]
      end

      # アソシエーションの戻り値型を解決
      def resolve_association_type(class_name, method_name)
        info = class_info(class_name)
        return nil unless info&.associations

        assoc = info.associations[method_name.to_sym]
        return nil unless assoc

        case assoc.macro
        when :has_many
          "ActiveRecord::Associations::CollectionProxy"
        when :has_one, :belongs_to
          assoc.target_class
        end
      end

      # カラムの型を解決
      def resolve_column_type(class_name, method_name)
        info = class_info(class_name)
        info&.column_types&.[](method_name.to_s)
      end

      # メソッドが存在するか確認（祖先チェーン込み）
      def has_method?(class_name, method_name, kind: :instance)
        info = class_info(class_name)
        return false unless info

        methods = kind == :instance ? info.instance_method_names : info.singleton_method_names
        return true if methods&.include?(method_name.to_s)

        # 祖先チェーンを辿る
        info.ancestors&.each do |ancestor|
          ancestor_info = class_info(ancestor)
          next unless ancestor_info
          methods = kind == :instance ? ancestor_info.instance_method_names : ancestor_info.singleton_method_names
          return true if methods&.include?(method_name.to_s)
        end

        false
      end

      # fork で Rails 環境を起動して型情報を収集
      def build_from_rails(rails_root)
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @errors = []

        reader, writer = IO.pipe
        reader.binmode
        writer.binmode

        pid = fork do
          reader.close
          result = collect_in_child(rails_root)
          writer.write(Marshal.dump(result))
        rescue => e
          writer.write(Marshal.dump({ error: "#{e.class}: #{e.message}" }))
        ensure
          writer.close
          exit!(0)
        end

        writer.close
        data = reader.read
        reader.close
        Process.wait(pid)

        if data.empty?
          @errors << "子プロセスからデータなし"
          return self
        end

        result = Marshal.load(data)

        if result[:error]
          @errors << result[:error]
          return self
        end

        # 結果を ClassInfo に変換
        result[:classes]&.each do |name, raw|
          associations = {}
          raw[:associations]&.each do |aname, araw|
            associations[aname.to_sym] = AssociationInfo.new(
              macro: araw[:macro].to_sym,
              name: aname.to_sym,
              target_class: araw[:target_class]
            )
          end

          @classes[name] = ClassInfo.new(
            name: name,
            superclass: raw[:superclass],
            ancestors: raw[:ancestors],
            instance_method_names: raw[:instance_method_names],
            singleton_method_names: raw[:singleton_method_names],
            associations: associations,
            column_types: raw[:column_types]
          )
        end

        t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @build_time_ms = ((t1 - t0) * 1000).round
        self
      end

      private

      # 子プロセス内で Rails を起動して reflection
      def collect_in_child(rails_root)
        ENV["RAILS_ENV"] ||= "development"
        require File.join(rails_root, "config", "environment")
        Rails.application.eager_load!

        classes = {}
        ApplicationRecord.descendants.each do |klass|
          name = klass.name
          next unless name

          # アソシエーション
          associations = {}
          if klass.respond_to?(:reflect_on_all_associations)
            klass.reflect_on_all_associations.each do |assoc|
              target = begin
                assoc.klass.name
              rescue
                assoc.class_name rescue assoc.name.to_s.classify
              end
              associations[assoc.name.to_s] = {
                macro: assoc.macro.to_s,
                target_class: target
              }
            end
          end

          # カラム型
          column_types = {}
          if klass.respond_to?(:columns_hash)
            klass.columns_hash.each do |col_name, col|
              column_types[col_name] = ruby_type_for(col.type)
            end
          end

          classes[name] = {
            superclass: klass.superclass&.name,
            ancestors: klass.ancestors.map(&:name).compact.first(15),
            instance_method_names: klass.instance_methods(false).map(&:to_s),
            singleton_method_names: klass.singleton_methods(false).map(&:to_s),
            associations: associations,
            column_types: column_types
          }
        end

        { classes: classes }
      end

      def ruby_type_for(col_type)
        case col_type
        when :string, :text then "String"
        when :integer, :bigint then "Integer"
        when :float, :decimal then "Float"
        when :boolean then "TrueClass"
        when :datetime, :timestamp then "ActiveSupport::TimeWithZone"
        when :date then "Date"
        when :time then "Time"
        when :json, :jsonb then "Hash"
        else "Object"
        end
      end
    end
  end
end
