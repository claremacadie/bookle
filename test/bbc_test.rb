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
    
  end

  def teardown
  
  end

  # def session
  #   last_request.env["rack.session"]
  # end

  # def admin_session
  #   { "rack.session" => { username: "admin" } }
  # end

  def test_homepage
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Welcome to the Book Borrowers' Collective."
  end

  # def test_signin_form
  #   get "/users/signin"

  #   assert_equal 200, last_response.status
  #   assert_includes last_response.body, "<input"
  #   assert_includes last_response.body, %q(<button type="submit")
  # end

  # def test_signin
  #   post "/users/signin", username: "admin", password: "secret"
  #   assert_equal 302, last_response.status
  #   assert_equal "Welcome!", session[:message]
  #   assert_equal "admin", session[:username]

  #   get last_response["Location"]
  #   assert_includes last_response.body, "Signed in as admin"
  # end

  # def test_signin_with_bad_credentials
  #   post "/users/signin", username: "guest", password: "shhhh"
  #   assert_equal 422, last_response.status
  #   assert_nil session[:username]
  #   assert_includes last_response.body, "Invalid credentials"
  # end

  # def test_signout
  #   get "/", {}, {"rack.session" => { username: "admin" } }
  #   assert_includes last_response.body, "Signed in as admin"

  #   post "/users/signout"
  #   assert_equal "You have been signed out", session[:message]

  #   get last_response["Location"]
  #   assert_nil session[:username]
  #   assert_includes last_response.body, "Sign In"
  # end
  
  # def test_view_signup_form_signed_out
  #   get "/users/signup"
    
  #   assert_equal 200, last_response.status
  #   assert_includes last_response.body, "Reenter password"
  # end
  
  # def test_view_signup_form_signed_in
  #   get "/users/signup", {}, admin_session
    
  #   assert_equal 302, last_response.status
  #   assert_equal "You must be signed out to do that.", session[:message]
  # end
  
  # def test_signup_signed_out
  #   post "/users/signup", {new_username: "joe", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    
  #   assert_equal 302, last_response.status
  #   assert_equal "Your account has been created.", session[:message]

  #   get "/"
  #   assert_includes last_response.body, "Signed in as joe."
  # end
  
  # def test_signup_signed_in
  #   post "/users/signup", {new_username: "joe", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}, admin_session
    
  #   assert_equal 302, last_response.status
  #   assert_equal "You must be signed out to do that.", session[:message]
  # end
  
  # def test_signup_existing_username
  #   post "/users/signup", {new_username: "admin", password: "dfghiewo34334", reenter_password: "dfghiewo34334"}
    
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, "That username already exists."
  # end

  # def test_signup_mismatched_passwords
  #   post "/users/signup", {new_username: "joe", password: "dfghiewo34334", reenter_password: "mismatched"}
    
  #   assert_equal 422, last_response.status
  #   assert_includes last_response.body, "The passwords do not match."
  # end
end