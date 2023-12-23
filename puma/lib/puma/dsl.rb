# frozen_string_literal: true

require_relative 'const'
require_relative 'util'

module Puma
  class DSL
    ON_WORKER_KEY = [String, Symbol].freeze

    def self.ssl_bind_str(host, port, opts)
      verify = opts.fetch(:verify_mode, 'none').to_s

      tls_str =
        if opts[:no_tlsv1_1]  then '&no_tlsv1_1=true'
        elsif opts[:no_tlsv1] then '&no_tlsv1=true'
        else ''
        end

      ca_additions = "&ca=#{Puma::Util.escape(opts[:ca])}" if ['peer', 'force_peer'].include?(verify)

      low_latency_str = opts.key?(:low_latency) ? "&low_latency=#{opts[:low_latency]}" : ''
      backlog_str = opts[:backlog] ? "&backlog=#{Integer(opts[:backlog])}" : ''

      if defined?(JRUBY_VERSION)
        cipher_suites = opts[:ssl_cipher_list] ? "&ssl_cipher_list=#{opts[:ssl_cipher_list]}" : nil # old name
        cipher_suites = "#{cipher_suites}&cipher_suites=#{opts[:cipher_suites]}" if opts[:cipher_suites]
        protocols = opts[:protocols] ? "&protocols=#{opts[:protocols]}" : nil

        keystore_additions = "keystore=#{opts[:keystore]}&keystore-pass=#{opts[:keystore_pass]}"
        keystore_additions = "#{keystore_additions}&keystore-type=#{opts[:keystore_type]}" if opts[:keystore_type]
        if opts[:truststore]
          truststore_additions = "&truststore=#{opts[:truststore]}"
          truststore_additions = "#{truststore_additions}&truststore-pass=#{opts[:truststore_pass]}" if opts[:truststore_pass]
          truststore_additions = "#{truststore_additions}&truststore-type=#{opts[:truststore_type]}" if opts[:truststore_type]
        end

        "ssl://#{host}:#{port}?#{keystore_additions}#{truststore_additions}#{cipher_suites}#{protocols}" \
          "&verify_mode=#{verify}#{tls_str}#{ca_additions}#{backlog_str}"
      else
        ssl_cipher_filter = opts[:ssl_cipher_filter] ? "&ssl_cipher_filter=#{opts[:ssl_cipher_filter]}" : nil
        v_flags = (ary = opts[:verification_flags]) ? "&verification_flags=#{Array(ary).join ','}" : nil

        cert_flags = (cert = opts[:cert]) ? "cert=#{Puma::Util.escape(cert)}" : nil
        key_flags = (key = opts[:key]) ? "&key=#{Puma::Util.escape(key)}" : nil
        password_flags = (password_command = opts[:key_password_command]) ? "&key_password_command=#{Puma::Util.escape(password_command)}" : nil

        reuse_flag =
          if (reuse = opts[:reuse])
            if reuse == true
              '&reuse=dflt'
            elsif reuse.is_a?(Hash) && (reuse.key?(:size) || reuse.key?(:timeout))
              val = +''
              if (size = reuse[:size]) && Integer === size
                val << size.to_s
              end
              if (timeout = reuse[:timeout]) && Integer === timeout
                val << ",#{timeout}"
              end
              if val.empty?
                nil
              else
                "&reuse=#{val}"
              end
            else
              nil
            end
          else
            nil
          end

        "ssl://#{host}:#{port}?#{cert_flags}#{key_flags}#{password_flags}#{ssl_cipher_filter}" \
          "#{reuse_flag}&verify_mode=#{verify}#{tls_str}#{ca_additions}#{v_flags}#{backlog_str}#{low_latency_str}"
      end
    end

    def initialize(options, config)
      @config  = config
      @options = options

      @plugins = []
    end

    def _load_from(path)
      if path
        @path = path
        instance_eval(File.read(path), path, 1)
      end
    ensure
      _offer_plugins
    end

    def _offer_plugins
      @plugins.each do |o|
        if o.respond_to? :config
          @options.shift
          o.config self
        end
      end

      @plugins.clear
    end

    def set_default_host(host)
      @options[:default_host] = host
    end

    def default_host
      @options[:default_host] || Configuration::DEFAULTS[:tcp_host]
    end

    def inject(&blk)
      instance_eval(&blk)
    end

    def get(key,default=nil)
      @options[key.to_sym] || default
    end

    def plugin(name)
      @plugins << @config.load_plugin(name)
    end

    def app(obj=nil, &block)
      obj ||= block

      raise "Provide either a #call'able or a block" unless obj

      @options[:app] = obj
    end

    def activate_control_app(url="auto", opts={})
      if url == "auto"
        path = Configuration.temp_path
        @options[:control_url] = "unix://#{path}"
        @options[:control_url_temp] = path
      else
        @options[:control_url] = url
      end

      if opts[:no_token]
        auth_token = 'none'
      else
        auth_token = opts[:auth_token]
        auth_token ||= Configuration.random_token
      end

      @options[:control_auth_token] = auth_token
      @options[:control_url_umask] = opts[:umask] if opts[:umask]
    end

    def load(file)
      @options[:config_files] ||= []
      @options[:config_files] << file
    end

    def bind(url)
      @options[:binds] ||= []
      @options[:binds] << url
    end

    def clear_binds!
      @options[:binds] = []
    end

    def bind_to_activated_sockets(bind=true)
      @options[:bind_to_activated_sockets] = bind
    end

    def port(port, host=nil)
      host ||= default_host
      bind URI::Generic.build(scheme: 'tcp', host: host, port: Integer(port)).to_s
    end

    def first_data_timeout(seconds)
      @options[:first_data_timeout] = Integer(seconds)
    end

    def persistent_timeout(seconds)
      @options[:persistent_timeout] = Integer(seconds)
    end

    def idle_timeout(seconds)
      @options[:idle_timeout] = Integer(seconds)
    end

    def clean_thread_locals(which=true)
      @options[:clean_thread_locals] = which
    end

    def drain_on_shutdown(which=true)
      @options[:drain_on_shutdown] = which
    end

    def environment(environment)
      @options[:environment] = environment
    end

    def force_shutdown_after(val=:forever)
      i = case val
          when :forever
            -1
          when :immediately
            0
          else
            Float(val)
          end

      @options[:force_shutdown_after] = i
    end

    def on_restart(&block)
      @options[:on_restart] ||= []
      @options[:on_restart] << block
    end

    def restart_command(cmd)
      @options[:restart_cmd] = cmd.to_s
    end

    def pidfile(path)
      @options[:pidfile] = path.to_s
    end

    def quiet(which=true)
      @options[:log_requests] = !which
    end

    def log_requests(which=true)
      @options[:log_requests] = which
    end

    def custom_logger(custom_logger)
      @options[:custom_logger] = custom_logger
    end

    def debug
      @options[:debug] = true
    end

    def rackup(path)
      @options[:rackup] ||= path.to_s
    end

    def rack_url_scheme(scheme=nil)
      @options[:rack_url_scheme] = scheme
    end

    def early_hints(answer=true)
      @options[:early_hints] = answer
    end

    def stdout_redirect(stdout=nil, stderr=nil, append=false)
      @options[:redirect_stdout] = stdout
      @options[:redirect_stderr] = stderr
      @options[:redirect_append] = append
    end

    def log_formatter(&block)
      @options[:log_formatter] = block
    end

    def threads(min, max)
      min = Integer(min)
      max = Integer(max)
      if min > max
        raise "The minimum (#{min}) number of threads must be less than or equal to the max (#{max})"
      end

      if max < 1
        raise "The maximum number of threads (#{max}) must be greater than 0"
      end

      @options[:min_threads] = min
      @options[:max_threads] = max
    end

    def ssl_bind(host, port, opts = {})
      add_pem_values_to_options_store(opts)
      bind self.class.ssl_bind_str(host, port, opts)
    end

    def state_path(path)
      @options[:state] = path.to_s
    end

    def state_permission(permission)
      @options[:state_permission] = permission
    end

    def workers(count)
      @options[:workers] = count.to_i
    end

    def silence_single_worker_warning
      @options[:silence_single_worker_warning] = true
    end

    def silence_fork_callback_warning
      @options[:silence_fork_callback_warning] = true
    end

    def before_fork(&block)
      warn_if_in_single_mode('before_fork')

      @options[:before_fork] ||= []
      @options[:before_fork] << block
    end

    def on_worker_boot(key = nil, &block)
      warn_if_in_single_mode('on_worker_boot')

      process_hook :before_worker_boot, key, block, 'on_worker_boot'
    end

    def on_worker_shutdown(key = nil, &block)
      warn_if_in_single_mode('on_worker_shutdown')

      process_hook :before_worker_shutdown, key, block, 'on_worker_shutdown'
    end

    def on_worker_fork(&block)
      warn_if_in_single_mode('on_worker_fork')

      process_hook :before_worker_fork, nil, block, 'on_worker_fork'
    end

    def after_worker_fork(&block)
      warn_if_in_single_mode('after_worker_fork')

      process_hook :after_worker_fork, nil, block, 'after_worker_fork'
    end

    alias_method :after_worker_boot, :after_worker_fork

    def on_booted(&block)
      @config.options[:events].on_booted(&block)
    end

    def on_refork(key = nil, &block)
      process_hook :before_refork, key, block, 'on_refork'
    end

    def on_thread_start(&block)
      @options[:before_thread_start] ||= []
      @options[:before_thread_start] << block
    end

    def on_thread_exit(&block)
      @options[:before_thread_exit] ||= []
      @options[:before_thread_exit] << block
    end

    def out_of_band(&block)
      process_hook :out_of_band, nil, block, 'out_of_band'
    end

    def directory(dir)
      @options[:directory] = dir.to_s
    end

    def preload_app!(answer=true)
      @options[:preload_app] = answer
    end

    def lowlevel_error_handler(obj=nil, &block)
      obj ||= block
      raise "Provide either a #call'able or a block" unless obj
      @options[:lowlevel_error_handler] = obj
    end

    def prune_bundler(answer=true)
      @options[:prune_bundler] = answer
    end

    def raise_exception_on_sigterm(answer=true)
      @options[:raise_exception_on_sigterm] = answer
    end

    def extra_runtime_dependencies(answer = [])
      @options[:extra_runtime_dependencies] = Array(answer)
    end

    def tag(string)
      @options[:tag] = string.to_s
    end

    def worker_check_interval(interval)
      @options[:worker_check_interval] = Integer(interval)
    end

    def worker_timeout(timeout)
      timeout = Integer(timeout)
      min = @options.fetch(:worker_check_interval, Configuration::DEFAULTS[:worker_check_interval])

      if timeout <= min
        raise "The minimum worker_timeout must be greater than the worker reporting interval (#{min})"
      end

      @options[:worker_timeout] = timeout
    end

    def worker_boot_timeout(timeout)
      @options[:worker_boot_timeout] = Integer(timeout)
    end

    def worker_shutdown_timeout(timeout)
      @options[:worker_shutdown_timeout] = Integer(timeout)
    end

    def worker_culling_strategy(strategy)
      stategy = strategy.to_sym

      if ![:youngest, :oldest].include?(strategy)
        raise "Invalid value for worker_culling_strategy - #{stategy}"
      end

      @options[:worker_culling_strategy] = strategy
    end

    def queue_requests(answer=true)
      @options[:queue_requests] = answer
    end

    def shutdown_debug(val=true)
      @options[:shutdown_debug] = val
    end

    def wait_for_less_busy_worker(val=0.005)
      @options[:wait_for_less_busy_worker] = val.to_f
    end

    def set_remote_address(val=:socket)
      case val
      when :socket
        @options[:remote_address] = val
      when :localhost
        @options[:remote_address] = :value
        @options[:remote_address_value] = "127.0.0.1".freeze
      when String
        @options[:remote_address] = :value
        @options[:remote_address_value] = val
      when Hash
        if hdr = val[:header]
          @options[:remote_address] = :header
          @options[:remote_address_header] = "HTTP_" + hdr.upcase.tr("-", "_")
        elsif protocol_version = val[:proxy_protocol]
          @options[:remote_address] = :proxy_protocol
          protocol_version = protocol_version.downcase.to_sym
          unless [:v1].include?(protocol_version)
            raise "Invalid value for proxy_protocol - #{protocol_version.inspect}"
          end
          @options[:remote_address_proxy_protocol] = protocol_version
        else
          raise "Invalid value for set_remote_address - #{val.inspect}"
        end
      else
        raise "Invalid value for set_remote_address - #{val}"
      end
    end

    def fork_worker(after_requests=1000)
      @options[:fork_worker] = Integer(after_requests)
    end

    def max_fast_inline(num_of_requests)
      @options[:max_fast_inline] = Float(num_of_requests)
    end

    def io_selector_backend(backend)
      @options[:io_selector_backend] = backend.to_sym
    end

    def mutate_stdout_and_stderr_to_sync_on_write(enabled=true)
      @options[:mutate_stdout_and_stderr_to_sync_on_write] = enabled
    end

    def http_content_length_limit(limit)
      @options[:http_content_length_limit] = limit
    end

    def supported_http_methods(methods)
      if methods == :any
        @options[:supported_http_methods] = :any
      elsif Array === methods && methods == (ary = methods.grep(String).uniq) &&
        !ary.empty?
        @options[:supported_http_methods] = ary
      else
        raise "supported_http_methods must be ':any' or a unique array of strings"
      end
    end

    private

    def add_pem_values_to_options_store(opts)
      return if defined?(JRUBY_VERSION)

      @options[:store] ||= []

      # Store cert_pem and key_pem to options[:store] if present
      [:cert, :key].each do |v|
        opt_key = :"#{v}_pem"
        if opts[opt_key]
          index = @options[:store].length
          @options[:store] << opts[opt_key]
          opts[v] = "store:#{index}"
        end
      end
    end

    def process_hook(options_key, key, block, meth)
      @options[options_key] ||= []
      if ON_WORKER_KEY.include? key.class
        @options[options_key] << [block, key.to_sym]
      elsif key.nil?
        @options[options_key] << block
      else
        raise "'#{meth}' key must be String or Symbol"
      end
    end

    def warn_if_in_single_mode(hook_name)
      return if @options[:silence_fork_callback_warning]

      workers_val = @config.options.user_options[:workers] || @options[:workers] ||
        @config.puma_default_options[:workers] || 0
      if workers_val == 0
        log_string =
          "Warning: You specified code to run in a `#{hook_name}` block, " \
          "but Puma is not configured to run in cluster mode (worker count > 0 ), " \
          "so your `#{hook_name}` block did not run"

        LogWriter.stdio.log(log_string)
      end
    end
  end
end
