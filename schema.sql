DROP TABLE books_categories;
DROP TABLE categories;
DROP TABLE books;
DROP TABLE users;

CREATE TABLE users (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL UNIQUE,
  password text NOT NULL,
  CHECK (name != ''),
  CHECK (password != '')
);

CREATE TABLE categories (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL UNIQUE,
  CHECK (name != '')
);

CREATE TABLE books (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title text NOT NULL,
  author text NOT NULL,
  owner_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  requester_id integer REFERENCES users(id),
  borrower_id integer REFERENCES users(id),
  CHECK (title != ''),
  CHECK (author != ''),
  CHECK (owner_id != requester_id),
  CHECK (owner_id != borrower_id),
  CHECK (requester_id IS NULL OR borrower_id IS NULL)
);

CREATE TABLE books_categories (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  book_id integer NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  category_id integer NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  UNIQUE (book_id, category_id)
);
