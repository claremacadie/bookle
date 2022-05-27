ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require 'simplecov'
SimpleCov.start

require_relative "../bookle"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    sql = File.read('test/data_test.sql')
    @db_test = PG.connect(dbname: "bookle_test").exec(sql)
  end

  def teardown
  
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user_name: "admin", user_id: 1 } }
  end

  def test_homepage_signed_in
    get "/", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to Bookle."
    assert_includes last_response.body, "Home"
    assert_includes last_response.body, "View books"
    assert_includes last_response.body, "Administer account"
    assert_includes last_response.body, "Signed in as Clare MacAdie"
    assert_includes last_response.body, %q(<button type="submit">Sign Out</button>)
    refute_includes last_response.body, "Administer categories"
    refute_includes last_response.body, "Administer users"
    refute_includes last_response.body, "Sign In"
    refute_includes last_response.body, "Create Account"
  end
  
  def test_homepage_signed_in_as_admin
    get "/", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to Bookle."
    assert_includes last_response.body, "Home"
    assert_includes last_response.body, "View books"
    assert_includes last_response.body, "Administer account"
    assert_includes last_response.body, "Signed in as admin"
    assert_includes last_response.body, %q(<button type="submit">Sign Out</button>)
    assert_includes last_response.body, "Administer categories"
    assert_includes last_response.body, "Administer users"
    refute_includes last_response.body, "Sign In"
    refute_includes last_response.body, "Create Account"
  end
  
  def test_homepage_signed_out
    get "/"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to Bookle."
    assert_includes last_response.body, "Home"
    assert_includes last_response.body, "Sign In"
    assert_includes last_response.body, "Create Account"
    assert_includes last_response.body, "View books"
    refute_includes last_response.body, "Administer account"
    refute_includes last_response.body, "Administer categories"
    refute_includes last_response.body, "Administer users"
    refute_includes last_response.body, "Signed in as"
    refute_includes last_response.body, %q(<button type="submit">Sign Out</button>)
  end

  def test_appropriate_hyperlinks_for_book_titles
    get "/books/filter_results/all_books/3", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, '<a href="/images/halfblood_prince.jpeg" target="blank">'
    assert_includes last_response.body, "How to Be a Pirate"
    refute_includes last_response.body, '<a href="/images/how_to_be_a_pirate.jpeg" target="blank">'
  end

  def no_books_on_bookle_message
    @db_test.exec("DELETE FROM books;")

    get "/books/filter_result/all_books/0"
    assert_equal 302, last_response.status
    assert_equal "There are no books on Bookle.", session[:message]
  end

  def test_all_books_list_signed_in
    get "/books/filter_results/all_books/0", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "List available books for you to borrow"
    assert_includes last_response.body, "List your books"
    assert_includes last_response.body, "Search books"
    assert_includes last_response.body, "List all books"
    assert_includes last_response.body, "Add book"
    assert_includes last_response.body, "There are 18 books on Bookle."
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Fantasy, Magic"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_all_books_list_signed_in
    get "/books/filter_results/all_books/3", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "List available books for you to borrow"
    assert_includes last_response.body, "List your books"
    assert_includes last_response.body, "Search books"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Half-Blood Prince"
    assert_includes last_response.body, "How to Be a Pirate"
    assert_includes last_response.body, "How to Cheat a Dragon's Curse"
    refute_includes last_response.body, "Fantasy, Magic"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
  end
  
  def test_all_books_list_signed_out
    get "/books/filter_results/all_books/0"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "List available books for you to borrow"
    assert_includes last_response.body, "List your books"
    assert_includes last_response.body, "Search books"
    assert_includes last_response.body, "List all books"
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "Add book"
  end
  
  def no_books_to_borrow_message
    @db_test.exec("DELETE FROM books;")

    get "/books/filter_result/available_books/0"
    assert_equal 302, last_response.status
    assert_equal "There are no books available for you to borrow.", session[:message]
  end
  
  def test_available_books_list_signed_in
    get "/books/filter_results/available_to_borrow/0", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "There are 8 books available for you to borrow."
    assert_includes last_response.body, "How to Be a Pirate"
    assert_includes last_response.body, "How to Cheat a Dragon's Curse"
    assert_includes last_response.body, "How to Speak Dragonese"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "How to Train a Dragon"
  end
  
  def test_available_books_list_signed_in_invalid_offset
    get "/books/filter_results/available_to_borrow/9", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new book"
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Page 3"
  end
  
  def test_available_books_list_signed_out
    get "/books/filter_results/available_to_borrow/0"
    assert_equal 302, last_response.status
    assert_includes session[:message], "You must be signed in to do that. Sign in below or"

    get last_response["Location"]
    assert_includes last_response.body, "Home"
  end
  
  def test_view_your_books_signed_in
    get "/books/filter_results/your_books/0", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new book"
    assert_includes last_response.body, "You have 7 books on Bookle."
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Fantasy, Magic"
    assert_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>) 
  end
  
  def test_your_books_signed_in_invalid_offset
    get "/books/filter_results/your_books/9", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new book"
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Page 3"
  end
  
  def test_view_your_books_signed_in_invalid_offset
    get "/books/filter_results/your_books/9", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new book"
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Page 3"
  end
  
  def test_view_your_books_signed_out
    get "/books/filter_results/your_books/0"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
  
  def test_view_your_books_signed_out
    get "/books/filter_results/your_books/0"

    assert_equal 302, last_response.status
    assert_includes session[:message], "You must be signed in to do that. Sign in below or"
  end
  
  def test_filter_books_form_signed_in
    get "/books/filter_form", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value="")
    assert_includes last_response.body, %q(<input type="checkbox")
    assert_includes last_response.body, %q(<button type="submit">See Results</button>)
  end
  
  def test_filter_books_form_signed_in_no_books_on_bookle
    get "/books/filter_results/your_books/0", {}, {"rack.session" => { user_name: "Beth Bloom" , user_id: 4 } }
    
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You don't own any books on Bookle", session[:message]
  end

  def test_filter_books_signed_in_invalid_offset
    get "/books/filter_results/search/9", {title: '', author: 'k'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new book"
    assert_includes last_response.body, "There are 7 books meeting your criteria."
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Page 3"
  end

  def test_filtered_by_title_books_list_signed_in_pagination_test
    get "/books/filter_results/search/0", {title: 'k', author: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Page"
  end
  
  def test_filtered_by_author_books_list_signed_in_pagination_test
    get "/books/filter_results/search/0", {title: '', author: 'k'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Page 3"
    refute_includes last_response.body, "Page 4"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end
  
  def test_filtered_by_author_books_list_signed_in_pagination_test
    get "/books/filter_results/search/3", {title: '', author: 'k'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Page 1"
    assert_includes last_response.body, "Page 2"
    assert_includes last_response.body, "Page 3"
    assert_includes last_response.body, "Half-Blood Prince"
    assert_includes last_response.body, "Order of the Phoenix"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Deathly Hallows"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_title_and_author_books_list_signed_in
    get "/books/filter_results/search/0", {title: 'a', author: 'a'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "How to Be a Pirate"
    assert_includes last_response.body, "How to Cheat a Dragon's Curse"
    assert_includes last_response.body, "How to Speak Dragonese"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end

  def test_filtered_by_category_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', category_id_1: '1'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Philosopher's Stone"
    assert_includes last_response.body, "Fantasy, Magic"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_title_and_category_books_list_signed_in
    get "/books/filter_results/search/0", {title: 'k', author: '', category_id_1: '1'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_author_and_category_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: 'k', category_id_1: '1'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_availability_is_available_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: 'availability', requested: '', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Half-Blood Prince"
    assert_includes last_response.body, "How to Be a Pirate"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_availability_is_requested_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: '', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: '', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_available_and_requested_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: 'availability', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_availability_is_available_and_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: 'availability', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Half-Blood Prince"
    assert_includes last_response.body, "How to Be a Pirate"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
  end
  
  def test_filtered_by_availability_is_requested_and_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: '', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Prince Caspian"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_available_requested_and_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: '', available: 'availability', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
  end

  def test_filtered_by_title_and_availability_is_available_books_list_signed_in
    get "/books/filter_results/search/0", {title: 't', author: '', available: 'availability', requested: '', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "How to Be a Pirate"
    assert_includes last_response.body, "How to Cheat a Dragon's Curse"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_author_and_availability_is_requested_books_list_signed_in
    get "/books/filter_results/search/0", {title: '', author: 'k', available: '', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_title_and_availability_is_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: 'k', author: '', available: '', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_title_and_availability_is_available_and_requested_books_list_signed_in
    get "/books/filter_results/search/0", {title: 't', author: '', available: 'availability', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_title_and_availability_is_available_and_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: 't', author: '', available: 'availability', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "How to Be a Pirate"
    assert_includes last_response.body, "How to Cheat a Dragon's Curse"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
  end
  
  def test_filtered_by_title_and_availability_is_requested_and_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: 't', author: '', available: '', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "The Silver Chair"
    refute_includes last_response.body, "Prince Caspian"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_available_requested_and_onloan_books_list_signed_in
    get "/books/filter_results/search/0", {title: 't', author: '', available: 'availability', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Deathly Hallows"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_title_author_category_and_availability_list_signed_in
    get "/books/filter_results/search/0", {title: 'o', author: 'o', category_id_1: '1', available: 'availability' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_books_no_book_found_list_signed_in
    get "/books/filter_results/search/0", {title: 'q', author: '' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "There are no books meeting your search criteria. Try again!", session[:message]
  end
  
  def test_filtered_books_list_signed_out
    get "/books/filter_form"
   
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value="")
    assert_includes last_response.body, %q(<input type="checkbox")
    assert_includes last_response.body, %q(<button type="submit">See Results</button>)
  end
  
  def test_view_available_book_signed_in_as_book_owner
    get "/books/filter_results/search/0", {title: 'Philosopher', author: '' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Philosopher's Stone"
    assert_includes last_response.body, "Available"
    assert_includes last_response.body, "Edit book"
    assert_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
  
  def test_view_available_book_signedin_as_not_book_owner
    get "/books/filter_results/search/0", {title: 'Philosopher', author: '' }, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Philosopher's Stone"
    assert_includes last_response.body, "Available"
    assert_includes last_response.body, %q(<button>Request book</button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end

  def test_view_requested_book_signed_in_as_book_owner
    get "/books/filter_results/search/0", {title: 'Chamber', author: '' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested by Alice Allbright"
    assert_includes last_response.body, %q(<button>Loan book to Alice Allbright</button>)
    assert_includes last_response.body, %q(<button>Reject request from Alice Allbright</button>)
    assert_includes last_response.body, "Edit book details"
    assert_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
  
  def test_view_requested_book_signed_in_as_book_requester
    get "/books/filter_results/search/0", {title: 'Chamber', author: '' }, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested by you"
    assert_includes last_response.body, %q(<button>Cancel request</button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
  
  def test_view_requested_book_signed_in_as_not_book_owner_or_requester
    get "/books/filter_results/search/0", {title: 'Chamber', author: '' }, {"rack.session" => { user_name: "Beth Broom", user_id: 4 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested by Alice Allbright"
    refute_includes last_response.body, %q(<button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
  
  def test_view_onloan_book_signed_in_as_book_owner
    get "/books/filter_results/search/0", {title: 'Prisoner', author: '' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan to Alice Allbright"
    assert_includes last_response.body, %q(<button>Book returned</button>)
    assert_includes last_response.body, "Edit book details"
    assert_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
  
  def test_view_onloan_book_signed_in_as_book_borrower
    get "/books/filter_results/search/0", {title: 'Prisoner', author: '' }, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan to you"
    refute_includes last_response.body, %q(<button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
  
  def test_view_onloan_book_signed_in_not_as_book_owner_or_borrower
    get "/books/filter_results/search/0", {title: 'Prisoner', author: '' }, {"rack.session" => { user_name: "Beth Broom", user_id: 4 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan to Alice Allbright"
    refute_includes last_response.body, %q(<button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, %q(<button type="submit" class="delete">Delete book</button>)
  end
   
  def test_request_book
    post "/book/1/request", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have requested Philosopher's Stone from Clare MacAdie", session[:message]
    
    get "/books/filter_results/search/0", {title: 'Philosopher', author: '' }, {"rack.session" => { user_name: "Alice Allbright" } }
    assert_includes last_response.body, "Requested by you"
  end

  def test_cancel_request_book
    post "/book/2/cancel_request", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have cancelled your request for Chamber of Secrets from Clare MacAdie", session[:message]
    
    get "/books/filter_results/search/0", {title: 'Chamber', author: '' }, {"rack.session" => { user_name: "Beth Broom", user_id: 4 } }
    assert_includes last_response.body, "Available"
  end
   
  def test_loan_book
    post "/book/2/loan", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "Chamber of Secrets has been loaned to Alice Allbright", session[:message]
    
    get "/books/filter_results/search/0", {title: 'Chamber', author: '' }, {"rack.session" => { user_name: "Beth Broom", user_id: 4 } }
    assert_includes last_response.body, "On loan to Alice Allbright"
  end
   
  def test_reject_request_book
    post "/book/2/reject_request", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have rejected a request for Chamber of Secrets from Alice Allbright", session[:message]
    
    get "/books/filter_results/search/0", {title: 'Chamber', author: '' }, {"rack.session" => { user_name: "Beth Broom", user_id: 4 } }
    assert_includes last_response.body, "Available"
  end

  def test_return_book
    post "/book/3/return", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "Prisoner of Azkaban has been returned", session[:message]
    
    get "/books/filter_results/search/0", {title: 'Prisoner', author: '' }, {"rack.session" => { user_name: "Beth Broom", user_id: 4 } }
    assert_includes last_response.body, "Available"
  end

  def add_book_not_signedin
    get "/book/add_new"
    
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
  
  def test_add_book_form_signedin
    get "/book/add_new", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value=)
    assert_includes last_response.body, %q(<button type="submit">Add new book</button>)
  end

  def test_add_new_book
    post "/book/add_new", { title: "A new title", author: "A new author", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "A new title has been added.", session[:message]
    
    get "/books/filter_results/search/0", {title: 'A new', author: '' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "A new title"
    assert_includes last_response.body, "A new author"
  end
  
  def test_add_new_book_blank_title
    post "/book/add_new", { title: ''}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Title cannot be blank! Please enter a title."
  end
  
  def test_add_new_book_blank_author
    post "/book/add_new", { title: 'A new title', author: ''}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Author cannot be blank! Please enter an author."
  end
  
  def test_add_new_book_blank_title_and_author
    post "/book/add_new", { title: '', author: ''}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Title and author cannot be blank! Please enter a title and an author."
  end

  def delete_book_not_signedin
    post "/book/7/delete"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def delete_book_not_signedin_not_as_book_owner
    post "/book/7/delete", { book_id: "7" }, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    assert_equal 302, last_response.status
    assert_equal "You must be the book owner to do that.", session[:message]
  end

  def test_delete_book
    post "/book/7/delete", { book_id: "7" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "Deathly Hallows has been deleted.", session[:message]
    
    get last_response["Location"]
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    
    get "/books/filter_results/your_books/0"
    # Can't use the book's name as this is in the flash message.
    refute_includes last_response.body, "/book/7"
  end

  def test_edit_book_signedin_as_book_owner
    get "/book/1/edit", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="Philosopher's Stone")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value="JK Rowling")
    assert_includes last_response.body, %q(<button type="submit">Submit</button>)
  end

  def test_edit_book_signedin_as_not_book_owner
    get "/book/1/edit", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 3 } }
    assert_equal 302, last_response.status
    assert_equal "You must be the book owner to do that.", session[:message]
  end

  def test_edit_book_not_signedin
    get "/book/1/edit"
    assert_equal 302, last_response.status
    assert_includes session[:message], "You must be signed in to do that. Sign in below or"
  end
  
  def test_change_book_details
    post "/book/1/edit", { title: "A new title", author: "A new author", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "Book details have been updated for A new title.", session[:message]
    
    get "/books/filter_results/search/0", {title: 'A new', author: '' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 2 } }
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "A new title"
    assert_includes last_response.body, "A new author"
  end
  
  def test_change_book_details_blank_title
    post "/book/1/edit", { title: "", author: "A new author", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Title cannot be blank! Please enter a title."
  end
  
  def test_change_book_details_blank_author
    post "/book/1/edit", { title: "A new title", author: "", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Author cannot be blank! Please enter an author."
  end
  
  def test_change_book_details_blank_title_and_author
    post "/book/1/edit", { title: "", author: "", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Title and author cannot be blank! Please enter a title and an author."
  end
  
  def test_admin_users_page
    get "/users", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Administer users"
  end
  
  def test_users_page_not_admin
    get "/users", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "Administer users"
  end
  
  def test_users_page_signed_out
    get "/users"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "Administer users"
  end
  
  def test_reset_password_admin
    post "/users/reset_password", {user_name: "Clare MacAdie"}, admin_session
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "The password has been reset to 'bookle' for Clare MacAdie.", session[:message]
    
    post "/users/signin", {user_name: "Clare MacAdie", password: "bookle"}, {}
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "Clare MacAdie", session[:user_name]
  end
  
  def test_reset_password_not_admin
    post "/users/reset_password", {user_name: "Beth Broom"}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "The password has been reset to 'bookle' for Clare MacAdie."
    
    post "/users/signin", {user_name: "Clare MacAdie", password: "bookle"}, {}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
  end
  
  def test_reset_password_signed_out
    post "/users/reset_password", {user_name: "Beth Broom"}
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "The password has been reset to 'bookle' for Clare MacAdie."
    
    post "/users/signin", {user_name: "Clare MacAdie", password: "bookle"}, {}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
  end
  
  def test_signin_form
    get "/users/signin"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_signin
    post "/users/signin", {user_name: "admin", password: "a"}, {}
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:user_name]
    
    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end
  
  def test_signin_with_bad_credentials
    post "/users/signin", {user_name: "guest", password: "shhhh"}, {}
    assert_equal 422, last_response.status
    assert_nil session[:user_name]
    assert_includes last_response.body, "Invalid credentials"
  end
  
  def test_signout
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in as admin"
    
    post "/users/signout"
    assert_equal "You have been signed out", session[:message]
    
    get last_response["Location"]
    assert_nil session[:user_name]
    assert_includes last_response.body, "Sign In"
  end
  
  def test_view_signup_form_signed_out
    get "/users/signup"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Reenter password"
  end
  
  def test_view_signup_form_signed_in
    get "/users/signup", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "You must be signed out to do that.", session[:message]
  end
  
  def test_signup_signed_out
    post "/users/signup", {new_username: "joe", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    assert_equal 302, last_response.status
    assert_equal "Your account has been created.", session[:message]
    
    get "/"
    assert_includes last_response.body, "Signed in as joe."
  end
  
  def test_signup_signed_in
    post "/users/signup", {new_username: "joe", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}, admin_session
    assert_equal 302, last_response.status
    assert_equal "You must be signed out to do that.", session[:message]
  end
  
  def test_signup_existing_username
    post "/users/signup", {new_username: "Clare MacAdie", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "That username already exists."
  end
  
  def test_signup_blank_username
    post "/users/signup", {new_username: "", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username cannot be blank! Please enter a username."
  end
  
  def test_signup_admin_username
    post "/users/signup", {new_username: "admin", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username cannot be 'admin'! Please choose a different username."
  end
  
  def test_signup_blank_password
    post "/users/signup", {new_username: "joanna", password: "", reenter_password: ""}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Password cannot be blank! Please enter a password."
  end
  
  def test_signup_blank_username_and_password
    post "/users/signup", {new_username: "", password: "", reenter_password: ""}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Username and password cannot be blank! Please enter a username and password."
  end
  
  def test_signup_mismatched_passwords
    post "/users/signup", {new_username: "joanna", password: "dfghiewo34334", reenter_password: "mismatched"}
    assert_equal 422, last_response.status
    assert_includes last_response.body, "The passwords do not match."
  end
  
  def test_view_administer_account_form_signed_out
    get "/user"
    assert_equal 302, last_response.status
    assert_includes session[:message], "You must be signed in to do that. Sign in below or"
  end
  
  def test_view_administer_account_form_signed_in
    get "/user", {}, admin_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Enter new username"
    assert_includes last_response.body, "Enter current password"
    assert_includes last_response.body, "Enter new password"
    assert_includes last_response.body, "Reenter new password"
  end
  
  def test_change_username
    post "/user/edit_login", {new_username: "joe", current_password: "a", new_password: "", reenter_password: ""}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "joe", session[:user_name]
    assert_equal "Your username has been updated.", session[:message]
    
    get "/"
    assert_includes last_response.body, "Signed in as joe."
  end
  
  def test_change_username_to_blank
    post "/user/edit_login", {new_username: "", current_password: "a", new_password: "", reenter_password: ""}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_equal "Clare MacAdie", session[:user_name]
    assert_includes last_response.body, "New username cannot be blank! Please enter a username."
  end
  
  def test_change_username_to_admin
    post "/user/edit_login", {new_username: "admin", current_password: "a", new_password: "", reenter_password: ""}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_equal "Clare MacAdie", session[:user_name]
    assert_includes last_response.body, "New username cannot be 'admin'! Please choose a different username."
  end
  
  def test_change_username_to_existing_username
    post "/user/edit_login", {new_username: "Alice Allbright", current_password: "a", new_password: "", reenter_password: ""}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_equal "Clare MacAdie", session[:user_name]
    assert_includes last_response.body, "That username already exists. Please choose a different username."
  end
  
  def test_change_password
    post "/user/edit_login", {new_username: "Clare MacAdie", current_password: "a", new_password: "b", reenter_password: "b"}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "Clare MacAdie", session[:user_name]
    assert_equal "Your password has been updated.", session[:message]
    
    post "/users/signin", {user_name: "Clare MacAdie", password: "b"}, {}
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "Clare MacAdie", session[:user_name]
  end
   
  def test_change_password_mismatched
    post "/user/edit_login", {new_username: "Clare MacAdie", current_password: "a", new_password: "b", reenter_password: "c"}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_equal "Clare MacAdie", session[:user_name]
    assert_includes last_response.body, "The passwords do not match."
  end
  
  def test_change_username_and_password
    post "/user/edit_login", {new_username: "joe", current_password: "a", new_password: "b", reenter_password: "b"}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "joe", session[:user_name]
    assert_equal "Your username and password have been updated.", session[:message]
    
    post "/users/signin", {user_name: "joe", password: "b"}, {}
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "joe", session[:user_name]
  end
  
  def test_change_user_credentials_password_mismatched
    post "/user/edit_login", {new_username: "joe", current_password: "wrong_password", new_password: "b", reenter_password: "b"}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 422, last_response.status
    assert_equal "Clare MacAdie", session[:user_name]
    assert_includes last_response.body, "That is not the correct current password. Try again!"
  end

  def test_admin_categories_page
    get "/categories", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Administer categories"
  end

  def test_categories_page_not_admin
    get "/categories", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "Administer categories"
  end

  def test_categories_page_signed_out
    get "/categories"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "Administer categories"
  end

  def test_admin_add_category_page
    get "/categories/add_new", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new category"
  end
  
  def test_add_category_page_not_admin
    get "/categories/add_new", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "Add new category"
  end
  
  def test_add_category_page_signed_out
    get "/categories/add_new"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You must be an administrator to do that.", session[:message]
    refute_includes last_response.body, "Add new category"
  end
  
  def test_add_category
    post "/categories/add_new", {name: 'sport'}, admin_session
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "A new category of 'Sport' has been added.", session[:message]
  end
  
  def test_add_category_already_exists
    post "/categories/add_new", {name: 'magic'}, admin_session
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "That category name already exists. Please choose another name."
  end
  
  def test_add_category_blank
    post "/categories/add_new", {name: ''}, admin_session
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "The category name cannot be blank. Please try again."
  end

  def test_delete_category
    post "/category/Fantasy/delete", { name: "Fantasy" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "Category 'Fantasy' has been deleted.", session[:message]
    
    get "/categories"
    # Can't use the book's name as this is in the flash message.
    refute_includes last_response.body, "<td>Fantasy</td>"
  end

  def test_delete_category_not_admin
    post "/category/Fantasy/delete", { name: "Fantasy" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 2} }
    assert_equal 302, last_response.status
    assert_equal "You must be an administrator to do that.", session[:message]
    
    get "/books/filter_results/all_books/0"
    assert_includes last_response.body, "Fantasy"
  end

  def test_delete_category_signed_out
    post "/category/Fantasy/delete", { name: "Fantasy" }, {}
    assert_equal 302, last_response.status
    assert_equal "You must be an administrator to do that.", session[:message]
    
    get "/books/filter_results/all_books/0"
    assert_includes last_response.body, "Fantasy"
  end
end
