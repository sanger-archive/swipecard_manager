require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'
load 'sanger_authentication.rb'
require 'configatron'
require 'haml'
#require 'sequencescape-api'
require 'sequencescape'


APP_ROOT = File.dirname(File.expand_path(__FILE__))
Environment = ENV["RAILS_ENV"] || "development"
configatron.configure_from_yaml( File.join(APP_ROOT,'config/config.yml'), :hash => Environment)
raise "Environment '#{Environment} not found if configuration file." if configatron.nil?

def self.init()
  auth = configatron.authentication_service
  raise RuntimeError, "Authentication service not configured" unless auth
  params = {"cookie_name" => auth.cookie_name,
   "validation_url" => auth.validation_url,
   "user_agent" => "Swipecard Manager",
   "proxy" => configatron.proxy
  }
  @@sanger_authentication = Sanger::Authentication::SSO.new('swipecard manager',params)
end

init



def find_login_from_cookies(cookies)
  halt 500, "server not configured" unless @@sanger_authentication
  halt 500, "cookie name not configured" unless token_name=configatron.authentication_service.cookie_name
  @sso_token = cookies[token_name]
  #halt 301, "please log on " unless token
  login = @@sanger_authentication.sso_login_from_cookie(@sso_token)
  if @sso_token && !login
    halt 500, "Authentication service error"
  else
    login
  end
end

def api
  @api ||= begin
             sequencescape_url = configatron.sequencescape.url
             halt 500, "Serves missconfigured. sequencescape.url required" unless sequencescape_url
             Sequencescape::Api.new(:url => sequencescape_url, :cookie => @sso_token, :authorisation => configatron.sequencescape.authorisation)
           end
end

def find_user_by_login(login)
  searcher = api.search.find(configatron.sequencescape.find_user_by_login_uuid || halt("500", "Server missconfigured, please a sequencescape_uuid"))
  searcher.first(:login => login)
end

def update_code(name, code)
  user = find_user_by_login(name)
  user.swipecard_code=code
  user.save!
end

# find user from cookie
before do 
  @user = find_login_from_cookies(request.cookies)
end

def check_user_logged_in
    redirect to('/login') unless @user
end
# main page
get '/' do
  haml :index
end

get '/code_input' do
  check_user_logged_in
  haml :code_input
end

post '/update' do
  check_user_logged_in
  user = @user 
  code = params["code"]

  @success = update_code(user, code)
  haml :update
end

get '/login' do
  redirect to '/' if @user
  haml :login
end
