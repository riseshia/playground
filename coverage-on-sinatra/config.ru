require 'coverage'
Coverage.start(lines: true)
require_relative 'coverage_result'

require_relative 'app'

use CoverageResult
run App
