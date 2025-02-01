# frozen_string_literal: true

require_relative "exwiw/version"

require_relative "exwiw/runner"
require_relative "exwiw/config"
require_relative "exwiw/database"
require_relative "exwiw/table"
require_relative "exwiw/table_column"
require_relative "exwiw/belongs_to_relation"
require_relative "exwiw/serde/v"

module Exwiw
  class Error < StandardError; end
  # Your code goes here...
end
