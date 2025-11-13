require 'prism'

class LocalVarExtractor
  def self.extract(file_path)
    source = File.read(file_path)
    result = Prism.parse(source)

    local_vars = []
    visit_node(result.value, local_vars)

    local_vars.uniq
  end

  def self.visit_node(node, local_vars)
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

    # Visit all child nodes
    node.compact_child_nodes.each do |child|
      visit_node(child, local_vars)
    end
  end
end
