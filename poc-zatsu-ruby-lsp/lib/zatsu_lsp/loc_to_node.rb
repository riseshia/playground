# frozen_string_literal: true

module ZatsuLsp
  module LocToNode
    class << self
      # row start from 1, column start from 0
      def lookup(node, row:, column:)
        target_node = node

        loop do
          next_node = target_node.compact_child_nodes.find do |child|
            in_range?(child, row: row, column: column)
          end

          break if next_node.nil?

          target_node = next_node
        end

        target_node
      end

      private def in_range?(node, row:, column:)
        loc = node.location

        return false if loc.start_line > row || row > loc.end_line
        return false if loc.start_line == row && column < loc.start_column
        return false if loc.end_line == row && column > loc.end_column

        true
      end
    end
  end
end
