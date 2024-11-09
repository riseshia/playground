class EventsController < ApplicationController
  include ActionController::Live

  def index
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Last-Modified"] = Time.now.httpdate

    sse = SSE.new(response.stream, event: "message")

    1..10.times do |i|
      sse.write({ message: "Hi there, Here is the number #{i}" })
    end
  ensure
    sse.close
  end

  def create
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Last-Modified"] = Time.now.httpdate

    sse = SSE.new(response.stream, event: "message")

    1..10.times do |i|
      sse.write({ message: "Hi there, Here is the number #{i}" })
    end
  ensure
    sse.close
  end
end
