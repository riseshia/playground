require "sinatra"

set :environment, :production

get "/" do
  "Hello, world!!\n"
end

get "/healthcheck" do
  "200~\n"
end
