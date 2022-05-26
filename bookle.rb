# frozen_string_literal: true

require 'bcrypt'
require 'sinatra'
require 'tilt/erubis'
require 'pry'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistence.rb'
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
      book[:borrower_id] == session[:user_id] ? 'On loan to you' : "On loan to #{book[:borrower_name]}"
    elsif book[:requester_id]
      book[:requester_id] == session[:user_id] ? 'Requested by you' : "Requested by #{book[:requester_name]}"
    else
      'Available'
    end
  end

  def image_file(title)
    image_files = Dir.glob('public/images/*')
    image_files.map! do |file|
      File.basename(file).split('.')[0]
    end

    format_title = title.downcase.gsub(' ', '_').gsub(/\W/, '')
    format_title if image_files.include?(format_title)
  end

  def total_books(filter_type, books_count)
    case filter_type
    when 'search'
      "There are #{books_count} books meeting your criteria."
    when 'all_books'
      "There are #{books_count} books on Bookle."
    when 'available_to_borrow'
      "There are #{books_count} books available for you to borrow."
    when 'your_books'
      "You have #{books_count} books on Bookle."
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

def require_admin_signed_in
  return if session[:user_name] == 'admin'

  @original_route = request.path_info
  session[:message] = 'You must be an adimistrator to do that.'
  redirect "/users/signin?original_route=#{@original_route}"
  # erb :signin - I think this doesn't work because the rest of the route that invoked this method
  # ends in an erb that overwrites it.
end

def require_signed_in_user
  return if user_signed_in?

  @original_route = request.path_info
  session[:message] = 'You must be signed in to do that.' \
    " Sign in below or <a href='/users/signup?original_route=#{@original_route}'>create a new account</a>"
  redirect "/users/signin?original_route=#{@original_route}"
  # erb :signin - I think this doesn't work because the rest of the route that invoked this method
  # ends in an erb that overwrites it.
end

def require_signed_in_as_book_owner(book_id)
  return if user_is_book_owner?(book_id)

  session[:message] = 'You must be the book owner to do that.'
  redirect '/'
end

def require_signed_out_user
  return unless user_signed_in?

  session[:message] = 'You must be signed out to do that.'
  redirect '/'
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

def signup_input_error(new_username, new_password, reenter_password)
  if new_username == '' && new_password == ''
    'Username and password cannot be blank! Please enter a username and password.'
  elsif new_username == ''
    'Username cannot be blank! Please enter a username.'
  elsif new_username == 'admin'
    "Username cannot be 'admin'! Please choose a different username."
  elsif new_password == ''
    'Password cannot be blank! Please enter a password.'
  elsif @storage.load_user_credentials.keys.include?(new_username)
    'That username already exists.'
  elsif new_password != reenter_password
    'The passwords do not match.'
  end
end

def selected_category_ids(params)
  if params.keys.include?('categories')
    # Convert "[1, 2, 3]" to [1, 2, 3]
    return params['categories'].delete('[', ']').split(', ').map(&:to_i)
  end

  categories = []
  params.each do |k, v|
    categories << v.to_i if k.include?('category_id')
  end
  categories
end

def availability_array(params)
  return params['availabilities'] if params.keys.include?('availabilities')

  availabilities = []
  params.each do |k, v|
    availabilities << k if v == 'availability'
  end
  availabilities.join(',')
end

def heading(filter_type)
  heading_hash = {
    'search' => 'Search Results',
    'all_books' => 'All Books',
    'available_to_borrow' => 'Books Available For You To Borrow',
    'your_books' => 'Your Books'
  }
  heading_hash[filter_type]
end

def blank_field_message(title, author)
  if title == '' && author == ''
    'Title and author cannot be blank! Please enter a title and an author.'
  elsif title == ''
    'Title cannot be blank! Please enter a title.'
  elsif author == ''
    'Author cannot be blank! Please enter an author.'
  end
end

def number_of_books(filter_type)
  method_hash = {
    'search' => @storage.count_filter_books(@title, @author, @categories_selected, @availabilities),
    'all_books' => @storage.count_filter_books(@title, @author, @categories_selected, @availabilities),
    'available_to_borrow' => @storage.count_available_books(session[:user_id]),
    'your_books' => @storage.count_user_books(session[:user_id])
  }
  method_hash[filter_type]
end

def no_books_message(filter_type)
  message_hash = {
    'search' => 'There are no books meeting your search criteria. Try again!',
    'all_books' => 'There are no books on Bookle.',
    'available_to_borrow' => 'There are no books available for you to borrow.',
    'your_books' => "You don't own any books on Bookle"
  }
  message_hash[filter_type]
end

def books_data(filter_type)
  case filter_type
  when 'search'
    @storage.filter_books(@title, @author, @categories_selected, @availabilities, @limit, @offset)
  when 'all_books'
    @storage.filter_books(@title, @author, @categories_selected, @availabilities, @limit, @offset)
  when 'available_to_borrow'
    @storage.available_books(session[:user_id], @limit, @offset)
  when 'your_books'
    @storage.user_owned_books(session[:user_id], @limit, @offset)
  end
end

# Routes
get '/' do
  erb :home
end

get '/users' do
  require_admin_signed_in
  @users = @storage.load_user_credentials
  erb :users
end

get '/users/signin' do
  @original_route = params[:original_route]
  erb :signin
end

post '/users/signin' do
  @original_route = params['original_route']
  if valid_credentials?(params[:user_name], params[:password])
    session[:user_name] = params[:user_name]
    session[:user_id] = @storage.user_id(session[:user_name])
    session[:message] = 'Welcome!'
    redirect(@original_route)
  else
    session[:message] = 'Invalid credentials'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:user_name)
  session.delete(:user_id)
  session[:message] = 'You have been signed out'
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    '/'
  else
    redirect '/'
  end
