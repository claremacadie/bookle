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

# Define constants
LIMIT = 3

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
      if book[:borrower_id] == session[:user_id]
        "On loan to you"
      else
        "On loan to #{book[:borrower_name]}"
      end
    elsif book[:requester_id]
      if book[:requester_id] == session[:user_id]
        "Requested by you"
      else
        "Requested by #{book[:requester_name]}"
      end
    else
      "Available"
    end
  end
end

# Helper methods for routes
def user_signed_in?
  session.key?(:user_name)
end

def user_is_book_owner?(book_id)
  book_owner_id = @storage.owner_id(book_id)
  session[:user_id] == book_owner_id
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

def require_signed_in_as_book_owner(book_id)
  unless user_is_book_owner?(book_id)
    session[:message] = "You must be the book owner to do that."
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

def selected_category_ids(params)
  if params.keys.include?('categories')
    # Convert "[1, 2, 3]" to [1, 2, 3]
    return params['categories'].delete('[' ']').split(', ').map(&:to_i)
  end
  categories = []
  params.each do |k, v|
    if k.include?("category_id")
      categories << v.to_i
    end
  end
  categories
end

def availability_array(params)
  if params.keys.include?('availabilities')
    return params['availabilities']
  end
  availabilities = []
  params.each do |k, v|
    if v == "availability"
      availabilities << k
    end
  end
  availabilities.join(', ')
end

def format_heading(string)
  word_array = string.split('_')
  word_array.map! {|word| word.capitalize}.join(' ')
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
    session[:user_id] = @storage.user_id(session[:user_name])
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
    session[:user_id] = @storage.user_id(new_username)
    session[:message] = "Your account has been created."
    redirect "/"
  end
end

get "/paginated_books_list/:list_type/:offset" do
  require_signed_in_user
  @list_type = params[:list_type]
  @heading = format_heading(@list_type)
  @limit = LIMIT
  @offset = params[:offset].to_i
  case @list_type
  when "all_books"
    books_count = @storage.count_all_books
    @books = @storage.all_books_limit_offset(@limit, @offset)
  when "available_to_borrow"
    books_count = @storage.count_available_books(session[:user_id])
    @books = @storage.available_books(session[:user_id])
  when "your_books"
    books_count = @storage.count_user_books(session[:user_id])
    @books = @storage.user_owned_books(session[:user_id])
  end
  @number_of_pages = (books_count/ @limit.to_f).ceil
  erb :paginated_books_list
end
  
get "/books/filter_form" do
  require_signed_in_user
  @categories = @storage.categories_list
  erb :books_filter_form
end
  
get "/books/filter_results/:offset" do
  require_signed_in_user
  @title = params[:title]
  @author = params[:author]
  @categories = selected_category_ids(params)
  @availabilities = availability_array(params)
  books_count = @storage.count_filter_books(@title, @author, @categories, @availabilities)
  if books_count == 0
    session[:message] = "There are no books meeting your search criteria. Try again!"
    redirect "/books/filter_form"
  end
  @heading = "Search results"
  @limit = LIMIT
  @offset = params[:offset].to_i
  @number_of_pages = (books_count/ @limit.to_f).ceil
  @books = @storage.filter_books(@title, @author, @categories, @availabilities, @limit, @offset)
  erb :books_filter_result
end

get "/users/book_list" do
  require_signed_in_user
  @user_owned_books = @storage.user_owned_books(session[:user_id])
  erb :user_owned_book_list
end

get "/book/add_new" do
  require_signed_in_user
  @categories = @storage.categories_list
  erb :add_book
end

post "/book/add_new" do
  require_signed_in_user
  title = params[:title]
  author = params[:author]
  owner_id = session[:user_id]
  categories = selected_category_ids(params)
  @storage.add_book(title, author, owner_id, categories)
  session[:message] = "#{title} has been added."
  redirect "/users/book_list"
end

get "/book/:book_id/edit" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  @book = @storage.book_data(book_id)
  @categories = @storage.categories_list
  @book_category_ids = @storage.categories(book_id)
  erb :edit_book
end

post "/book/:book_id/edit" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  title = params[:title]
  author = params[:author]
  categories = selected_category_ids(params)
  @storage.update_book_data(book_id, title, author, categories)
  session[:message] = "Book details have been updated for #{title}."
  redirect "/users/book_list"
end

get "/book/:book_id/delete" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  @book = @storage.book_data(book_id)
  erb :delete_book
end

post "/book/:book_id/delete" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  @book = @storage.book_data(book_id)
  @storage.delete_book(book_id, session[:user_id])
  session[:message] = "#{@book[:title]} has been deleted."
  redirect "/users/book_list"
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

get "/book/:book_id" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  @book = @storage.book_data(book_id)
  erb :book
end

not_found do
  redirect "/"
end
