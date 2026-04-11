# frozen_string_literal: true

module RubyLsp
  module RuntimeType
    # Hover: カーソル位置の変数/メソッド呼び出しに型情報を表示
    class Hover
      def initialize(world, response_builder, node_context, dispatcher, global_state)
        @world = world
        @response_builder = response_builder
        @node_context = node_context
        @global_state = global_state

        dispatcher.register(
          self,
          :on_call_node_enter,
          :on_constant_read_node_enter,
          :on_constant_path_node_enter
        )
      end

      def on_call_node_enter(node)
        method_name = node.name.to_s
        class_name = resolve_receiver_class(node)
        return unless class_name

        # アソシエーション型
        assoc_type = @world.resolve_association_type(class_name, method_name)
        if assoc_type
          assoc_info = @world.class_info(class_name)&.associations&.[](method_name.to_sym)
          macro = assoc_info&.macro || :unknown
          @response_builder.push(
            "**[RuntimeType]** `#{macro} :#{method_name}` → `#{assoc_type}`",
            category: :documentation
          )
          return
        end

        # カラム型
        col_type = @world.resolve_column_type(class_name, method_name)
        if col_type
          @response_builder.push(
            "**[RuntimeType]** column `#{method_name}` → `#{col_type}`",
            category: :documentation
          )
          return
        end

        # スコープ（singleton メソッド）
        info = @world.class_info(class_name)
        if info&.singleton_method_names&.include?(method_name)
          @response_builder.push(
            "**[RuntimeType]** scope `.#{method_name}` → `ActiveRecord::Relation`",
            category: :documentation
          )
        end
      end

      def on_constant_read_node_enter(node)
        show_class_summary(node.name.to_s)
      end

      def on_constant_path_node_enter(node)
        show_class_summary(node.slice)
      end

      private

      def show_class_summary(class_name)
        info = @world.class_info(class_name)
        return unless info

        lines = ["**[RuntimeType]** `#{class_name}`"]

        if info.associations&.any?
          assoc_list = info.associations.values.map { |a| "`#{a.macro} :#{a.name}`" }.join(", ")
          lines << "Associations: #{assoc_list}"
        end

        if info.column_types&.any?
          col_list = info.column_types.first(8).map { |n, t| "`#{n}: #{t}`" }.join(", ")
          cols_remaining = info.column_types.size - 8
          col_list += ", ... (+#{cols_remaining})" if cols_remaining > 0
          lines << "Columns: #{col_list}"
        end

        @response_builder.push(lines.join("\n\n"), category: :documentation)
      end

      def resolve_receiver_class(node)
        if node.receiver
          case node.receiver
          when Prism::SelfNode
            nesting_to_class(@node_context)
          when Prism::LocalVariableReadNode
            # ローカル変数 → 型推論が必要だが、簡易版では nil
            nil
          when Prism::CallNode
            # チェーン呼び出し → 再帰的に解決
            nil
          when Prism::ConstantReadNode
            node.receiver.name.to_s
          when Prism::ConstantPathNode
            node.receiver.slice
          end
        else
          # レシーバなし → self のクラス
          nesting_to_class(@node_context)
        end
      end

      def nesting_to_class(node_context)
        nesting = node_context.nesting
        return nil if nesting.empty?

        nesting.filter_map { |n|
          case n
          when String then n
          else n.respond_to?(:name) ? n.name.to_s : nil
          end
        }.join("::")
      end
    end
  end
end
