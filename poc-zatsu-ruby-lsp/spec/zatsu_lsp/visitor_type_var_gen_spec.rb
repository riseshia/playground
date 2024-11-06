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
          a, one = type_var_registry.all
          expect(a.name).to eq("a")
          expect(one.name).to eq("1")

          expect(a.dependencies).to eq([one])
          expect(one.dependents).to eq([a])
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
          a0, one, a1, two = type_var_registry.all

          expect(a0.dependencies).to eq([one])
          expect(one.dependents).to eq([a0])
          expect(a1.dependencies).to eq([two])
          expect(two.dependents).to eq([a1])
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
          a0, one, a1, plus, a2, two = type_var_registry.all

          expect(a0.dependencies).to eq([one])
          expect(one.dependents).to eq([a0])
          expect(a1.dependencies).to eq([plus])
          expect(plus.dependencies).to eq([a2, two])
          expect(plus.dependents).to eq([a1])
          expect(plus.scope).to eq("")
          expect(a2.dependencies).to eq([a0])
          expect(a2.dependents).to eq([plus])
          expect(two.dependents).to eq([plus])
        end
      end

      context "with method call" do
        let(:code) do
          <<~CODE
            def hello
              a + 1
            end
          CODE
        end

        it "registers all" do
          plus, a0, one = type_var_registry.all

          expect(plus.dependencies).to eq([a0, one])
          expect(a0.dependents).to eq([plus])
          expect(one.dependents).to eq([plus])
        end
      end
    end
  end
end
