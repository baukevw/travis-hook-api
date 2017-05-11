require 'sinatra'
require 'json'
require 'digest/sha2'
require 'dotenv'
require 'sinatra/logger'

# Setting the encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8


class TravisHookAPI < Sinatra::Base
  set :token, ENV['TRAVIS_USER_TOKEN']
  logger filename: "log/#{settings.environment}.log", level: :trace
  Dotenv.load

  get '/' do
    logger.info("Hello World.")
    'Hello World'
  end

  post '/' do
    if not valid_request?
      logger.info("Invalid payload request for repository #{repo_slug}")
    else
      payload = JSON.parse(params[:payload])
      logger.info("Received valid payload for repository #{repo_slug}")
      logger.info(payload)
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
