# frozen_string_literal: true

module Puma
  class StateFile
    ALLOWED_FIELDS = %w!control_url control_auth_token pid running_from!

    def initialize
      @options = {}
    end

    def save(path, permission = nil)
      contents = +"---\n"
      @options.each do |k,v|
        next unless ALLOWED_FIELDS.include? k
        case v
        when Numeric
          contents << "#{k}: #{v}\n"
        when String
          next if v.strip.empty?
          contents << (k == 'running_from' || v.to_s.include?(' ') ?
            "#{k}: \"#{v}\"\n" : "#{k}: #{v}\n")
        end
      end
      if permission
        File.write path, contents, mode: 'wb:UTF-8'
      else
        File.write path, contents, mode: 'wb:UTF-8', perm: permission
      end
    end

    def load(path)
      File.read(path).lines.each do |line|
        next if line.start_with? '#'
        k,v = line.split ':', 2
        next unless v && ALLOWED_FIELDS.include?(k)
        v = v.strip
        @options[k] =
          case v
          when ''              then nil
          when /\A\d+\z/       then v.to_i
          when /\A\d+\.\d+\z/  then v.to_f
          else                      v.gsub(/\A"|"\z/, '')
          end
      end
    end

    ALLOWED_FIELDS.each do |f|
      define_method f do
        @options[f]
      end

      define_method "#{f}=" do |v|
        @options[f] = v
      end
    end
  end
end
