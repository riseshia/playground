# Stands in for ruby-vips: this machine only has libvips 8.12 available and Mastodon
# aborts at boot below 8.13. Specs that actually process images fail under this stub.
module Vips
  class Error < StandardError; end

  def self.at_least_libvips?(_major, _minor) = true
  def self.block(_operation, _enabled) = nil
  def self.block_untrusted(_enabled) = nil
end
