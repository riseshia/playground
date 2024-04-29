require 'prism'

class CallVisitor < Prism::Visitor
  def visit_call_node(node)
    if node.arguments &&
        node.message_loc.start_line != node.arguments.location&.end_line
      p node.message
      p node.message_loc

      puts "We need to coloring this method call"
      p node.arguments.location.end_line
    end

    super
  end
end

result = Prism.parse_file('some_app.rb')

prog_node = result.value

visitor = CallVisitor.new
visitor.visit(prog_node)
