
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

class ChatApp::Api < Sinatra::Base
  set :public_folder, File.join(AppEnvironment.instance.root_path, 'public')

  register ChatApp::MessagingApi

  get '/' do
    File.read("public/index.html")
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
end
