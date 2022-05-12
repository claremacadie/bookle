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
  session.key?(:user_name)
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

def valid_credentials?(user_name, password)
  credentials = @storage.load_user_credentials

  if credentials.key?(user_name)
    bcrypt_password = BCrypt::Password.new(credentials[user_name])
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
  if valid_credentials?(params[:user_name], params[:password])
    session[:user_name] = params[:user_name]
    session[:message] = "Welcome!"
    session[:user_id] = @storage.get_user_id(session[:user_name])
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:user_name)
  session.delete(:user_id)
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
    session[:user_name] = new_username
    session[:user_id] = @storage.get_user_id(new_username)
    session[:message] = "Your account has been created."
    redirect "/"
  end
end

get "/all_books_list" do
  @books = @storage.all_books
  erb :all_books_list
end

get "/users/book_list" do
  require_signed_in_user
  @user_owned_books = @storage.user_owned_books(session[:user_id])
  erb :user_owned_book_list
end

get "/book/:book_id" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  @book = @storage.book_data(book_id)
  erb :book
end

post "/book/:book_id/request" do
  require_signed_in_user
  book_id = params[:book_id].to_i
 
  @storage.book_add_request(book_id, session[:user_id])
  @book = @storage.book_data(book_id)
  session[:message] = "You have requested #{@book[:title]} from #{@book[:owner_name]}"
  redirect :all_books_list
end

post "/book/:book_id/cancel_request" do
  require_signed_in_user
  book_id = params[:book_id].to_i
 
  @storage.book_cancel_request(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "You have cancelled your request for #{@book[:title]} from #{@book[:owner_name]}"
  redirect :all_books_list
end

post "/book/:book_id/loan" do
  require_signed_in_user
  book_id = params[:book_id].to_i
 
  @storage.book_loan(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "#{@book[:title]} has been loaned to #{@book[:borrower_name]}"
  redirect :user_owned_book_list
end

post "/book/:book_id/reject_request" do
  require_signed_in_user
  book_id = params[:book_id].to_i
 
  @book = @storage.book_data(book_id)
  session[:message] = "You have rejected a request for #{@book[:title]} from #{@book[:requester_name]}"
  @storage.book_reject_request(book_id)
  redirect :user_owned_book_list
end

post "/book/:book_id/return" do
  require_signed_in_user
  book_id = params[:book_id].to_i
 
  @storage.book_return(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "#{@book[:title]} has been returned"
  redirect :user_owned_book_list
end

not_found do
  redirect "/"
end