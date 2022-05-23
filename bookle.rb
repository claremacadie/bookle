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

def heading(filter_type)
  case filter_type
  when "search"
    "Search Results"
  when 'all_books'
    'All Books'
  when 'available_to_borrow'
    'Books Available For You To Borrow'
  when 'your_books'
    'Your Books'
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
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
	  "/"
	else
	  redirect "/"
  end
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

get "/books/filter_form" do
  require_signed_in_user
  @categories = @storage.categories_list
  erb :books_filter_form
end
  
get "/books/filter_results/:filter_type/:offset" do
  require_signed_in_user
  @filter_type = params[:filter_type]
  @title = params[:title]
  @author = params[:author]
  @categories = selected_category_ids(params)
  @availabilities = availability_array(params)
  @limit = LIMIT
  @offset = params[:offset].to_i
  case 
  when @filter_type == 'search'
    books_count = @storage.count_filter_books(@title, @author, @categories, @availabilities)
    if books_count == 0
      session[:message] = "There are no books meeting your search criteria. Try again!"
      redirect "/books/filter_form"
    end
    @books = @storage.filter_books(@title, @author, @categories, @availabilities, @limit, @offset)
  when @filter_type == 'all_books'
    books_count = @storage.count_filter_books(@title, @author, @categories, @availabilities)
    if books_count == 0
      session[:message] = "There are no books on Bookle."
      redirect "/"
    end
    @books = @storage.filter_books(@title, @author, @categories, @availabilities, @limit, @offset)
  when @filter_type == 'available_to_borrow'
    books_count = @storage.count_available_books(session[:user_id])
    if books_count == 0
      session[:message] = "There are no books available for you to borrow."
      redirect "/"
    end
    @books = @storage.available_books(session[:user_id], @limit, @offset)
  when @filter_type == 'your_books'
    books_count = @storage.count_user_books(session[:user_id])
    if books_count == 0
      session[:message] = "You don't own any books on Bookle."
      redirect "/"
    end
    @books = @storage.user_owned_books(session[:user_id], @limit, @offset)
  end
  @heading = heading(@filter_type)
  @number_of_pages = (books_count/ @limit.to_f).ceil
  erb :books_filter_result
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
  redirect "/books/filter_results/your_books/0"
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
  redirect "/books/filter_results/your_books/0"
end

post "/book/:book_id/delete" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  @book = @storage.book_data(book_id)
  @storage.delete_book(book_id, session[:user_id])
  session[:message] = "#{@book[:title]} has been deleted."
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/books/filter_results/your_books/0"
  else
    redirect "/books/filter_results/your_books/0"
  end
end

post "/book/:book_id/request" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  
  @storage.book_add_request(book_id, session[:user_id])
  @book = @storage.book_data(book_id)
  session[:message] = "You have requested #{@book[:title]} from #{@book[:owner_name]}"
  redirect "/books/filter_results/all_books/0"
end

post "/book/:book_id/cancel_request" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  
  @storage.book_cancel_request(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "You have cancelled your request for #{@book[:title]} from #{@book[:owner_name]}"
  redirect "/books/filter_results/all_books/0"
end

post "/book/:book_id/loan" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  
  @storage.book_loan(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "#{@book[:title]} has been loaned to #{@book[:borrower_name]}"
  redirect "/books/filter_results/your_books/0"
end

post "/book/:book_id/reject_request" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  
  @book = @storage.book_data(book_id)
  session[:message] = "You have rejected a request for #{@book[:title]} from #{@book[:requester_name]}"
  @storage.book_reject_request(book_id)
  redirect "/books/filter_results/your_books/0"
end

post "/book/:book_id/return" do
  require_signed_in_user
  book_id = params[:book_id].to_i
  
  @storage.book_return(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "#{@book[:title]} has been returned"
  redirect "/books/filter_results/your_books/0"
end

not_found do
  redirect "/"
end
