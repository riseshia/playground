# frozen_string_literal: true

module Puma
  HAS_FORK = ::Process.respond_to? :fork

  HAS_NATIVE_IO_WAIT = ::IO.public_instance_methods(false).include? :wait_readable

  IS_JRUBY = Object.const_defined? :JRUBY_VERSION

  IS_OSX = RUBY_DESCRIPTION.include? 'darwin'

  IS_WINDOWS = RUBY_DESCRIPTION.match?(/mswin|ming|cygwin/)

  IS_LINUX = !(IS_OSX || IS_WINDOWS)

  IS_MRI = RUBY_ENGINE == 'ruby'

  def self.jruby?
    IS_JRUBY
  end

  def self.osx?
    IS_OSX
  end

  def self.windows?
    IS_WINDOWS
  end

  def self.mri?
    IS_MRI
  end

  def self.forkable?
    HAS_FORK
  end
end
