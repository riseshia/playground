# frozen_string_literal: true

module ZatsuLsp
  class Method
    attr_reader :path, :node, :receiver_type,
                :arg_tvs, :return_tvs, :return_type

    def initialize(path:, receiver_type:, node:)
      @path = path
      @node = node
      @receiver_type = receiver_type

      @arg_types = {}
      @return_type = nil

      @arg_tvs = []
      @return_tvs = []
      @call_location_tvs = []
    end

    def node_id = (@node_id ||= @node.node_id)

    def name
      @node.name
    end

    def inference_arg_type(name)
      if @arg_types.key?(name)
        @arg_types[name]
      else
        # Try some guess with @call_location_tvs
        Type.any
      end
    end

    def inference_return_type
      if @return_type
        @return_type
      else
        # Try some guess with @return_tvs
        Type.any
      end
    end

    def add_arg_type(name, type)
      @arg_types[name] = type
    end

    def add_return_type(type)
      @return_type = type
    end

    def add_arg_tv(arg_tv)
      @arg_tvs << arg_tv
      arg_tv.add_method_obj(self)
    end

    def add_return_tv(return_tv)
      @return_tvs << return_tv
    end

    def add_call_location_tv(call_tv)
      @call_location_tvs << call_tv
    end
  end
end
