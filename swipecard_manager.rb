require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'
load 'sanger_authentication.rb'
require 'configatron'
require 'haml'


APP_ROOT = File.dirname(File.expand_path(__FILE__))
configatron.configure_from_yaml( File.join(APP_ROOT,'config/config.yml'))

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
  token = cookies[token_name]
  #halt 301, "please log on " unless token
  login = @@sanger_authentication.sso_login_from_cookie(token)
  if token && !login
    halt 500, "Authentication service error"
  else
    login
  end
end

# find user from cookie
before do 
  @user = find_login_from_cookies(request.cookies)
end
# main page
get '/' do
  haml :index
end

get '/code_input' do
  case @user
  when nil
    redirect to('/login')
  else
    haml :update
  end
end

post '/update' do
end

get '/login' do
  redirect to '/' if @user
  haml :login
end
