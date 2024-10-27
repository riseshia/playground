# frozen_string_literal: true

module ZatsuLsp
  class TypeVariable
    attr_reader :id, :candidates, :depends, :affect_to, :node, :path, :stable

    def initialize(path, name, node)
      @id = build_id(name)
      @path = path
      @node = node
      @candidates = []
      @depends = []
      @affect_to = []
      @stable = false
    end

    private def build_id(name)
    end
  end
end
