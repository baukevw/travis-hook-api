require 'sinatra'
require 'json'
require 'digest/sha2'
require 'dotenv'
require 'logger'

require 'base64'
require 'open-uri'
require 'openssl'
require 'httparty'

# Setting the encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

FILE = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')

LOGGER = Logger.new(FILE)


class TravisHookAPI < Sinatra::Base
  set :token, ENV['TRAVIS_USER_TOKEN']
  TRAVIS_CONFIG_URL = 'https://api.travis-ci.org/config'.freeze
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
      LOGGER.info("Build status message: #{payload['status_message']}")
      if %w(Fixed Passed).include? status_message
        LOGGER.info("Fixed Passed")
        return if HTTParty.post(
          "http://pc.bauke.me/api/change",
          query: { "pin_number" => '0', "action" => "off" }
        )
      end
      if %w(Broken Failed Still Failing).include? status_message
        LOGGER.info("Broken Failed Still Failing")
        return if HTTParty.post(
          "http://pc.bauke.me/api/change",
          query: { "pin_number" => '0', "action" => "on" }
        )
      end
    end
  end

  private

  def valid_request?
    signature    = request.env["HTTP_SIGNATURE"]
    json_payload = params.fetch('payload', '')

    public_key.verify(
      OpenSSL::Digest::SHA1.new,
      Base64.decode64(signature),
      json_payload
    )
  end

  def public_key
    config = JSON.parse(open(TRAVIS_CONFIG_URL).read)
    OpenSSL::PKey::RSA.new(
      config['config']['notifications']['webhook']['public_key']
    )
  end

  def repo_slug
    env['HTTP_TRAVIS_REPO_SLUG']
  end
end
