# frozen_string_literal: true

module ZatsuLsp
  describe LocToNode do
    describe "#lookup" do
      let(:code) do
        <<~CODE
          module App
            class Post
              def initialize(title, body)
                @title = title
                @body = body
              end

              def title
                @title
              end

              def self.find(id)
                Repository.find(Post, id)
              end
            end
          end
        CODE
      end
      let(:node) { Prism.parse(code).value }

      it "return module" do
        result = described_class.lookup(node, row: 1, column: 1)
        expect(result.type).to eq(:module_node)
      end

      it "return App" do
        result = described_class.lookup(node, row: 1, column: 7)
        expect(result.type).to eq(:constant_read_node)
      end

      it "return class" do
        result = described_class.lookup(node, row: 2, column: 3)
        expect(result.type).to eq(:class_node)
      end

      it "return def initialize" do
        result = described_class.lookup(node, row: 3, column: 4)
        expect(result.type).to eq(:def_node)
      end

      it "return arg title of initialize" do
        result = described_class.lookup(node, row: 3, column: 19)
        expect(result.type).to eq(:required_parameter_node)
      end

      it "return ivar title" do
        result = described_class.lookup(node, row: 9, column: 6)
        expect(result.type).to eq(:instance_variable_read_node)
      end

      it "return call" do
        result = described_class.lookup(node, row: 13, column: 19)
        expect(result.type).to eq(:call_node)
      end
    end
  end
end
