# frozen_string_literal: true

module ZatsuLsp
  class Constant
    attr_reader :path, :node

    def initialize(path, prism_node)
      @path = path
      @node = prism_node
    end
  end
end
