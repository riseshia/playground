# frozen_string_literal: true

# Specification Helper
# This file determines which Ractor::Port implementation to use:
# - Ruby 3.5+: Native Ractor::Port
# - Ruby 3.3/3.4: Backported Ractor::Port
#
# This allows running the same test suite against both implementations
# to verify specification compliance.

RUBY_VERSION_PARTS = RUBY_VERSION.split('.').map(&:to_i)
RUBY_MAJOR = RUBY_VERSION_PARTS[0]
RUBY_MINOR = RUBY_VERSION_PARTS[1]

# Check if we need to load the backport
if RUBY_MAJOR < 3 || (RUBY_MAJOR == 3 && RUBY_MINOR < 5)
  puts "Ruby #{RUBY_VERSION} detected: Loading backported Ractor::Port"
  require_relative '../lib/ractor_port'
  USING_BACKPORT = true
else
  puts "Ruby #{RUBY_VERSION} detected: Using native Ractor::Port"

  # Check if native Ractor::Port exists
  begin
    Ractor::Port
    USING_BACKPORT = false
  rescue NameError
    puts "Warning: Native Ractor::Port not found, loading backport"
    require_relative '../lib/ractor_port'
    USING_BACKPORT = true
  end
end

def port_implementation_info
  if USING_BACKPORT
    "Backported Ractor::Port (Ruby #{RUBY_VERSION})"
  else
    "Native Ractor::Port (Ruby #{RUBY_VERSION})"
  end
end