end

get '/users/signup' do
  require_signed_out_user
  @original_route = params[:original_route]
  erb :signup
end

post '/users/signup' do
  require_signed_out_user
  @original_route = params[:original_route]
  new_username = params[:new_username]
  new_password = params[:password]
  reenter_password = params[:reenter_password]

  if (session[:message] = signup_input_error(new_username, new_password, reenter_password))
    status 422
    erb :signup
  else
    @storage.upload_new_user_credentials(new_username, new_password)
    session[:user_name] = new_username
    session[:user_id] = @storage.user_id(new_username)
    session[:message] = 'Your account has been created.'
    redirect(@original_route)
  end
end

get '/books/filter_form' do
  @categories_list = @storage.categories_list
  erb :books_filter_form
end

get '/books/filter_results/:filter_type/:offset' do
  @filter_type = params[:filter_type]
  require_signed_in_user if @filter_type == 'your_books' || @filter_type == 'available_to_borrow'
  @title = params[:title]
  @author = params[:author]
  @categories_selected = selected_category_ids(params)
  @availabilities = availability_array(params)
  @limit = LIMIT
  @offset = params[:offset].to_i
  @books_count = number_of_books(@filter_type)
  if @books_count.zero?
    session[:message] = no_books_message(@filter_type)
    @filter_type == 'search' ? redirect('/books/filter_form') : redirect('/')
  end
  @books = books_data(@filter_type)
  while @books.empty?
    @offset -= LIMIT
    @books = @storage.user_owned_books(session[:user_id], @limit, @offset)
  end
  @heading = heading(@filter_type)
  @number_of_pages = (@books_count / @limit.to_f).ceil
  erb :books_filter_result
end

get '/book/add_new' do
  require_signed_in_user
  @filter_type = params[:filter_type]
  @offset = params[:offset]
  @categories_list = @storage.categories_list
  erb :add_book
end

post '/book/add_new' do
  require_signed_in_user
  title = params[:title]
  author = params[:author]
  @filter_type = params[:filter_type]
  @offset = params[:offset].to_i
  owner_id = session[:user_id]
  categories_selected = selected_category_ids(params)
  if title == '' || author == ''
    session[:message] = blank_field_message(title, author)
    status 422
    @categories_list = @storage.categories_list
    erb :add_book
  else
    @storage.add_book(title, author, owner_id, categories_selected)
    session[:message] = "#{title} has been added."
    redirect "/books/filter_results/#{@filter_type}/#{@offset}"
  end
end

get '/book/:book_id/edit' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  @filter_type = params[:filter_type]
  @offset = params[:offset]
  @book = @storage.book_data(book_id)
  @categories_list = @storage.categories_list
  @book_category_ids = @storage.categories(book_id)
  erb :edit_book
end

post '/book/:book_id/edit' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  title = params[:title]
  author = params[:author]
  @filter_type = params[:filter_type]
  @offset = params[:offset].to_i
  categories_selected = selected_category_ids(params)
  if title == '' || author == ''
    session[:message] = blank_field_message(title, author)
    status 422
    @book = @storage.book_data(book_id)
    @categories_list = @storage.categories_list
    @book_category_ids = @storage.categories(book_id)
    erb :edit_book
  else
    @storage.update_book_data(book_id, title, author, categories_selected)
    session[:message] = "Book details have been updated for #{title}."
    redirect "/books/filter_results/#{@filter_type}/#{@offset}"
  end
end

post '/book/:book_id/delete' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  require_signed_in_as_book_owner(book_id)
  filter_type = params[:filter_type]
  offset = params[:offset]
  @book = @storage.book_data(book_id)
  @storage.delete_book(book_id, session[:user_id])
  session[:message] = "#{@book[:title]} has been deleted."
  if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
    "/books/filter_results/#{filter_type}/#{offset}"
  else
    redirect "/books/filter_results/#{filter_type}/#{offset}"
  end
end

post '/book/:book_id/request' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  filter_type = params[:filter_type]
  offset = params[:offset]
  @storage.book_add_request(book_id, session[:user_id])
  @book = @storage.book_data(book_id)
  session[:message] = "You have requested #{@book[:title]} from #{@book[:owner_name]}"
  redirect "/books/filter_results/#{filter_type}/#{offset}"
end

post '/book/:book_id/cancel_request' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  filter_type = params[:filter_type]
  offset = params[:offset]
  @storage.book_cancel_request(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "You have cancelled your request for #{@book[:title]} from #{@book[:owner_name]}"
  redirect "/books/filter_results/#{filter_type}/#{offset}"
end

post '/book/:book_id/loan' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  filter_type = params[:filter_type]
  offset = params[:offset]
  @storage.book_loan(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "#{@book[:title]} has been loaned to #{@book[:borrower_name]}"
  redirect "/books/filter_results/#{filter_type}/#{offset}"
end

post '/book/:book_id/reject_request' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  filter_type = params[:filter_type]
  offset = params[:offset]
  @book = @storage.book_data(book_id)
  session[:message] = "You have rejected a request for #{@book[:title]} from #{@book[:requester_name]}"
  @storage.book_reject_request(book_id)
  redirect "/books/filter_results/#{filter_type}/#{offset}"
end

post '/book/:book_id/return' do
  require_signed_in_user
  book_id = params[:book_id].to_i
  filter_type = params[:filter_type]
  offset = params[:offset]
  @storage.book_return(book_id)
  @book = @storage.book_data(book_id)
  session[:message] = "#{@book[:title]} has been returned"
  redirect "/books/filter_results/#{filter_type}/#{offset}"
end

not_found do
  redirect '/'
end
