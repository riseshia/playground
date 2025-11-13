require 'prism'

class RactorParallel
  def self.run(file_paths, ractor_count = 8)
    results = []
    ractors = []

    iterations = file_paths.size
    iterations_per_ractor = iterations / ractor_count
    remainder = iterations % ractor_count

    current_index = 0

    ractor_count.times do |i|
      iterations_for_this_ractor = iterations_per_ractor
      iterations_for_this_ractor += 1 if i < remainder

      start_index = current_index
      end_index = current_index + iterations_for_this_ractor
      current_index = end_index

      paths_for_ractor = file_paths[start_index...end_index]

      ractors << Ractor.new(paths_for_ractor) do |paths|
        ractor_results = []

        paths.each do |path|
          # Read file on each iteration
          src = File.read(path)
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
