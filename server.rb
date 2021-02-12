#!/usr/bin/env ruby
require 'time'
require 'date'

require 'sinatra'
require 'redis'
require 'oj'
require 'multi_json'

require 'pry'
require 'pry-byebug'

$redis = Redis.new(url: "redis://localhost/14")

set :public_folder, 'public'

post '/send_message' do
  payload = MultiJson.load(request.body.read)

  user_name = payload["user_name"]
  message_content = payload["message_content"]
  current_time = Time.now

  $redis.rpush("messages", MultiJson.dump({
    user_name: user_name,
    message_content: message_content,
    current_time: current_time
  }))

  status 204
end

get '/poll_messages/:cursor' do
  cursor = Time.at(params[:cursor].to_i)

  messages = $redis.lrange("messages", 0, -1).map do |msg_string|
    MultiJson.load(msg_string)
  end

  messages = messages.select do |msg|
    msg_timestamp = Time.parse(msg["current_time"])

    msg_timestamp > cursor
  end

  MultiJson.dump(messages)
end

get '/' do
  File.read("public/index.html")
end
