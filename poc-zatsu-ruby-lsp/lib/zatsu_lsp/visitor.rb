# frozen_string_literal: true

module ZatsuLsp
  class Visitor < Prism::Visitor
    def initialize(
      const_registry:,
      method_registry:,
      type_var_registry:,
      file_path:
    )
      super()

      @const_registry = const_registry
      @method_registry = method_registry
      @type_var_registry = type_var_registry
      @file_path = file_path
      @current_scope = []
      @lvars = []
      @in_singleton = false
      @current_method_name = nil
      @current_method_obj = nil
      @current_if_cond_tv = nil
      @last_evaluated_tv_stack = []
    end

    def visit_module_node(node)
      const_names = extract_const_names(node.constant_path)
      qualified_const_name = build_qualified_const_name(const_names)
      @const_registry.add(qualified_const_name, node, @file_path)

      in_scope(const_names) do
        super
      end
    end

    def visit_class_node(node)
      const_names = extract_const_names(node.constant_path)
      qualified_const_name = build_qualified_const_name(const_names)
      @const_registry.add(qualified_const_name, node, @file_path)

      in_scope(const_names) do
        super
      end
    end

    def visit_singleton_class_node(node)
      in_singleton do
        super
      end
    end

    def visit_constant_write_node(node)
      # we need this some day
      # const_names = extract_const_names(node.constant_path)
      qualified_const_name = build_qualified_const_name([node.name])
      @const_registry.add(qualified_const_name, node, @file_path)

      super
    end

    def visit_def_node(node)
      qualified_const_name = build_qualified_const_name([])
      singleton = node.receiver.is_a?(Prism::SelfNode) || @in_singleton

      method_obj = @method_registry.add(
        qualified_const_name, node, @file_path,
        singleton: singleton
      )

      in_method(node.name, method_obj) do
        super
      end
    end

    def visit_required_parameter_node(node)
      tv = find_or_create_tv(node)
      @current_method_obj.add_arg_tv(tv)

      super

      @lvars.push(tv)
    end

    def visit_return_node(node)
      if node.arguments.nil?
        # means return nil, so mimic it
        tv = TypeVariable::Static.new(
          path: @file_path,
          name: "Prism::NilNode",
          node: node,
        )
        @type_var_registry.add(tv)
      else
        node.arguments.arguments.each do |arg|
          arg_tv = find_or_create_tv(arg)
          @return_tvs.push(arg_tv)
        end
      end

      super
    end

    def visit_local_variable_write_node(node)
      lvar_node = node
      lvar_tv = find_or_create_tv(lvar_node)

      value_node = node.value
      value_tv = find_or_create_tv(value_node)

      lvar_tv.add_dependency(value_tv)
      value_tv.add_dependent(lvar_tv)

      @type_var_registry.add(lvar_tv)

      super

      @lvars.push(lvar_tv)
      @last_evaluated_tv = lvar_tv
    end

    def visit_if_node(node)
      if_cond_tv = find_or_create_tv(node)
      predicate_tv = find_or_create_tv(node.predicate)
      if_cond_tv.add_predicate(predicate_tv)

      in_if_cond(if_cond_tv) do
        super
      end
      @last_evaluated_tv = if_cond_tv
    end

    def visit_statements_node(node)
      @last_evaluated_tv_stack.push(@last_evaluated_tv)
      @last_evaluated_tv = nil

      super

      if in_if_cond?
        @current_if_cond_tv.add_dependency(@last_evaluated_tv)
        @last_evaluated_tv.add_dependent(@current_if_cond_tv)
      else
        if in_method?
          @return_tvs.push(@last_evaluated_tv)
        end
      end

      @last_evaluated_tv = @last_evaluated_tv_stack.pop
    end

    def visit_call_node(node)
      call_tv = find_or_create_tv(node)

      depend_tvs = []
      if node.receiver
        receiver_tv = find_or_create_tv(node.receiver)
        call_tv.add_receiver(receiver_tv)
        depend_tvs.push(receiver_tv)
      end

      node.arguments&.arguments&.each do |arg|
        arg_tv = find_or_create_tv(arg)
        call_tv.add_arg(arg_tv)
        depend_tvs.push(arg_tv)
      end

      qualified_const_name = build_qualified_const_name([])
      call_tv.add_scope(qualified_const_name)

      depend_tvs.each do |tv|
        if tv.is_a?(TypeVariable::LvarRead)
          lvar_ref = @lvars.reverse_each.find { |lvar| lvar.name == tv.name }

          if lvar_ref
            lvar_ref.add_dependent(tv)
            tv.add_dependency(lvar_ref)
          end
        else
          next
        end
      end

      super

      @last_evaluated_tv = call_tv
    end

    def visit_integer_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type::Integer.new)

      super

      @last_evaluated_tv = value_tv
    end

    def visit_true_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type::True.new)

      super

      @last_evaluated_tv = value_tv
    end

    def visit_false_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type::False.new)

      super

      @last_evaluated_tv = value_tv
    end

    private def extract_const_names(const_read_node_or_const_path_node)
      if const_read_node_or_const_path_node.is_a?(Prism::ConstantReadNode)
        [const_read_node_or_const_path_node.name]
      else
        list = [const_read_node_or_const_path_node.name]

        node = const_read_node_or_const_path_node.parent
        loop do
          list.push node.name

          break if node.is_a?(Prism::ConstantReadNode)

          node = node.parent
        end

        list.reverse
      end
    end

    private def build_qualified_const_name(const_names)
      (@current_scope + const_names).map(&:to_s).join("::")
    end

    private def in_if_cond(if_cond_tv)
      prev_in_if_cond_tv = @current_if_cond_tv
      @current_if_cond_tv = if_cond_tv
      yield
      @current_if_cond_tv = prev_in_if_cond_tv
    end

    private def in_if_cond?
      @current_if_cond_tv
    end

    private def in_scope(const_names)
      @current_scope.push(*const_names)
      yield
      const_names.size.times { @current_scope.pop }
    end

    private def in_singleton
      prev_in_singleton = @in_singleton
      @in_singleton = true
      yield
      @in_singleton = prev_in_singleton
    end

    private def in_method(method_name, method_obj)
      prev_in_method_name = @current_method_name
      @current_method_name = method_name
      prev_method_obj = @current_method_obj
      @current_method_obj = method_obj
      prev_lvars = @lvars
      @lvars = []
      @return_tvs = []

      yield

      @lvars = prev_lvars
      @return_tvs.each do |tv|
        @current_method_obj.add_return_tv(tv)
      end
      @current_method_name = prev_in_method_name
      @current_method_obj = prev_method_obj
    end

    private def in_method?
      @current_method_obj != nil
    end

    private def find_or_create_tv(node)
      tv = @type_var_registry.find(node.node_id)
      return tv if tv

      tv =
        case node
        when Prism::RequiredParameterNode
          TypeVariable::Arg.new(
            path: @file_path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::LocalVariableReadNode
          TypeVariable::LvarRead.new(
            path: @file_path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::LocalVariableWriteNode
          TypeVariable::LvarWrite.new(
            path: @file_path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::CallNode
          TypeVariable::Call.new(
            path: @file_path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::IfNode
          TypeVariable::If.new(
            path: @file_path,
            name: node.class.name,
            node: node,
          )
        when Prism::IntegerNode
          TypeVariable::Static.new(
            path: @file_path,
            name: node.value.to_s,
            node: node,
          )
        when Prism::TrueNode, Prism::FalseNode, Prism::NilNode
          TypeVariable::Static.new(
            path: @file_path,
            name: node.class.name,
            node: node,
          )
        else
          pp node
          raise "unknown type variable node: #{node.class}"
        end

      @type_var_registry.add(tv)

      tv
    end
  end
end
