require "ostruct"
require 'active_support/json'
require 'curl'

require 'logger'
module Sanger
  AuthenticationError = Class.new(StandardError)
  ConnectionError     = Class.new(AuthenticationError)
    module Authentication
      class SSO
      
        def initialize(app, settings = {})
          @config = OpenStruct.new
          @config.magic_header_name = settings["magic_header_name"]
          @config.cookie_name = settings["cookie_name"]
          @config.validation_url = settings["validation_url"]
          @config.user_agent = settings["user_agent"]
          @config.error_text = settings["error_text"]
          @config.proxy = settings["proxy"]
          
          @app = app
          @logger = settings["logger"]
        end
        
        def sso_login_from_cookie(cookie_value)
      response = service!(@config.validation_url, 'cookie' => cookie_value)
      logger.debug("Authentication response: #{ response.inspect }")

      result = ActiveSupport::JSON.decode(response) || {}
      logger.debug("Authentication decoded: #{ result.inspect }")


      return result['username'] if result["valid"] == 1 and not result["username"].blank?
      return nil  # In all cases, other than a valid user, return nil
    rescue ConnectionError => exception
      logger.info("Authentication service #{configatron.sanger_auth_service} cookie: #{value} (error response)")
      return nil
    rescue ActiveSupport::JSON.parse_error => exception
      logger.info("Authentication service parse error #{configatron.sanger_auth_service} cookie: #{value} (#{ response })")
      return nil
    rescue Exception => exception
      logger.info("Authentication service down #{configatron.sanger_auth_service} cookie: #{value} res: #{response}")
      return nil
        end
        
        def logger
          @logger ||= Logger.new(STDOUT)
        end
        private
    def service!(url, parameters = {}, &block)
      curl = Curl::Easy.new(url) do |curl|
        curl.useragent =@config.user_agent
        unless @config.proxy.blank?
          curl.proxy_url    = @config.proxy
          curl.proxy_tunnel = true
        end
        yield(curl) if block_given?
      end

      curl.http_post(*parameters.map { |k,v| Curl::PostField.content(k, v) })
      raise ConnectionError, "Server response not OK (#{ curl.response_code })" unless [ 200, 302 ].include?(curl.response_code)
      curl.body_str
    ensure
      curl.close
    end
      end
    end
  end
