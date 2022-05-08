DROP TABLE authors_books;
DROP TABLE books_categories;
DROP TABLE loans;
DROP TABLE books_owners;
DROP TABLE books;
DROP TABLE users;
DROP TABLE authors;
DROP TABLE categories;
DROP TABLE collections;

CREATE TABLE users (
  id serial PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text NOT NULL UNIQUE
);

CREATE TABLE authors (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE categories (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE collections (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE books (
  id serial PRIMARY KEY,
  title text NOT NULL,
  collection_id integer REFERENCES collections(id)
);

CREATE TABLE authors_books (
  id serial PRIMARY KEY,
  book_id integer NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  author_id integer NOT NULL REFERENCES authors(id) ON DELETE CASCADE
);

CREATE TABLE books_categories (
  id serial PRIMARY KEY,
  book_id integer NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  category_id integer NOT NULL REFERENCES categories(id) ON DELETE CASCADE
);

CREATE TABLE books_owners (
  id serial PRIMARY KEY,
  book_id integer NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  owner_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  available boolean DEFAULT true
);

CREATE TABLE loans (
  id serial PRIMARY KEY,
  books_owners_id integer REFERENCES books_owners(id) ON DELETE CASCADE,
  borrower_id integer REFERENCES users(id) ON DELETE CASCADE,
  loan_start date NOT NULL DEFAULT NOW(),
  loan_end date CHECK (loan_end >= loan_start)
);

INSERT INTO users (first_name, last_name, email) VALUES
  ('Clare', 'MacAdie', 'clare@email.com'),
  ('Alice', 'Allbright', 'alice@email.com'),
  ('Beth', 'Broom', 'beth@email.com')
  ;

INSERT INTO authors (name) VALUES
  ('JK Rowling'),
  ('CS Lewis'),
  ('Cressida Cowell'),
  ('Dr Seuss')
;

INSERT INTO categories (name) VALUES 
  ('Children''s'),
  ('Fantasy'),
  ('Education')
;

INSERT INTO collections (name) VALUES 
  ('Harry Potter'),
  ('Chronicles of Narnia'),
  ('How to Train a Dragon')
;

INSERT INTO books (title, collection_id) VALUES
  ('Philospher''s Stone', 1),
  ('Chamber of Secrets', 1),
  ('Prisoner of Azkaban', 1),
  ('Goblet of Fire', 1),
  ('Order of the Phoenix', 1),
  ('Half-Blood Prince', 1),
  ('Deathly Hallows', 1),
  ('Prince Caspian', 2),
  ('The Voyage of the Dawn Treader', 2),
  ('The Lion, the Witch and the Wardrobe', 2),
  ('The Silver Chair', 2),
  ('The Horse and His Boy', 2),
  ('The Magcian''s Nephew', 2),
  ('The Last Battle', 2),
  ('How to Train Your Dragon', 3),
  ('How to Be a Pirate', 3),
  ('How to Speak Dragonese', 3),
  ('How to Cheat a Dragon''s Curse', 3)
;

INSERT INTO authors_books (author_id, book_id) VALUES
  (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6),(1, 7),
  (2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14),
  (3, 15), (3, 16), (3, 17), (3, 18)
;

INSERT INTO books_categories (book_id, category_id) VALUES
  (1, 1), (1, 2),
  (2, 1), (2, 2),
  (3, 1), (3, 2),
  (4, 1), (4, 2),
  (5, 1), (5, 2),
  (6, 1), (6, 2),
  (7, 1), (7, 2),
  (8, 1),
  (9, 1),
  (10, 1),
  (11, 1),
  (12, 1),
  (13, 1),
  (14, 1),
  (15, 1),
  (16, 1),
  (17, 1),
  (18, 1)
; 

INSERT INTO books_owners (book_id, owner_id, available) VALUES
  (1, 1, true),
  (2, 1, false),
  (3, 2, true),
  (3, 1, false)
;

INSERT INTO loans (books_owners_id, borrower_id, loan_start, loan_end) VALUES
  (1, 2, '2022-04-07', '2022-04-28')
;

INSERT INTO loans (books_owners_id, borrower_id) VALUES
  (2, 2),
  (3, 3)
;

/*
    SELECT books_owners.available
    FROM books_owners
    WHERE books_owners.id = 1;
*/
