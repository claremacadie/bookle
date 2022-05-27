require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if ENV["RACK_ENV"] == "test"
            PG.connect(dbname: "bookle_test")
          else
            PG.connect(dbname: "bookle")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def upload_new_user_credentials(user_name, password)
    hashed_password = BCrypt::Password.create(password).to_s
    sql = "INSERT INTO users (name, password) VALUES ($1, $2)"
    query(sql, user_name, hashed_password)
  end

  def change_username_and_password(old_username, new_username, new_password)
    hashed_password = BCrypt::Password.create(new_password).to_s
    sql = "UPDATE users SET name = $1, password = $2 WHERE name = $3"
    query(sql, new_username, hashed_password, old_username)
  end
  
  def change_username(old_username, new_username)
    sql = "UPDATE users SET name = $1 WHERE name = $2"
    query(sql, new_username, old_username)
  end
  
  def change_password(old_username, new_password)
    hashed_password = BCrypt::Password.create(new_password).to_s
    sql = "UPDATE users SET password = $1 WHERE name = $2"
    query(sql, hashed_password, old_username)
  end

  def reset_password(username)
    new_password = BCrypt::Password.create('bookle').to_s
    sql = "UPDATE users SET password = $1 WHERE name = $2"
    query(sql, new_password, username)
  end

  def load_user_credentials
    sql = "SELECT name, password FROM users"
    result = query(sql)
    
    result.each_with_object({}) do |tuple, hash|
      hash[tuple["name"]] = tuple["password"] 
    end
  end

  def user_id(user_name)
    sql = "SELECT id FROM users WHERE name = $1"
    result = query(sql, user_name)
    result.first["id"].to_i
  end

  def owner_id(book_id)
    sql = "SELECT owner_id FROM books WHERE id = $1;"
    result = query(sql, book_id).first["owner_id"].to_i
  end

  def all_books
    sql = [select_clause, group_clause, order_clause].join(' ')
    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def count_all_books
    sql = "SELECT count(books.id) FROM books"
    query(sql).first["count"].to_i
  end
  
  def all_books_limit_offset(limit, offset)
    limit_clause = "LIMIT #{limit}"
    offset_clause = "OFFSET #{offset}"
    sql = [select_clause, group_clause, order_clause, limit_clause, offset_clause].join(' ')
    result = query(sql)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def count_available_books(user_id)
    sql = "SELECT count(books.id) FROM books WHERE owner_id != $1 AND requester_id IS NULL AND borrower_id IS NULL"
    query(sql, user_id).first["count"].to_i
  end
  
  def available_books(user_id, limit, offset)
    limit_clause = "LIMIT #{limit}"
    offset_clause = "OFFSET #{offset}"
    where_clause = "WHERE owner_id != $1 AND requester_id IS NULL AND borrower_id IS NULL"
    sql = [select_clause, where_clause, group_clause, order_clause, limit_clause, offset_clause].join(' ')
    result = query(sql, user_id)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end
  
  def count_filter_books(title, author, categories, availabilities)
    sql = [count_clause, where_clause_filter(categories, availabilities)].join(' ')
    result = query(sql, "%#{title}%", "%#{author}%").first
    if result == nil
      0
    else
      convert_string_to_integer(result["count"])
    end
  end

  def filter_books(title='', author='', categories=[], availabilities=[], limit, offset)
    limit_clause = "LIMIT #{limit}"
    offset_clause = "OFFSET #{offset}"
    sql = [select_clause, where_clause_filter(categories, availabilities), group_clause, order_clause, limit_clause, offset_clause].join(' ')
    result = query(sql, "%#{title}%", "%#{author}%")
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def count_user_books(user_id)
    sql = "SELECT count(books.id) FROM books WHERE owner_id = $1"
    query(sql, user_id).first["count"].to_i
  end
  
  def user_owned_books(user_id, limit, offset) 
    where_clause = "WHERE owners.id = $1"
    limit_clause = "LIMIT #{limit}"
    offset_clause = "OFFSET #{offset}"
    sql = [select_clause, where_clause, group_clause, order_clause, limit_clause, offset_clause].join(' ')
    result = query(sql, user_id)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end
  
  def book_data(book_id)
    where_clause = "WHERE books.id = $1"
    sql = [select_clause, where_clause, group_clause, order_clause].join(' ')
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
    requester_id = requester_id(book_id)
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
    sql = "SELECT * FROM categories ORDER BY NAME"
    result = query(sql)
    result.map do |tuple|
      tuple_to_category_hash(tuple)
    end
  end

  def categories(book_id)
    sql = "SELECT category_id FROM books_categories WHERE book_id = $1"
    result = query(sql, book_id)
    result.map do |tuple|
      tuple["category_id"].to_i
    end
  end

  def update_book_data(book_id, title, author, categories)
    sql = update_books_table_statement
    query(sql, book_id, title, author)

    unless categories.empty?
      sql = delete_from_books_categories_statement
      query(sql, book_id)

      categories.each do |category_id|
        sql = add_to_books_categories_statement
        query(sql, book_id, category_id)
      end
    end
  end

  def add_book(title, author, owner_id, categories)
    sql = insert_books_table_statement
    query(sql, title, author, owner_id)

    unless categories.empty?
      book_id = @db.exec("SELECT max(id) FROM books;").first["max"].to_i
      categories.each do |category_id|
        sql = add_to_books_categories_statement
        query(sql, book_id, category_id)
      end
    end
  end

  def delete_book(book_id, owner_id)
    sql = "DELETE FROM books WHERE id = $1 AND owner_id = $2;"
    query(sql, book_id, owner_id)
  end

  private

  def count_clause
    <<~COUNT_CLAUSE
    SELECT count(books.id)
    FROM books
    COUNT_CLAUSE
  end

  def select_clause
    <<~SELECT_CLAUSE
      SELECT 
        books.id, 
        books.title,
        books.author,
        string_agg(categories.name, ', ' ORDER BY categories.name) AS categories,
        owners.id AS owner_id,
        owners.name AS owner_name,
        requesters.id AS requester_id,
        requesters.name AS requester_name,
        borrowers.id AS borrower_id,
        borrowers.name AS borrower_name
      FROM books
      LEFT JOIN books_categories ON books.id = books_categories.book_id
      LEFT JOIN categories ON books_categories.category_id = categories.id
      INNER JOIN users AS owners ON books.owner_id = owners.id
      LEFT OUTER JOIN users AS requesters ON books.requester_id = requesters.id
      LEFT OUTER JOIN users AS borrowers ON  books.borrower_id = borrowers.id
    SELECT_CLAUSE
  end

  def availabilities_clause(availabilities)
    case 
    when availabilities.include?('available') && availabilities.include?('requested') && !availabilities.include?('on_loan')
      ' AND books.borrower_id IS NULL'
    when availabilities.include?('available') && availabilities.include?('on_loan') && !availabilities.include?('requested')
      ' AND books.requester_id IS NULL'
    when availabilities.include?('requested') && availabilities.include?('on_loan') && !availabilities.include?('available')
      ' AND (books.requester_id IS NOT NULL OR books.borrower_id IS NOT NULL)'
    when availabilities.include?('available') && !availabilities.include?('requested') && !availabilities.include?('on_loan')
      ' AND books.borrower_id IS NULL AND books.requester_id IS NULL'
    when availabilities.include?('requested') && !availabilities.include?('available') && !availabilities.include?('on_loan')
      ' AND books.requester_id IS NOT NULL'
    when availabilities.include?('on_loan') && !availabilities.include?('available') && !availabilities.include?('requested')
      ' AND books.borrower_id IS NOT NULL'
    else
      ''
    end
  end

  def where_clause(categories, availabilities)
    clause = "WHERE books.title ILIKE $1 AND books.author ILIKE $2"
    unless categories.empty?
      clause << " AND books_categories.category_id IN (#{categories.join(', ')})"
    end

    unless availabilities.empty?
      clause << availabilities_clause(availabilities)
    end
    clause
  end

  def where_clause_filter(categories, availabilities)
    clause = "WHERE books.title ILIKE $1 AND books.author ILIKE $2"
    unless categories.empty?
      clause << <<~CATEGORY_CLAUSE
         AND books.id IN (
          SELECT books.id FROM books
          INNER JOIN books_categories ON books.id = books_categories.book_id
          WHERE books_categories.category_id IN (#{categories.join(', ')})
        )
      CATEGORY_CLAUSE
    end

    unless availabilities.empty?
      clause << availabilities_clause(availabilities)
    end
    clause
  end

  def group_clause
    "GROUP BY books.id, owners.id, requesters.id, borrowers.id"
  end

  def order_clause
    "ORDER BY title"
  end

  def update_books_table_statement
    "UPDATE books SET title = $2, author = $3 WHERE id = $1"
  end

  def delete_from_books_categories_statement
    "DELETE FROM books_categories WHERE book_id = $1"
  end

  def insert_books_table_statement
    "INSERT INTO books (title, author, owner_id) VALUES ($1, $2, $3)"
  end

  def add_to_books_categories_statement
    <<~SQL
      INSERT INTO books_categories (book_id, category_id) 
      VALUES ($1, $2) 
      ON CONFLICT DO NOTHING;
    SQL
  end

  def query(statement, *params)
    begin
      @logger.info "#{statement}: #{params}"
      @db.exec_params(statement, params)
    rescue => error
      error 
    end
  end

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

  def requester_id(book_id)
    sql = "SELECT requester_id FROM books WHERE id = $1"
    result = query(sql, book_id).first
    result["requester_id"].to_i
  end
end
