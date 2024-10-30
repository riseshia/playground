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

    before(:each) do
      parse_result = Prism.parse(code)
      parse_result.value.accept(visitor)
    end

    context "when simple class" do
      let(:code) do
        <<~CODE
          class Post
          end
        CODE
      end

      it "registers class" do
        expect(const_registry.find("Post")).not_to be_nil
      end
    end
  end
end
