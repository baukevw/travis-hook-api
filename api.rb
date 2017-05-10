require 'sinatra'
require 'json'
require 'digest/sha2'
require 'dotenv'

class TravisHookAPI < Sinatra::Base
  set :token, ENV['TRAVIS_USER_TOKEN']
  Dotenv.load
  # Setting the encoding
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8

  post '/' do
    if not valid_request?
      puts "Invalid payload request for repository #{repo_slug}"
    else
      payload = JSON.parse(params[:payload])
      puts "Received valid payload for repository #{repo_slug}"
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
