# frozen_string_literal: true

require "prism"

class Visitor < Prism::Visitor
  attr_reader :method_defs, :method_calls
  attr_writer :file_path

  def initialize
    super()

    @method_defs = []
    @method_calls = []
    @current_scope = []
    @file_path = nil
  end

  def visit_module_node(node)
    const_names = extract_const_names(node.constant_path)

    in_scope(const_names) do
      super
    end
  end

  def visit_class_node(node)
    const_names = extract_const_names(node.constant_path)

    in_scope(const_names) do
      super
    end
  end

  MethodDef = Data.define(:name, :receiver, :file_path, :location)

  def visit_def_node(node)
    qualified_const_name = build_qualified_const_name([])

    method_def = MethodDef.new(
      name: node.name,
      receiver: qualified_const_name,
      file_path: @file_path,
      location: node.location,
    )

    method_defs.push(method_def)

    super
  end

  MethodCall = Data.define(:name, :receiver, :file_path, :location)

  def visit_call_node(node)
    if node.receiver
      case node.receiver
      when Prism::CallNode, Prism::LocalVariableReadNode
        method_call = MethodCall.new(
          name: node.name,
          receiver: node.receiver.name,
          file_path: @file_path,
          location: node.location,
        )
        method_calls.push(method_call)
      end
    end

    super
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
end
