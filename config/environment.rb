
if !ENV['RACK_ENV']
  ENV['RACK_ENV'] = 'development'
else
  valid_envs = %w(development production)
  unless valid_envs.include?(ENV['RACK_ENV'])
    puts "Environment '#{ENV['RACK_ENV']}' is invalid, must be one of #{valid_env}"
    exit(1)
  end
end

require 'zeitwerk'

Zeitwerk::Loader.new.tap do |loader|
  lib_path = File.expand_path("../lib", __dir__)
  loader.push_dir(lib_path)
  loader.setup

  loader.eager_load if ENV['RACK_ENV'] == 'production'
end

require 'time'
require 'date'

require 'sinatra'
require 'sinatra/namespace'

require 'redis'
require 'oj'
require 'multi_json'
require 'bcrypt'
require 'securerandom'
require 'openssl'

if ENV['RACK_ENV'] == "development"
  require 'pry'
  require 'pry-byebug'
end

class AppEnvironment
  attr_reader :env

  def self.instance
    @instance ||= new
  end

  def root_path
    File.expand_path("../", __dir__)
  end

  def boot!
    raise "Application is already booted. Aborting" if @booted
    @booted = true

    @env = ENV['RACK_ENV']

    load_config

    setup_db_connections
  end

  def setup_db_connections
    $redis = Redis.new(url: @redis_url)

    def symbolize_keys(hash)
      Hash[
        hash.map do |key, value|
          [ key.to_sym, value ]
        end
      ]
    end

    $user_db = MultiJson.load(File.read("users.json")).map { |x| symbolize_keys(x) }
  end

  private

  def load_config
    @redis_url = ENV["REDIS_URL"]

    @redis_url ||= "redis://localhost/14" if env == "development"

    if !@redis_url || @redis_url == ""
      raise "REDIS_URL env var must be a valid URL"
    end
  end
end
