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
   @@sanger_authentication.sso_login_from_cookie(token)
end

# find user from cookie
before do 
  @user = find_login_from_cookies(request.cookies)
end
# main page
get '/' do
  haml :index
end

get '/todo' do
  case @user
  when nil
    redirect to('/login')
  else
    haml :code_input
  end
end

get '/login' do
  haml :login
end
__END__
@@ layout
%html
  %table.bar#header
    %tr
      %td
        %h1 Swipecard Manager
      %td
        - if @user
          logged as #{ user }
        - else
          %i please login to the sanger
          %a{:href => configatron.login_service.url }website
  #main
    = yield

@@ index
%a{:href => url('/update') } Update or enter a new swipecard code

@@ login
please login 

@@ code_input
Hello, user #{@user}. How are you

