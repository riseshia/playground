# frozen_string_literal: true

require "prism"

require "zatsu_lsp/node"
require "zatsu_lsp/type_variable"

require "zatsu_lsp/const_registry"
require "zatsu_lsp/method_registry"
require "zatsu_lsp/type_variable_registry"
require "zatsu_lsp/visitor"

module ZatsuLsp
  module_function

  def add_workspace(path)
    Dir.glob("#{path}/**/*.rb").each do |file|
      parse_rb(file)
    end
  end

  def parse_rb(file)
    parse_result = Prism.parse_file(file)
    visitor = Visitor.new(
      const_registry:,
      method_registry:,
      type_var_registry:,
      file_path: file,
    )
    # pp parse_result.value
    parse_result.value.accept(visitor)
  end

  def const_registry
    @const_registry ||= ConstRegistry.new
  end

  def method_registry
    @method_registry ||= MethodRegistry.new
  end

  def type_var_registry
    @type_var_registry ||= TypeVariableRegistry.new
  end
end
