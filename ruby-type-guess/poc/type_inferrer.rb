# TypeInferrer: Prism AST を巡回し、TypeWorld を参照して
# メソッド本文内のローカル変数・式の型を推論する
# Phase 2 の実装

require "prism"
require_relative "type_world"

module TypeGuess
  # ある位置での型情報
  TypeAtLocation = Struct.new(:file, :line, :column, :expression, :type, keyword_init: true)

  class TypeInferrer
    attr_reader :type_map  # { "file:line:col" => TypeAtLocation }

    def initialize(world)
      @world = world
      @type_map = {}
    end

    # ファイルを解析して型マップを構築
    def analyze_file(file)
      source = File.read(file)
      result = Prism.parse(source)
      visit(result.value, file, Env.new)
      @type_map
    end

    private

    # 型環境: スコープ内の変数→型マッピング
    class Env
      attr_reader :locals, :current_class, :current_method

      def initialize(locals: {}, current_class: nil, current_method: nil)
        @locals = locals
        @current_class = current_class
        @current_method = current_method
      end

      def set(name, type)
        @locals[name.to_s] = type
      end

      def get(name)
        @locals[name.to_s]
      end

      def with_class(name)
        Env.new(locals: {}, current_class: name, current_method: nil)
      end

      def with_method(name)
        Env.new(locals: @locals.dup, current_class: @current_class, current_method: name)
      end

      def dup_env
        Env.new(locals: @locals.dup, current_class: @current_class, current_method: @current_method)
      end
    end

    # AST ノードを巡回して型を推論
    def visit(node, file, env)
      return nil unless node

      case node
      when Prism::ProgramNode
        visit(node.statements, file, env)

      when Prism::StatementsNode
        last_type = nil
        node.body.each { |stmt| last_type = visit(stmt, file, env) }
        last_type

      # --- クラス/モジュール定義 ---
      when Prism::ClassNode
        class_name = resolve_class_name(node)
        class_env = env.with_class(class_name)
        visit(node.body, file, class_env) if node.body
        class_name

      when Prism::ModuleNode
        mod_name = node.name.to_s
        mod_env = env.with_class(mod_name)
        visit(node.body, file, mod_env) if node.body
        mod_name

      # --- メソッド定義 ---
      when Prism::DefNode
        method_env = env.with_method(node.name.to_s)

        # パラメータを型環境に追加
        if node.parameters
          register_parameters(node.parameters, method_env, file)
        end

        # selfパラメータ
        method_env.set("self", env.current_class) if env.current_class

        # メソッド本文を解析
        return_type = visit(node.body, file, method_env) if node.body
        return_type

      # --- ローカル変数代入 ---
      when Prism::LocalVariableWriteNode
        value_type = visit(node.value, file, env)
        env.set(node.name.to_s, value_type)
        record(file, node.name_loc, node.name.to_s, value_type)
        value_type

      # --- ローカル変数参照 ---
      when Prism::LocalVariableReadNode
        type = env.get(node.name.to_s)
        record(file, node.location, node.name.to_s, type)
        type

      # --- メソッド呼び出し ---
      when Prism::CallNode
        infer_call(node, file, env)

      # --- リテラル ---
      when Prism::IntegerNode
        record(file, node.location, node.slice, "Integer")
        "Integer"

      when Prism::FloatNode
        record(file, node.location, node.slice, "Float")
        "Float"

      when Prism::StringNode
        record(file, node.location, node.slice, "String")
        "String"

      when Prism::SymbolNode
        record(file, node.location, node.slice, "Symbol")
        "Symbol"

      when Prism::TrueNode, Prism::FalseNode
        type = node.is_a?(Prism::TrueNode) ? "TrueClass" : "FalseClass"
        record(file, node.location, node.slice, type)
        type

      when Prism::NilNode
        record(file, node.location, "nil", "NilClass")
        "NilClass"

      when Prism::ArrayNode
        elem_types = node.elements.map { |e| visit(e, file, env) }.compact.uniq
        type = elem_types.length == 1 ? "Array<#{elem_types[0]}>" : "Array"
        record(file, node.location, node.slice, type)
        type

      when Prism::HashNode
        record(file, node.location, node.slice, "Hash")
        "Hash"

      when Prism::InterpolatedStringNode
        node.parts.each { |part| visit(part, file, env) }
        record(file, node.location, node.slice, "String")
        "String"

      when Prism::EmbeddedStatementsNode
        visit(node.statements, file, env) if node.statements

      # --- 制御構造 ---
      when Prism::IfNode
        visit(node.predicate, file, env)
        then_type = visit(node.statements, file, env.dup_env) if node.statements
        else_type = visit(node.subsequent, file, env.dup_env) if node.subsequent
        merge_types(then_type, else_type)

      when Prism::ElseNode
        visit(node.statements, file, env) if node.statements

      when Prism::ReturnNode
        if node.arguments
          node.arguments.arguments.map { |a| visit(a, file, env) }.last
        end

      # --- self ---
      when Prism::SelfNode
        type = env.current_class
        record(file, node.location, "self", type)
        type

      # --- インスタンス変数 ---
      when Prism::InstanceVariableReadNode
        record(file, node.location, node.name.to_s, nil)
        nil

      when Prism::InstanceVariableWriteNode
        value_type = visit(node.value, file, env)
        record(file, node.location, node.name.to_s, value_type)
        value_type

      # --- その他のノードは子ノードを巡回 ---
      else
        visit_child_nodes(node, file, env)
      end
    end

    def visit_child_nodes(node, file, env)
      last = nil
      node.child_nodes.compact.each { |child| last = visit(child, file, env) }
      last
    end

    # メソッド呼び出しの型推論
    def infer_call(node, file, env)
      # レシーバの型を推論
      if node.receiver
        receiver_type = visit(node.receiver, file, env)
      else
        # レシーバなし → self 呼び出し
        receiver_type = env.current_class
      end

      method_name = node.name.to_s

      # 引数を巡回（型情報の収集）
      if node.arguments
        node.arguments.arguments.each { |arg| visit(arg, file, env) }
      end
      visit(node.block, file, env) if node.block

      # 型の解決
      return_type = resolve_return_type(receiver_type, method_name, node, env)
      record(file, node.location, node.slice, return_type)
      return_type
    end

    # メソッドの戻り値型を解決
    def resolve_return_type(receiver_type, method_name, node, env)
      return nil unless receiver_type

      # 特殊ケース: よく知られたメソッド
      case method_name
      when "new"
        return receiver_type  # Foo.new → Foo
      when "to_s"
        return "String"
      when "to_i"
        return "Integer"
      when "to_f"
        return "Float"
      when "nil?"
        return "Boolean"
      when "is_a?", "kind_of?", "instance_of?"
        return "Boolean"
      when "class"
        return "Class"
      when "length", "size", "count"
        return "Integer"
      when "first"
        # Array<X>.first → X
        if receiver_type.start_with?("Array<")
          return receiver_type[6..-2]
        end
        return nil
      when "select", "filter", "reject"
        return receiver_type  # コレクションを返す
      when "map", "collect"
        return "Array"  # 要素型不明
      when "save", "save!", "destroy", "update"
        return "Boolean"
      when "==", "!=", "<", ">", "<=", ">="
        return "Boolean"
      when "+", "-", "*", "/"
        return receiver_type  # 簡易: 同じ型を返す
      end

      # アソシエーション由来のメソッドかチェック
      class_info = @world.class_info(receiver_type)
      if class_info&.associations
        assoc = class_info.associations[method_name.to_sym]
        if assoc
          case assoc.macro
          when :has_many
            return "Array<#{assoc.target_class}>"
          when :has_one, :belongs_to
            return assoc.target_class
          end
        end
      end

      # カラムアクセサかチェック
      if class_info&.column_types
        col_type = class_info.column_types[method_name]
        return col_type if col_type
      end

      # ?で終わるメソッド → Boolean と推定
      if method_name.end_with?("?")
        return "Boolean"
      end

      # TypeWorld からメソッド情報を検索
      method_info = @world.resolve_method(receiver_type, method_name)
      if method_info
        infer_from_method_info(receiver_type, method_info)
      else
        # singleton メソッドとして検索
        method_info = @world.resolve_method(receiver_type, method_name, kind: :singleton)
        if method_info
          receiver_type  # スコープ等はクラス自体を返す
        else
          nil
        end
      end
    end

    # メソッド情報から戻り値型を推論
    def infer_from_method_info(receiver_type, method_info)
      owner_info = @world.class_info(method_info.owner)
      return nil unless owner_info

      # アソシエーション由来を再チェック（祖先で定義された場合）
      if owner_info.associations
        assoc = owner_info.associations[method_info.name]
        if assoc
          case assoc.macro
          when :has_many then return "Array<#{assoc.target_class}>"
          when :has_one, :belongs_to then return assoc.target_class
          end
        end
      end

      nil
    end

    # パラメータを型環境に登録
    def register_parameters(params_node, env, file)
      params_node.child_nodes.compact.each do |param|
        case param
        when Prism::RequiredParameterNode
          env.set(param.name.to_s, nil)  # 型不明
          record(file, param.location, param.name.to_s, nil)
        when Prism::OptionalParameterNode
          default_type = visit(param.value, file, env)
          env.set(param.name.to_s, default_type)
          record(file, param.location, param.name.to_s, default_type)
        when Prism::KeywordParameterNode
          if param.value
            default_type = visit(param.value, file, env)
            env.set(param.name.to_s, default_type)
          else
            env.set(param.name.to_s, nil)
          end
        end
      end
    end

    # 2つの型をマージ（union type の簡易版）
    def merge_types(a, b)
      return a if b.nil?
      return b if a.nil?
      return a if a == b
      "#{a} | #{b}"
    end

    # クラス名を解決
    def resolve_class_name(node)
      if node.constant_path
        node.constant_path.slice
      else
        node.name.to_s
      end
    end

    # 型情報を記録
    def record(file, location, expression, type)
      return unless location
      key = "#{file}:#{location.start_line}:#{location.start_column}"
      @type_map[key] = TypeAtLocation.new(
        file: file,
        line: location.start_line,
        column: location.start_column,
        expression: expression.to_s[0..60],
        type: type
      )
    end
  end
end
