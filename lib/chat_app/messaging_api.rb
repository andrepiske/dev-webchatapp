
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

        AppEnvironment.instance.redis_pool.with do |redis|
          serialized_message = MultiJson.dump({
            user_name: user_name,
            message_content: message_content,
            current_time: current_time
          })

          redis.rpush("messages", serialized_message)
          redis.keys("channel:reg:*").each do |key_name|
            channel_id = key_name.split(":").last

            redis.rpush("channel:#{channel_id}:messages", serialized_message)
          end
        end

        status 204
      end

      get '/archived' do
        messages = AppEnvironment.instance.redis_pool.with do |redis|
          redis.lrange("messages", 0, -1).map do |msg_string|
            MultiJson.load(msg_string)
          end
        end

        MultiJson.dump(messages)
      end

      get '/poll/:channel_id' do
        channel_id = params[:channel_id]

        if channel_id == "start"
          channel_id = SecureRandom.uuid
        end

        _, msg_string = AppEnvironment.instance.redis_pool.with do |redis|
          redis.set("channel:reg:#{channel_id}", "1")
          redis.brpop("channel:#{channel_id}:messages", timeout: 5)
        end

        if !msg_string
          return MultiJson.dump({
            channel_id: channel_id
          })
        end

        MultiJson.dump({
          channel_id: channel_id,
          message: MultiJson.load(msg_string)
        })
      end
    end
  end
end
