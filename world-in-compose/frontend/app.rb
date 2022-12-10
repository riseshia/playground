require "sinatra"

set :environment, :production

get "/frontend" do
  "Hello, frontend!!\n"
end
