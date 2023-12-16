# frozen_string_literal: true

require "socket"

module Puma
  module SdNotify
    class NotifyError < RuntimeError; end

    READY     = "READY=1"
    RELOADING = "RELOADING=1"
    STOPPING  = "STOPPING=1"
    STATUS    = "STATUS="
    ERRNO     = "ERRNO="
    MAINPID   = "MAINPID="
    WATCHDOG  = "WATCHDOG=1"
    FDSTORE   = "FDSTORE=1"

    def self.ready(unset_env=false)
      notify(READY, unset_env)
    end

    def self.reloading(unset_env=false)
      notify(RELOADING, unset_env)
    end

    def self.stopping(unset_env=false)
      notify(STOPPING, unset_env)
    end

    def self.status(status, unset_env=false)
      notify("#{STATUS}#{status}", unset_env)
    end

    def self.errno(errno, unset_env=false)
      notify("#{ERRNO}#{errno}", unset_env)
    end

    def self.mainpid(pid, unset_env=false)
      notify("#{MAINPID}#{pid}", unset_env)
    end

    def self.watchdog(unset_env=false)
      notify(WATCHDOG, unset_env)
    end

    def self.fdstore(unset_env=false)
      notify(FDSTORE, unset_env)
    end

    def self.watchdog?
      wd_usec = ENV["WATCHDOG_USEC"]
      wd_pid = ENV["WATCHDOG_PID"]

      return false if !wd_usec

      begin
        wd_usec = Integer(wd_usec)
      rescue
        return false
      end

      return false if wd_usec <= 0
      return true if !wd_pid || wd_pid == $$.to_s

      false
    end

    def self.notify(state, unset_env=false)
      sock = ENV["NOTIFY_SOCKET"]

      return nil if !sock

      ENV.delete("NOTIFY_SOCKET") if unset_env

      begin
        Addrinfo.unix(sock, :DGRAM).connect do |s|
          s.close_on_exec = true
          s.write(state)
        end
      rescue StandardError => e
        raise NotifyError, "#{e.class}: #{e.message}", e.backtrace
      end
    end
  end
end
