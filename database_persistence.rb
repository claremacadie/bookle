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
      collections.name AS "collection", 
      string_agg(DISTINCT authors.name, ', ') AS authors, 
      string_agg(DISTINCT categories.name, ', ') AS categories,
      string_agg(DISTINCT users.first_name || ' ' || users.last_name, ', ') as owners
    FROM books
    FULL OUTER JOIN books_owners ON books.id = books_owners.book_id
    FULL OUTER JOIN users on books_owners.owner_id = users.id
    INNER JOIN authors_books ON  books.id = authors_books.book_id
    INNER JOIN authors ON authors_books.author_id = authors.id
    INNER JOIN books_categories on books.id = books_categories.book_id
    INNER JOIN categories on books_categories.category_id = categories.id
    FULL OUTER JOIN collections on books.collection_id = collections.id
    GROUP BY books.title, collections.name, books.id
    ORDER BY title;
      SQL
    result = query(sql)
    
    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def book_data(book_id)
    sql = <<~SQL
      SELECT 
        books.id,
        books.title,
        collections.name AS "collection", 
        string_agg(DISTINCT authors.name, ', ') AS authors, 
        string_agg(DISTINCT categories.name, ', ') AS categories
      FROM books
      INNER JOIN authors_books ON  books.id = authors_books.book_id
      INNER JOIN authors ON authors_books.author_id = authors.id
      INNER JOIN books_categories on books.id = books_categories.book_id
      INNER JOIN categories on books_categories.category_id = categories.id
      FULL OUTER JOIN collections on books.collection_id = collections.id
      WHERE books.id = $1
      GROUP BY collections.name, books.id;
    SQL

    result = query(sql, book_id)

    result.map do |tuple|
      tuple_to_book_hash(tuple)
    end.first
  end

  def book_instance(book_id)
    sql = <<~SQL
      SELECT 
        books_owners.book_id,
        (users.first_name || ' ' || users.last_name) AS owner,
        books_owners.available
      FROM users
      INNER JOIN books_owners ON users.id = books_owners.owner_id
      WHERE books_owners.book_id = $1;
    SQL
    
    result = query(sql, book_id)
    
    result.map do |tuple|
      tuple_to_book_instance_hash(tuple)
    end
  end
  private

  def tuple_to_book_instance_hash(tuple)
    { book_id: tuple["book_id"].to_i, 
      owner: tuple["owner"], 
      available: tuple["available"] == 't' }
  end

  def tuple_to_book_hash(tuple)
    { id: tuple["id"].to_i, 
      title: tuple["title"], 
      collection: tuple["collection"], 
      authors: tuple["authors"],
      categories: tuple["categories"] }
  end

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      title: tuple["title"], 
      collection: tuple["collection"], 
      authors: tuple["authors"],
      categories: tuple["categories"],
      owners: tuple["owners"] }
  end
end