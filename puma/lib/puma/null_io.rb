# frozen_string_literal: true

module Puma
  class NullIO
    def gets
      nil
    end

    def string
      ""
    end

    def each
    end

    def read(length = nil, buffer = nil)
      if length.to_i < 0
        raise ArgumentError, "(negative length #{length} given)"
      end

      buffer = if buffer.nil?
        "".b
      else
        String.try_convert(buffer) or raise TypeError, "no implicit conversion of #{buffer.class} into String"
      end
      buffer.clear
      if length.to_i > 0
        nil
      else
        buffer
      end
    end

    def rewind
    end

    def close
    end

    def size
      0
    end

    def eof?
      true
    end

    def sync
      true
    end

    def sync=(v)
    end

    def puts(*ary)
    end

    def write(*ary)
    end

    def flush
      self
    end

    def closed?
      false
    end
  end
end
