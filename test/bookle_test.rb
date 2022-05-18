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
    PG.connect(dbname: "bookle_test").exec(sql)
  end

  def teardown
  
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user_name: "admin" } }
  end

  ####### Unit (Method) tests




  ####### Integration (Route) tests
  def test_homepage_signed_in
    get "/", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to Bookle."
    assert_includes last_response.body, "Home"
    assert_includes last_response.body, "View all books"
    assert_includes last_response.body, "View your books"
    assert_includes last_response.body, "View available books"
    assert_includes last_response.body, "Signed in as Clare MacAdie"
    assert_includes last_response.body, %q(<button type="submit">Sign Out</button>)
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
    refute_includes last_response.body, "View all books"
    refute_includes last_response.body, "View your books"
    refute_includes last_response.body, "View available books"
    refute_includes last_response.body, "Signed in as"
    refute_includes last_response.body, %q(<button type="submit">Sign Out</button>)
  end
  
  def test_all_books_list_signed_in
    get "/all_books_list", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Fantasy, Magic"
    assert_includes last_response.body, "On loan"
  end
  
  def test_all_books_list_signed_out
    get "/all_books_list"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
    
    get last_response["Location"]
    assert_includes last_response.body, "Home"
  end
  
  def test_available_books_list_signed_in
    get "/books/available", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    refute_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "How to Train a Dragon"
  end
  
  def test_available_books_list_signed_out
    get "/books/available"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
    
    get last_response["Location"]
    assert_includes last_response.body, "Home"
  end
  
  def test_view_your_books_signed_in
    get "/users/book_list", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add new book"
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Fantasy, Magic"
  end
  
  def test_view_your_books_signed_out
    get "/users/book_list"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
  
  def test_filter_books_form_signed_in
    get "/books/filter", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value="")
    assert_includes last_response.body, %q(<input type="checkbox")
    assert_includes last_response.body, %q(<button type="submit">See Results</button>)
  
  end
  
  def test_filter_books_form_signed_out
    get "/books/filter"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_filtered_by_title_books_list_signed_in
    post "/books/filter", {title: 'k', author: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
  end

  def test_filtered_by_author_books_list_signed_in
    post "/books/filter", {title: '', author: 'k'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_title_and_author_books_list_signed_in
    post "/books/filter", {title: 'a', author: 'a'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end

  def test_filtered_by_category_books_list_signed_in
    post "/books/filter", {title: '', author: '', category_id: '1'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_title_and_category_books_list_signed_in
    post "/books/filter", {title: 'k', author: '', category_id: '1'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_author_and_category_books_list_signed_in
    post "/books/filter", {title: '', author: 'k', category_id: '1'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
  end

  def test_filtered_by_availability_is_available_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: 'availability', requested: '', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_availability_is_requested_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: '', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_onloan_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: '', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_available_and_requested_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: 'availability', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_availability_is_available_and_onloan_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: 'availability', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
  end
  
  def test_filtered_by_availability_is_requested_and_onloan_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: '', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_available_requested_and_onloan_books_list_signed_in
    post "/books/filter", {title: '', author: '', available: 'availability', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
  end

  def test_filtered_by_title_and_availability_is_available_books_list_signed_in
    post "/books/filter", {title: 't', author: '', available: 'availability', requested: '', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_author_and_availability_is_requested_books_list_signed_in
    post "/books/filter", {title: '', author: 'k', available: '', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_title_and_availability_is_onloan_books_list_signed_in
    post "/books/filter", {title: 'k', author: '', available: '', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_title_and_availability_is_available_and_requested_books_list_signed_in
    post "/books/filter", {title: 't', author: '', available: 'availability', requested: 'availability', on_loan: ''}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_title_and_availability_is_available_and_onloan_books_list_signed_in
    post "/books/filter", {title: 't', author: '', available: 'availability', requested: '', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
  end
  
  def test_filtered_by_title_and_availability_is_requested_and_onloan_books_list_signed_in
    post "/books/filter", {title: 't', author: '', available: '', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "Prisoner of Azkaban"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Philosopher's Stone"
  end
  
  def test_filtered_by_availability_is_available_requested_and_onloan_books_list_signed_in
    post "/books/filter", {title: 't', author: '', available: 'availability', requested: 'availability', on_loan: 'availability'}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Goblet of Fire"
    assert_includes last_response.body, "How to Train a Dragon"
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_by_title_author_category_and_availability_list_signed_in
    post "/books/filter", {title: 'o', author: 'o', category_id: '1', available: 'availability' }, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Philosopher's Stone"
    refute_includes last_response.body, "Chamber of Secrets"
    refute_includes last_response.body, "Goblet of Fire"
    refute_includes last_response.body, "How to Train a Dragon"
    refute_includes last_response.body, "Prisoner of Azkaban"
  end
  
  def test_filtered_books_list_signed_out
    post "/books/filter"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_view_book_signed_out
    get "/book/2"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_view_available_book_signed_in_as_book_owner
    get "/book/1", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Philosopher's Stone"
    assert_includes last_response.body, "Available"
    assert_includes last_response.body, "Edit book"
    assert_includes last_response.body, "Delete book"
    refute_includes last_response.body, %q(<button>)
  end
  
  def test_view_requested_book_signed_in_as_book_owner
    get "/book/2", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested by Alice Allbright"
    assert_includes last_response.body, %q(<button>Loan book to Alice Allbright</button>)
    assert_includes last_response.body, %q(<button>Reject request from Alice Allbright</button>)
    assert_includes last_response.body, "Edit book details"
    assert_includes last_response.body, "Delete book"
  end
  
  def test_view_requested_book_signed_in_as_book_requester
    get "/book/2", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested by you"
    assert_includes last_response.body, %q(<button>Cancel request</button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, "Delete book"
  end
  
  def test_view_requested_book_signed_in_as_not_book_owner_or_requester
    get "/book/2", {}, {"rack.session" => { user_name: "Beth Broom", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested by Alice Allbright"
    refute_includes last_response.body, %q(<button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, "Delete book"
  end
  
  def test_view_onloan_book_signed_in_as_book_owner
    get "/book/3", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan to Alice Allbright"
    assert_includes last_response.body, %q(<button>Book Returned</button>)
    assert_includes last_response.body, "Edit book details"
    assert_includes last_response.body, "Delete book"
  end
  
  def test_view_onloan_book_signed_in_as_book_borrower
    get "/book/3", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan to you"
    refute_includes last_response.body, %q(<button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, "Delete book"
  end
  
  def test_view_onloan_book_signed_in_not_as_book_owner_or_borrower
    get "/book/3", {}, {"rack.session" => { user_name: "Beth Broom", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan to Alice Allbright"
    refute_includes last_response.body, %q(<button>)
    refute_includes last_response.body, "Edit book details"
    refute_includes last_response.body, "Delete book"
  end
   
  def test_request_book
    post "/book/1/request", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have requested Philosopher's Stone from Clare MacAdie", session[:message]
    
    get "/book/1", {}, {"rack.session" => { user_name: "Alice Allbright" } }
    assert_includes last_response.body, "Requested by you"
  end
   
  def test_request_book_user_owns
    post "/book/1/request", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    output = StringIO.new
    
    # What assertions can confirm this error?
  end
  def test_loan_book_user_owns
    post "/book/1/loan", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    output = StringIO.new
    
    # What assertions can confirm this error?
  end
   
  def test_cancel_request_book
    post "/book/2/cancel_request", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have cancelled your request for Chamber of Secrets from Clare MacAdie", session[:message]
    
    get "/book/2", {}, {"rack.session" => { user_name: "Alice Allbright" } }
    assert_includes last_response.body, "Available"
  end
   
  def test_loan_book
    post "/book/2/loan", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 302, last_response.status
    assert_equal "Chamber of Secrets has been loaned to Alice Allbright", session[:message]
    
    get "/book/2", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    assert_includes last_response.body, "On loan to Alice Allbright"
  end
   
  def test_reject_request_book
    post "/book/2/reject_request", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have rejected a request for Chamber of Secrets from Alice Allbright", session[:message]
    
    get "/book/2", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    assert_includes last_response.body, "Available"
  end

  def test_return_book
    post "/book/3/return", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 302, last_response.status
    assert_equal "Prisoner of Azkaban has been returned", session[:message]
    
    get "/book/3", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    assert_includes last_response.body, "Available"
  end
  
  def test_view_available_book_signedin_as_not_book_owner
    get "/book/1", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Philosopher's Stone"
    assert_includes last_response.body, "Available"
    assert_includes last_response.body, %q(<button>Request book</button>)
  end

  def add_book_not_signedin
    get "/book/add"
    
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end
  
  def test_add_book_signedin
    get "/book/add_new", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value=)
    assert_includes last_response.body, %q(<button type="submit">Add new book</button>)
  end

  def test_add_new_book
    post "/book/add_new", { title: "new title", author: "new author", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1} }
    assert_equal 302, last_response.status
    assert_equal "new title has been added.", session[:message]
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "new title"
    assert_includes last_response.body, "new author"
  end

  def delete_book_not_signedin
    get "/book/1/delete"
    
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def delete_book_not_signedin_not_as_book_owner
    get "/book/1/delete", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You must be the book owner to do that.", session[:message]
  end
  
  def test_delete_book_signedin
    get "/book/1/delete", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Are you sure you want to delete \"Philosopher's Stone\"?"
    assert_includes last_response.body, %q(<button type="submit">Delete Philosopher's Stone</button>)
    assert_includes last_response.body, %q(<button type="submit">Cancel</button>)
  end

  def test_delete_book
    post "/book/1/delete", { book_id: "1" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1} }
    assert_equal 302, last_response.status
    assert_equal "Philosopher's Stone has been deleted.", session[:message]
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    
    get "users/book_list"
    refute_includes last_response.body, "Philosopher's Stone"
  end

  def test_edit_book_signedin_as_book_owner
    get "/book/1/edit", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<input id="title" type="text" name="title" value="Philosopher's Stone")
    assert_includes last_response.body, %q(<input id="authors" type="text" name="author" value="JK Rowling")
    assert_includes last_response.body, %q(<button type="submit">Submit</button>)
  end

  def test_edit_book_signedin_as_not_book_owner
    get "/book/1/edit", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You must be the book owner to do that.", session[:message]
  end

  def test_edit_book_not_signedin
    get "/book/1/edit"
    
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_change_book_details
    post "/book/1/edit", { title: "new title", author: "new author", category_id_3: "3" }, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1} }
    assert_equal 302, last_response.status
    assert_equal "Book details have been updated for new title.", session[:message]
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "new title"
    assert_includes last_response.body, "new author"
  end

  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post "/users/signin", user_name: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:user_name]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/signin", user_name: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:user_name]
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_signout
    get "/", {}, {"rack.session" => { user_name: "admin", user_id: 4 } }
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
    post "/users/signup", {new_username: "admin", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    
    assert_equal 422, last_response.status
    assert_includes last_response.body, "That username already exists."
  end

  def test_signup_mismatched_passwords
    post "/users/signup", {new_username: "joanna", password: "dfghiewo34334", reenter_password: "mismatched"}
    
    assert_equal 422, last_response.status
    assert_includes last_response.body, "The passwords do not match."
  end
end