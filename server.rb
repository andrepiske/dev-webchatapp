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

$user_db = [
  {
    username: "john",
    password: "sekret",
    token: "t9t938r39rt948yt4",
    full_name: "John Doe"
  },
  {
    username: "alice",
    password: "sekret",
    token: "9yr9hwe9uwnw9ufhwf",
    full_name: "Alice von Wonderland"
  }
]

set :public_folder, 'public'

post '/send_message' do
  payload = MultiJson.load(request.body.read)

  api_token = request.env['HTTP_API_TOKEN']
  if !api_token
    # error message....
  end

  user = $user_db.find { |u| u[:token] == api_token }
  if !user
    # error message....
    return
  end

  user_name = user[:username]
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

### Authentication stuff

post '/perform_login' do
  payload = MultiJson.load(request.body.read)

  $user_db.each do |user|
    if user[:username] == payload["username"] && user[:password] == payload["password"]

      return MultiJson.dump({
        status: "login_success",
        token: user[:token],
        full_name: user[:full_name]
      })
    end
  end

  MultiJson.dump({
    status: "login_failed",
    message: "User name or password are wrong"
  })
end
