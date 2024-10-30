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
      @in_singleton = false
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
      singleton = node.receiver&.is_a?(Prism::SelfNode) || @in_singleton
      @method_registry.add(
        qualified_const_name, node, @file_path,
        singleton: singleton
      )

      super
    end

    def visit_local_variable_write_node(node)
      # qualified_const_name = build_qualified_const_name([])
      # @method_registry.add(qualified_const_name, node, @file_path)
      # puts "in  local_variable_write_node: #{node.name}"
      super
      # puts "out local_variable_write_node: #{node.name}"
    end

    def visit_call_node(node)
      # qualified_const_name = build_qualified_const_name([])
      # @method_registry.add(qualified_const_name, node, @file_path)

      # puts "in  call_node: #{node.name}"
      # pp node
      super
      # puts "out call_node: #{node.name}"
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
  end
end
