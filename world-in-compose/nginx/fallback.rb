require "sinatra"

set :environment, :production

not_found do
  upstream_name = request.env["HTTP_X_UPSTREAM_SERVICE"]
  "Can't find upstream #{upstream_name}. is it running?"
end
