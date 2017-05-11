require 'sinatra'
require 'json'
require 'digest/sha2'
require 'dotenv'
require 'logger'

# Setting the encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

FILE = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')

LOGGER = Logger.new(FILE)


class TravisHookAPI < Sinatra::Base
  set :token, ENV['TRAVIS_USER_TOKEN']
  Dotenv.load

  configure do
    enable :logging

    FILE.sync = true
    use Rack::CommonLogger, FILE

    LOGGER.formatter = proc do |severity, datetime, progname, msg|
       "LOG: #{msg}\n"
    end
  end


  get '/' do
    LOGGER.info("Hello World")
    'Hello World'
  end

  post '/' do
    if not valid_request?
      LOGGER.info("Invalid payload request for repository #{repo_slug}")
    else
      payload = JSON.parse(params[:payload])
      LOGGER.info("Received valid payload for repository #{repo_slug}")
      LOGGER.info(payload)
    end
  end

  def valid_request?
    digest = Digest::SHA2.new.update("#{repo_slug}#{settings.token}")
    digest.to_s == authorization
  end

  def authorization
    env['HTTP_AUTHORIZATION']
  end

  def repo_slug
    env['HTTP_TRAVIS_REPO_SLUG']
  end
end
