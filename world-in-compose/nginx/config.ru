require 'rack/reverse_proxy'

use Rack::ReverseProxy do
  # Set :preserve_host to true globally (default is true already)
  reverse_proxy_options preserve_host: true

  # Forward the path /test* to http://example.com/test*
  reverse_proxy '/', 'http://app:4567/'
end

app = proc do |_env|
  [ 200, {'Content-Type' => 'text/plain'}, ["b"] ]
end

run app
