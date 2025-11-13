require 'prism'

class RactorParallel
  def self.run(file_path, iterations, ractor_count = 8)
    # Read file content once and pass it to ractors
    source = File.read(file_path)

    results = []
    ractors = []

    iterations_per_ractor = iterations / ractor_count
    remainder = iterations % ractor_count

    ractor_count.times do |i|
      iterations_for_this_ractor = iterations_per_ractor
      iterations_for_this_ractor += 1 if i < remainder

      ractors << Ractor.new(source, iterations_for_this_ractor) do |src, iter|
        ractor_results = []

        iter.times do
          result = Prism.parse(src)
          local_vars = []

          visit_node = lambda do |node|
            case node
            when Prism::LocalVariableWriteNode
              local_vars << node.name.to_s
            when Prism::LocalVariableAndWriteNode
              local_vars << node.name.to_s
            when Prism::LocalVariableOrWriteNode
              local_vars << node.name.to_s
            when Prism::LocalVariableOperatorWriteNode
              local_vars << node.name.to_s
            when Prism::LocalVariableTargetNode
              local_vars << node.name.to_s
            end

            node.compact_child_nodes.each do |child|
              visit_node.call(child)
            end
          end

          visit_node.call(result.value)
          ractor_results << local_vars.uniq
        end

        ractor_results
      end
    end

    ractors.each do |ractor|
      results.concat(ractor.take)
    end

    results
  end
end
