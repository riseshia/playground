# frozen_string_literal: true

module ZatsuLsp
  class Method
    attr_reader :path, :node, :node_id,
                :arg_tvs, :return_tvs

    def initialize(path:, node:)
      @node_id = node.node_id
      @path = path
      @node = node

      @arg_tvs = []
      @return_tvs = []
      @dependents = [] # method call location
    end

    def inference_arg(_name)
      nil
    end

    def add_arg_tv(arg_tv)
      @arg_tvs << arg_tv
    end

    def add_return_tv(return_tv)
      @return_tvs << return_tv
    end

    def add_call_location(call_tv)
      @dependents << call_tv
    end
  end
end
