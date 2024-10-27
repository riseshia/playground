# frozen_string_literal: true

module ZatsuLsp
  module Node
    class Node
      attr_reader :path, :node

      def initialize(path, prism_node)
        @path = path
        @node = prism_node
      end
    end
  end
end
