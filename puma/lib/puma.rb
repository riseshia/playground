# frozen_string_literal: true

require 'socket'
require 'tempfile'
require 'uri'
require 'stringio'

require 'thread'

require 'puma/puma_http11'

require_relative 'puma/detect'
require_relative 'puma/json_serialization'

module Puma
  autoload :Const, "#{__dir__}/puma/const"
  autoload :Server, "#{__dir__}/puma/server"
  autoload :Launcher, "#{__dir__}/puma/launcher"
  autoload :LogWriter, "#{__dir__}/puma/log_writer"

  HAS_SSL = const_defined?(:MiniSSL, false) && MiniSSL.const_defined?(:Engine, false)

  HAS_UNIX_SOCKET = Object.const_defined?(:UNIXSocket) && !IS_WINDOWS

  if HAS_SSL
    require_relative 'puma/minissl'
  else
    module MiniSSL
      class SSLError < StandardError; end
    end
  end

  def self.ssl?
    HAS_SSL
  end

  def self.abstract_unix_socket?
    @abstract_unix ||=
      if HAS_UNIX_SOCKET
        begin
          ::UNIXServer.new("\0puma.temp.unix").close
          true
        rescue ArgumentError
          false
        end
      else
        false
      end
  end

  def self.stats_object=(val)
    @get_stats = val
  end

  def self.stats
    Puma::JSONSerialization.generate(@get_stats.stats)
  end

  def self.stats_hash
    @get_stats.stats
  end

  def self.set_thread_name(name)
    Thread.current.name = "puma #{name}"
  end
end
