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

  def all_books
    sql = "SELECT * FROM books"
    result = query(sql)

    tuple_to_list_hash(result.first)
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      title: tuple["title"], 
      collection_id: tuple["collection_id"].to_i, 
      author_id: tuple["author_id"],
      owner_id: tuple["owner_id"].to_i }
  end
end