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

    context "when simple def" do
      let(:code) do
        <<~CODE
          def hello = 1
        CODE
      end

      it "registers method" do
        expect(method_registry.find("", "hello", visibility: :public, singleton: false)).not_to be_nil
      end
    end

    context "when class with public instance method" do
      let(:code) do
        <<~CODE
          class Post
            def hello = 1
          end
        CODE
      end

      it "registers all" do
        expect(method_registry.find("Post", "hello", visibility: :public, singleton: false)).not_to be_nil
      end
    end

    context "when class with private instance method" do
      context "when inline private" do
        let(:code) do
          <<~CODE
            class Post
              private def hello = 1
            end
          CODE
        end

        it "registers method" do
          skip
          expect(method_registry.find("Post", "hello", visibility: :private, singleton: false)).not_to be_nil
        end
      end

      context "when private declare" do
        let(:code) do
          <<~CODE
            class Post
              private
              def hello = 1
            end
          CODE
        end

        it "registers method" do
          skip
          expect(method_registry.find("Post", "hello", visibility: :private, singleton: false)).not_to be_nil
        end
      end
    end

    context "when class with class method" do
      context "with self." do
        let(:code) do
          <<~CODE
            class Post
              def self.hello = 1
            end
          CODE
        end

        it "registers all" do
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end

      context "with open self" do
        let(:code) do
          <<~CODE
            class Post
              class << self
                def hello = 1
              end
            end
          CODE
        end

        it "registers all" do
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end

      context "with self. in open self" do
        let(:code) do
          <<~CODE
            class Post
              class << self
                def self.hello = 1
              end
            end
          CODE
        end

        it "registers all" do
          skip
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end
    end

    context "type variable generation" do
      context "with self." do
        let(:code) do
          <<~CODE
            class Post
              def self.hello = 1
            end
          CODE
        end

        it "registers all" do
          expect(const_registry.find("Post")).not_to be_nil
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end

      context "with open self" do
        let(:code) do
          <<~CODE
            class Post
              class << self
                def hello = 1
              end
            end
          CODE
        end

        it "registers all" do
          expect(const_registry.find("Post")).not_to be_nil
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end
    end
  end
end
