# frozen_string_literal: true

require "ruby_lsp/type_inferrer"

module RubyLsp
  module RuntimeType
    # TypeInferrer: ruby-lsp の TypeInferrer をオーバーライドして
    # RuntimeWorld の型情報を利用する
    class TypeInferrer < ::RubyLsp::TypeInferrer
      def initialize(index, world)
        super(index)
        @world = world
      end

      # ruby-lsp が Go to Definition 等で呼ぶメソッドをオーバーライド
      def infer_receiver_type(node_context)
        node = node_context.node

        # CallNode のレシーバの型を推論
        if node.is_a?(Prism::CallNode)
          receiver = node.receiver
          if receiver
            receiver_type = infer_node_type(receiver, node_context)
            return GuessedType.new(receiver_type) if receiver_type
          else
            # レシーバなし → self のメソッド呼び出し
            # nesting からクラス名を取得
            class_name = nesting_to_class_name(node_context)
            if class_name && @world.has_method?(class_name, node.name.to_s)
              return GuessedType.new(class_name)
            end
          end
        end

        # 変数ノードの型推論
        type = infer_node_type(node, node_context)
        return GuessedType.new(type) if type

        # フォールバック: ruby-lsp のデフォルト推論
        super
      end

      private

      def infer_node_type(node, node_context)
        case node
        when Prism::LocalVariableReadNode
          infer_local_variable_type(node, node_context)
        when Prism::CallNode
          infer_call_type(node, node_context)
        when Prism::ConstantReadNode, Prism::ConstantPathNode
          node.slice
        when Prism::StringNode, Prism::InterpolatedStringNode
          "String"
        when Prism::IntegerNode
          "Integer"
        when Prism::FloatNode
          "Float"
        when Prism::SymbolNode
          "Symbol"
        when Prism::ArrayNode
          "Array"
        when Prism::HashNode
          "Hash"
        when Prism::TrueNode
          "TrueClass"
        when Prism::FalseNode
          "FalseClass"
        when Prism::NilNode
          "NilClass"
        when Prism::SelfNode
          nesting_to_class_name(node_context)
        end
      end

      def infer_call_type(node, node_context)
        method_name = node.name.to_s

        if node.receiver
          receiver_type = infer_node_type(node.receiver, node_context)
          return nil unless receiver_type

          # .new → インスタンス型
          return receiver_type if method_name == "new"

          # アソシエーション
          assoc_type = @world.resolve_association_type(receiver_type, method_name)
          return assoc_type if assoc_type

          # カラムアクセサ
          col_type = @world.resolve_column_type(receiver_type, method_name)
          return col_type if col_type

          # 既知のメソッド
          return resolve_known_method(receiver_type, method_name)
        else
          # レシーバなし → self のメソッド呼び出し
          class_name = nesting_to_class_name(node_context)
          return nil unless class_name

          # アソシエーション
          assoc_type = @world.resolve_association_type(class_name, method_name)
          return assoc_type if assoc_type

          # カラムアクセサ
          col_type = @world.resolve_column_type(class_name, method_name)
          return col_type if col_type

          nil
        end
      end

      def infer_local_variable_type(node, node_context)
        # ローカル変数の代入元を探す
        # Prism の node_context からスコープ内の代入を探索
        nesting_nodes = node_context.nesting
        target_name = node.name

        # 現在のメソッド/ブロックスコープ内で代入を探す
        find_assignment_type(target_name, node_context)
      end

      def find_assignment_type(var_name, node_context)
        # node_context の nesting を辿って DefNode を見つけ、
        # その本文内で var_name への代入を探す
        # 簡易実装: nesting からは直接 DefNode にアクセスしづらいため nil
        nil
      end

      def resolve_known_method(_receiver_type, method_name)
        case method_name
        when "to_s" then "String"
        when "to_i" then "Integer"
        when "to_f" then "Float"
        when "to_a" then "Array"
        when "to_h" then "Hash"
        when "nil?" then "TrueClass"
        when "class" then "Class"
        when "length", "size", "count" then "Integer"
        when "freeze" then nil # same type
        when "dup", "clone" then nil # same type
        end
      end

      def nesting_to_class_name(node_context)
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
