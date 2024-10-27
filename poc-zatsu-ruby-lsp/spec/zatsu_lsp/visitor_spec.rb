# frozen_string_literal: true

module ZatsuLsp
  describe Visitor do
    let(:const_registry) { ConstRegistry.new }
    let(:method_registry) { MethodRegistry.new }
    let(:type_var_registry) { TypeVariableRegistry.new }
    let(:visitor) do
      Visitor.new(
        const_registry: const_registry,
        method_registry: method_registry,
        type_var_registry: type_var_registry,
        file_path: "sample/sample.rb",
      )
    end
    let(:code) do
      ''
    end

    before(:each) do
      parse_result = Prism.parse(code)
      parse_result.value.accept(visitor)
    end

    describe "#add_workspace" do
      it "adds a workspace" do
        ZatsuLsp.add_workspace("sample/")
      end
    end
  end
end
