require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'pry'

require_relative 'database_persistence'

configure do
  enable :sessions
  set :session_secret, "secret"
  set :erb, escape_html: true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload "database_persistence.rb"
end

helpers do

end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

get "/" do
  redirect "/all_books_list"
end

get "/all_books_list" do
  @books = @storage.all_books_list
  erb :all_books_list
end

get "/book/:book_id" do
  book_id = params[:book_id].to_i
  @book = @storage.book_data(book_id)
  @book_instance = @storage.book_instance(book_id)
  erb :book
end
