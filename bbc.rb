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

get "/book/edit/:book_instance_id/:book_id" do
  book_instance_id = params[:book_instance_id].to_i
  book_id = params[:book_id].to_i
  @book = @storage.book_data(book_id)
  @book_availability =  if @storage.book_availability(book_instance_id) == 't'
                          "Available"
                        else
                          "On loan"
                        end
  erb :book_edit
end

get "/book/:book_id" do
  book_id = params[:book_id].to_i
  @book = @storage.book_data(book_id)
  @book_instances = @storage.book_instances(book_id)
  erb :book
end