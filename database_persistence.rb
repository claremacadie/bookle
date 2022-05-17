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

  def load_user_credentials
    sql = "SELECT name, password FROM users"
    result = query(sql)
    
    result.each_with_object({}) do |tuple, hash|
      hash[tuple["name"]] = tuple["password"] 
    end
  end

  def get_user_id(user_name)
    sql = "SELECT id FROM users WHERE name = $1"
    result = query(sql, user_name)
    result.first["id"].to_i
  end

  def get_owner_id(book_id)
    sql = "SELECT owner_id FROM books WHERE id = $1;"
    result = query(sql, book_id).first["owner_id"].to_i
  end

  def all_books
    sql = select_query(:all_books)
    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def available_books(user_id)
    sql = select_query(:available_books)
    result = query(sql, user_id)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def filter_books(title, author, category_ids)
    if !title.empty? && author.empty? && category_ids.empty?
      sql = select_query(:filter_title)
      result = query(sql, "%#{title}%")
    elsif title.empty? && !author.empty? && category_ids.empty?
      sql = select_query(:filter_author)
      result = query(sql, "%#{author}%")
    elsif !title.empty? && !author.empty? && category_ids.empty?
      sql = select_query(:filter_category)
      result = query(sql)
    elsif title.empty? && author.empty? && !category_ids.empty?
      sql = select_query_join_table(category_ids)
      result = query(sql)
    end

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end
  
  def user_owned_books(user_id)
    sql = select_query(:user_books)
    result = query(sql, user_id)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end
  
  def book_data(book_id)
    sql = select_query(:book_data)
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
    sql = "SELECT * FROM categories ORDER BY NAME"
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

  def update_book_data(book_id, title, author, category_ids)
    sql = update_books_table_statement
    query(sql, book_id, title, author)

    unless category_ids.empty?
      sql = delete_from_books_categories_statement
      query(sql, book_id)

      category_ids.each do |category_id|
        sql = add_to_books_categories_statement
        query(sql, book_id, category_id)
      end
    end
  end

  def add_book(title, author, owner_id, category_ids)
    sql = insert_books_table_statement
    query(sql, title, author, owner_id)

    unless category_ids.empty?
      book_id = @db.exec("SELECT max(id) FROM books;").first["max"].to_i
      category_ids.each do |category_id|
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

  def select_query(query_type, category_ids = '')
    select_clause = <<~SELECT_CLAUSE
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
    
    where_clause =  case query_type
                    when :all_books
                      ''
                    when :available_books
                      <<~WHERE_CLAUSE
                        WHERE owner_id != $1 AND requester_id IS NULL AND borrower_id IS NULL
                      WHERE_CLAUSE
                    when :filter_title
                      "WHERE books.title ILIKE $1"
                    when :filter_author
                      "WHERE books.author ILIKE $1"
                    when :filter_title_and_author
                      "WHERE books.title ILIKE $1 AND books.author ILIKE $2"
                    when :filter_category
                      "WHERE books_categories.category_id IN (#{category_ids.join(', ')})"
                    when :user_books
                      "WHERE owners.id = $1"
                    when :book_data
                      "WHERE books.id = $1"
    end

    group_clause = <<~GROUP_CLAUSE
      GROUP BY books.id, owners.id, requesters.id, borrowers.id
    GROUP_CLAUSE

    order_clause = <<~ORDER_CLAUSE
      ORDER BY title
    ORDER_CLAUSE
     
    [select_clause, where_clause, group_clause, order_clause].join(' ')
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

  def get_requester_id(book_id)
    sql = "SELECT requester_id FROM books WHERE id = $1"
    result = query(sql, book_id).first
    result["requester_id"].to_i
  end
end