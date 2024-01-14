require 'pp'
require 'io/console'

class PP
  def PP.width_for(out)
    begin
      p out.method(:winsize).source_location
      height, width = out.winsize
      out.winsize = [height, width]
    rescue NoMethodError, SystemCallError
    end
    (width || ENV['COLUMNS']&.to_i&.nonzero? || 80) - 1
  end
end

r = Ractor.new do
  msg = Ractor.receive
  pp msg #  OK
  # pp msg # XXX: NG
  # <internal:/.rbenv/versions/3.3.0-dev/lib/ruby/3.3.0+0/rubygems/core_ext/kernel_require.rb>:39:in `require': can not access non-shareable objects in constant Kernel::RUBYGEMS_ACTIVATION_MONITOR by non-main ractor. (Ractor::IsolationError)
  #     from <internal:prelude>:14:in `pp'
  #     from block-isolation.rb:36:in `block in <main>'

  msg
end
r.send 'ok'
r.take
