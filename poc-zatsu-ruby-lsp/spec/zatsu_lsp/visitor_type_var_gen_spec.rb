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

    context "type variable generation" do
      context "with lvar assign" do
        let(:code) do
          <<~CODE
            def hello
              a = 1
            end
          CODE
        end

        it "registers all" do
          tv = type_var_registry.find("#hello_a_0")
          expect(tv).not_to be_nil
        end
      end

      context "with lvar assign twice" do
        let(:code) do
          <<~CODE
            def hello
              a = 1
              a = 2
            end
          CODE
        end

        it "registers all" do
          tv0 = type_var_registry.find("#hello_a_0")
          tv1 = type_var_registry.find("#hello_a_1")

          expect(tv0).not_to be_nil
          expect(tv1).not_to be_nil
        end
      end

      context "with lvar assign twice and chain" do
        let(:code) do
          <<~CODE
            def hello
              a = 1
              a = a + 2
            end
          CODE
        end

        it "registers all" do
          tv0 = type_var_registry.find("#hello_a_0")
          tv1 = type_var_registry.find("#hello_a_1")

          expect(tv0).not_to be_nil
          expect(tv0.affect_to).to eq([tv1])
          expect(tv1).not_to be_nil
          expect(tv1.depends).to eq([tv0])
        end
      end
    end
  end
end
