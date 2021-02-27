#!/usr/bin/env ruby
require 'time'
require 'date'

require 'sinatra'
require 'redis'
require 'oj'
require 'multi_json'
require 'bcrypt'
require 'securerandom'
require 'openssl'


require 'pry'
require 'pry-byebug'

$redis = Redis.new(url: "redis://localhost/14")

def symbolize_keys(hash)
  Hash[
    hash.map do |key, value|
      [ key.to_sym, value ]
    end
  ]
end

$user_db = MultiJson.load(File.read("users.json")).map { |x| symbolize_keys(x) }

set :public_folder, 'public'

post '/send_message' do
  payload = MultiJson.load(request.body.read)

  api_token = request.env['HTTP_API_TOKEN']
  if !api_token
    # error message....
  end

  token_hash = OpenSSL::Digest.hexdigest('sha256', api_token)

  user = $user_db.find { |u| u[:token] == token_hash }
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

def generate_user_token(user)
  token = SecureRandom.alphanumeric(128)
  hashed_token = OpenSSL::Digest.hexdigest('sha256', token)
  user[:token] = hashed_token

  save_users_database

  token
end

def save_users_database
  content = MultiJson.dump($user_db, pretty: true)
  File.write("users.json", content)
end

post '/perform_login' do
  payload = MultiJson.load(request.body.read)

  user = $user_db.find do |u|
    u[:username] == payload["username"]
  end

  if user
    user_password = BCrypt::Password.new(user[:password])

    if user_password == payload["password"]
      token = generate_user_token(user)

      return MultiJson.dump({
        status: "login_success",
        token: token,
        full_name: user[:full_name]
      })
    end
  else
    BCrypt::Password.new("$2a$12$JZlPBqTyGMm6vbgseb6fROYwDIpeSfHnMQ30AU9rCKq/cJquGOwLG") == payload["password"]
  end

  MultiJson.dump({
    status: "login_failed",
    message: "User name or password are wrong"
  })
end
