# frozen_string_literal: true

require_relative 'runner'
require_relative 'detect'
require_relative 'plugin'

module Puma
  class Single < Runner
    def stats
      {
        started_at: utc_iso8601(@started_at)
      }.merge(@server.stats).merge(super)
    end

    def restart
      @server&.begin_restart
    end

    def stop
      @server&.stop false
    end

    def halt
      @server&.halt
    end

    def stop_blocked
      @server&.stop true
    end

    def run
      output_header "single"

      load_and_bind

      Plugins.fire_background

      start_control

      @server = server = start_server
      server_thread = server.run

      log "Use Ctrl-C to stop"
      redirect_io

      @events.fire_on_booted!

      debug_loaded_extensions("Loaded Extensions:") if @log_writer.debug?

      begin
        server_thread.join
      rescue Interrupt
        # Swallow it
      end
    end
  end
end
