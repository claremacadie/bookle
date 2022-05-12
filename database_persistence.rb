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

  def get_user_id(username)
    sql = "SELECT id FROM users WHERE name = $1"
    result = query(sql, username)
    result.first["id"].to_i
  end

  def all_books_list
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

  def ownedby_user_books_list(username)
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
      WHERE owners.name = $1
      GROUP BY books.id, owners.id, requesters.id, borrowers.id
      ORDER BY title;
    SQL
    result = query(sql, username)
    
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

  def book_requested(book_id, requester_name)
    sql = "SELECT id FROM users WHERE name = $1"
    result = query(sql, requester_name).first
    requester_id = result["id"]

    sql = "UPDATE books SET requester_id = $1 WHERE id = $2"
    query(sql, requester_id, book_id)
  end

  def book_cancelled_request(book_id)
    sql = "UPDATE books SET requester_id =NULL WHERE id = $1"
    query(sql, book_id)
  end

  def book_loaned(book_id)
    sql = "SELECT requester_id FROM books WHERE id = $1"
    result = query(sql, book_id).first
    requester_id = result["requester_id"]

    sql = "UPDATE books SET requester_id = NULL, borrower_id = $1 WHERE id = $2"
    query(sql, requester_id, book_id)
  end

  def book_rejected_request(book_id)
    sql = "UPDATE books SET requester_id = NULL WHERE id = $1"
    query(sql, book_id)
  end

  def book_returned(book_id)
    sql = "UPDATE books SET borrower_id = NULL WHERE id = $1"
    query(sql, book_id)
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      title: tuple["title"], 
      author: tuple["author"],
      categories: tuple["categories"],
      owner_id: tuple["owner_id"],
      owner_name: tuple["owner_name"],
      requester_id: tuple["requester_id"],
      requester_name: tuple["requester_name"],
      borrower_id: tuple["borrower_id"],
      borrower_name: tuple["borrower_name"] }
  end
end