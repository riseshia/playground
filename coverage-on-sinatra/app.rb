# frozen_string_literal: true

require 'sinatra/base'

class App < Sinatra::Base
  get '/initialize' do
    'ok'
  end

  get '/' do
    1 + 1
    'Hello world!'
  end

  get '/results' do
    result = Coverage.peek_result[__FILE__]
    SimpleFormatter.html('app.rb', result)
  end
end
