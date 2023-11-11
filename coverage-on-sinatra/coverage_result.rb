class CoverageResult
  PADDING = 4

  def initialize(app, name = nil)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] == '/coverage'
      matched = env['QUERY_STRING'].match(/path=([^&]+)/)
      path = matched ? matched[1] : 'app.rb'

      if !path.start_with?('/')
        path = "#{Dir.pwd}/#{path}"
      end

      result = Coverage.peek_result[path]
      html = render_result(path, result)
      [200, { 'Content-Type' => 'text/html;charset=utf-8' }, [html]]
    else
      @app.call(env)
    end
  end

  private def render_result(path, result)
    if result.nil?
      return "There is emtpy result for #{path}"
    end

    unless File.exist?(path)
      return "<" + "p>#{path} not found.<" + "/p>"
    end

    coverage_on_line = result[:lines]

    rows = []
    File.read(path).each_line.with_index do |line, index|
      prefix = coverage_on_line[index].to_s.rjust(PADDING)
      lineno = (index + 1).to_s.rjust(PADDING)

      rows << "#{prefix} #{lineno}: #{line}"
    end

    "<" + "pre>" + rows.join + "<" + "/pre>"
  end
end
