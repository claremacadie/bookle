require 'bcrypt'
require 'sinatra'
require 'tilt/erubis'
require 'pry'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, "secret"
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

# Helper methods for views (erb files)
helpers do
  def book_availability(book)
    if book[:borrower_id] 
      "On loan" 
    elsif book[:requester_id]
      "Requested"
    else
      "Available"
    end
  end
end

# Helper methods for routes
def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

def require_signed_out_user
  if user_signed_in?
    session[:message] = "You must be signed out to do that."
    redirect "/"
  end
end

def valid_credentials?(username, password)
  credentials = @storage.load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

# Routes
get "/" do
  erb :home
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out"
  redirect "/"
end

get "/users/signup" do
  require_signed_out_user
  erb :signup
end

post "/users/signup" do
  require_signed_out_user
  
  new_username = params[:new_username]
  new_password = params[:password]
  reenter_password = params[:reenter_password]
  @users = @storage.load_user_credentials
  
  if @users.keys.include?(new_username)
    session[:message] = "That username already exists."
    status 422
    erb :signup
  elsif new_password != reenter_password
    session[:message] = "The passwords do not match."
    status 422
    erb :signup
  else
    @storage.upload_new_user_credentials(new_username, new_password)
    session[:username] = new_username
    session[:message] = "Your account has been created."
    redirect "/"
  end
end

get "/all_books_list" do
  @books = @storage.all_books_list
  erb :all_books_list
end

get "/ownedby_user_books_list" do
  require_signed_in_user
  
  @user_owned_books = @storage.ownedby_user_books_list(session[:username])
  erb :ownedby_user_books_list
end

get "/book/:book_id" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  @book = @storage.book_data(book_id)
  erb :book
end

post "/book/:book_id/returned" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  p book_id
  gets
  @book = @storage.book_data(book_id)
  # @storage.book_returned(book_id)
  session[:message] = "#{@book[:title]} has been returned"
  redirect :ownedby_user_books_list
end

not_found do
  redirect "/"
end