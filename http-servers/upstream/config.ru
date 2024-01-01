headers = {'Content-Type'.freeze => 'text/plain'.freeze}.freeze
body = ['Hello World'.freeze].freeze
run lambda { |env| sleep 0.02; [200, headers, body] }
