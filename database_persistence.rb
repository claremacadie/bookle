require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if ENV["RACK_ENV"] == "test"
            PG.connect(dbname: "bbc_test")
          else
            PG.connect(dbname: "bbc")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def upload_new_user_credentials(user_name, password)
    hashed_password = BCrypt::Password.create(password).to_s
    sql = "INSERT INTO users (name, password) VALUES ($1, $2)"
    query(sql, user_name, hashed_password)
  end

  def load_user_credentials
    sql = "SELECT name, password FROM users"
    result = query(sql)
    
    users_hash = {}
    result.map do |tuple|
      users_hash[tuple["name"]] = tuple["password"] 
    end
    users_hash
  end

  def get_user_id(user_name)
    sql = "SELECT id FROM users WHERE name = $1"
    result = query(sql, user_name)
    result.first["id"].to_i
  end

  def all_books
    sql = <<~SQL
      SELECT 
        books.id, 
        books.title,
        books.author,
        string_agg(categories.name, ', ') AS categories,
        owners.id AS owner_id,
        owners.name AS owner_name,
        requesters.id AS requester_id,
        requesters.name AS requester_name,
        borrowers.id AS borrower_id,
        borrowers.name AS borrower_name
      FROM books
      INNER JOIN books_categories ON books.id = books_categories.book_id
      INNER JOIN categories ON books_categories.category_id = categories.id
      INNER JOIN users AS owners ON books.owner_id = owners.id
      LEFT OUTER JOIN users AS requesters ON books.requester_id = requesters.id
      LEFT OUTER JOIN users AS borrowers ON  books.borrower_id = borrowers.id
      GROUP BY books.id, owners.id, requesters.id, borrowers.id
      ORDER BY title;
    SQL
    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def user_owned_books(user_id)
    sql = <<~SQL
      SELECT
        books.id, 
        books.title,
        books.author,
        string_agg(categories.name, ', ') AS categories,
        owners.id AS owner_id,
        owners.name AS owner_name,
        requesters.id AS requester_id,
        requesters.name AS requester_name,
        borrowers.id AS borrower_id,
        borrowers.name AS borrower_name
      FROM books
      INNER JOIN books_categories ON books.id = books_categories.book_id
      INNER JOIN categories ON books_categories.category_id = categories.id
      INNER JOIN users AS owners ON books.owner_id = owners.id
      LEFT OUTER JOIN users AS requesters ON books.requester_id = requesters.id
      LEFT OUTER JOIN users AS borrowers ON  books.borrower_id = borrowers.id
      WHERE owners.id = $1
      GROUP BY books.id, owners.id, requesters.id, borrowers.id
      ORDER BY title;
    SQL
    result = query(sql, user_id)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end
  
  def book_data(book_id)
    sql = <<~SQL
      SELECT 
        books.id, 
        books.title,
        books.author,
        string_agg(categories.name, ', ') AS categories,
        owners.id AS owner_id,
        owners.name AS owner_name,
        requesters.id AS requester_id,
        requesters.name AS requester_name,
        borrowers.id AS borrower_id,
        borrowers.name AS borrower_name
      FROM books
      INNER JOIN books_categories ON books.id = books_categories.book_id
      INNER JOIN categories ON books_categories.category_id = categories.id
      INNER JOIN users AS owners ON books.owner_id = owners.id
      LEFT OUTER JOIN users AS requesters ON books.requester_id = requesters.id
      LEFT OUTER JOIN users AS borrowers ON  books.borrower_id = borrowers.id
      WHERE books.id = $1
      GROUP BY books.id, owners.id, requesters.id, borrowers.id
      ORDER BY title;
    SQL
    result = query(sql, book_id)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end.first
  end

  def book_add_request(book_id, requester_id)
    sql = "UPDATE books SET requester_id = $1 WHERE id = $2"
    query(sql, requester_id, book_id)
  end

  def book_cancel_request(book_id)
    sql = "UPDATE books SET requester_id = NULL WHERE id = $1"
    query(sql, book_id)
  end

  def book_loan(book_id)
    requester_id = get_requester_id(book_id)
    sql = "UPDATE books SET requester_id = NULL, borrower_id = $1 WHERE id = $2"
    query(sql, requester_id, book_id)
  end

  def book_reject_request(book_id)
    sql = "UPDATE books SET requester_id = NULL WHERE id = $1"
    query(sql, book_id)
  end

  def book_return(book_id)
    sql = "UPDATE books SET borrower_id = NULL WHERE id = $1"
    query(sql, book_id)
  end

  def categories_list
    sql = "SELECT * FROM categories"
    result = query(sql)
    result.map do |tuple|
      tuple_to_category_hash(tuple)
    end
  end

  def get_category_ids(book_id)
    sql = "SELECT category_id FROM books_categories WHERE book_id = $1"
    result = query(sql, book_id)
    result.map do |tuple|
      tuple["category_id"].to_i
    end
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      title: tuple["title"], 
      author: tuple["author"],
      categories: tuple["categories"],
      owner_id: convert_string_to_integer(tuple["owner_id"]),
      owner_name: tuple["owner_name"],
      requester_id: convert_string_to_integer(tuple["requester_id"]),
      requester_name: tuple["requester_name"],
      borrower_id: convert_string_to_integer(tuple["borrower_id"]),
      borrower_name: tuple["borrower_name"] }
  end
  
  def tuple_to_category_hash(tuple)
    { id: tuple["id"].to_i, 
      name: tuple["name"] }
  end

  def convert_string_to_integer(str)
    # This is needed because nil.to_i returns 0!!!
    str ? str.to_i : nil
  end

  def get_requester_id(book_id)
    sql = "SELECT requester_id FROM books WHERE id = $1"
    result = query(sql, book_id).first
    result["requester_id"].to_i
  end
end