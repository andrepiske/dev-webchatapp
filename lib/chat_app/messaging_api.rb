
module ChatApp::MessagingApi
  def self.registered(app)
    app.register Sinatra::Namespace

    app.namespace '/m' do
      post '/send' do
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

      get '/poll/:cursor' do
        cursor = Time.at(params[:cursor].to_i)

        iterations = 0
        messages = nil

        loop do
          messages = $redis.lrange("messages", 0, -1).map do |msg_string|
            MultiJson.load(msg_string)
          end

          messages = messages.select do |msg|
            msg_timestamp = Time.parse(msg["current_time"])

            msg_timestamp > cursor
          end

          break unless messages.empty?

          iterations += 1
          break if iterations > 30

          puts "polling messages..."
          sleep(1)
        end

        MultiJson.dump(messages)
      end
    end
  end
end
