require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
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

  def add_new_user(user_name)
    sql = "INSERT INTO users (name) VALUES ($1)"
    query(sql, user_name)
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