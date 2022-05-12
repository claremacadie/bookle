ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../bbc"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    sql = File.read('test/schema_test.sql')
    PG.connect(dbname: "bbc_test").exec(sql)
  end

  def teardown
  
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user_name: "admin" } }
  end

  def test_homepage_signed_in
    get "/", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to the Book Borrowers' Collective."
    assert_includes last_response.body, "View your books"
  end

  def test_homepage_signed_out
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to the Book Borrowers' Collective."
    refute_includes last_response.body, "View your books"
  end
  
  def test_all_books_list
    get "/all_books_list"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Children's, Fantasy"
    assert_includes last_response.body, "On loan"
  end

  def test_view_your_books_signed_out
    get "/ownedby_user_books_list"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_view_your_books_signed_in
    get "/ownedby_user_books_list", {}, {"rack.session" => { user_name: "Clare MacAdie" , user_id: 1 } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "JK Rowling"
    assert_includes last_response.body, "Children's, Fantasy"
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
    refute_includes last_response.body, %q(<button>)
  end

  def test_view_requested_book_signed_in_as_book_owner
    get "/book/2", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested"
    assert_includes last_response.body, %q(<button>Loan book to Alice Allbright</button>)
    assert_includes last_response.body, %q(<button>Reject request from Alice Allbright</button>)
  end

  def test_view_requested_book_signed_in_as_book_requester
    get "/book/2", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested"
    assert_includes last_response.body, %q(<button>Cancel request</button>)
  end

  def test_view_requested_book_signed_in_as_not_book_owner_or_requester
    get "/book/2", {}, {"rack.session" => { user_name: "Beth Broom", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Chamber of Secrets"
    assert_includes last_response.body, "Requested"
    refute_includes last_response.body, %q(<button>)
  end

  def test_view_onloan_book_signed_in_as_book_owner
    get "/book/3", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan"
    assert_includes last_response.body, %q(<button>Book Returned</button>)
  end

  def test_view_onloan_book_signed_in_as_book_borrower
    get "/book/3", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan"
    refute_includes last_response.body, %q(<button>)
  end

  def test_view_onloan_book_signed_in_not_as_book_owner_or_borrower
    get "/book/3", {}, {"rack.session" => { user_name: "Beth Broom", user_id: 3 } }
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Prisoner of Azkaban"
    assert_includes last_response.body, "On loan"
    refute_includes last_response.body, %q(<button>)
  end
   
  def test_request_book
    post "/book/1/requested", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have requested Philosopher's Stone from Clare MacAdie", session[:message]
    
    get "/book/1", {}, {"rack.session" => { user_name: "Alice Allbright" } }
    assert_includes last_response.body, "Requested"
  end
   
  def test_cancel_request_book
    post "/book/2/cancelled_request", {}, {"rack.session" => { user_name: "Alice Allbright", user_id: 2 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have cancelled your request for Chamber of Secrets from Clare MacAdie", session[:message]
    
    get "/book/2", {}, {"rack.session" => { user_name: "Alice Allbright" } }
    assert_includes last_response.body, "Available"
  end
   
  def test_loan_book
    post "/book/2/loaned", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 302, last_response.status
    assert_equal "Chamber of Secrets has been loaned to Alice Allbright", session[:message]
    
    get "/book/2", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    assert_includes last_response.body, "On loan"
  end
   
  def test_reject_request_book
    post "/book/2/rejected_request", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
    assert_equal 302, last_response.status
    assert_equal "You have rejected a request for Chamber of Secrets from Alice Allbright", session[:message]
    
    get "/book/2", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    assert_includes last_response.body, "Available"
  end

  def test_return_book
    post "/book/3/returned", {}, {"rack.session" => { user_name: "Clare MacAdie", user_id: 1 } }
    
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