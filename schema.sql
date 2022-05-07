DROP TABLE books_categories;
DROP TABLE loans;
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
  collection_id integer REFERENCES collections(id),
  author_id integer NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
  owner_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE books_categories (
  id serial PRIMARY KEY,
  book_id integer NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  category_id integer NOT NULL REFERENCES categories(id) ON DELETE CASCADE
);

CREATE TABLE loans (
  id serial PRIMARY KEY,
  book_id integer REFERENCES books(id) ON DELETE CASCADE,
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

INSERT INTO books (title, collection_id, author_id, owner_id) VALUES
  ('Philospher''s Stone', 1, 1, 1),
  ('Chamber of Secrets', 1, 1, 1),
  ('Prisoner of Azkaban', 1, 1, 1),
  ('Goblet of Fire', 1, 1, 1),
  ('Order of the Phoenix', 1, 1, 1),
  ('Half-Blood Prince', 1, 1, 1),
  ('Deathly Hallows', 1, 1, 1),
  ('Prince Caspian', 2, 2, 2),
  ('The Voyage of the Dawn Treader', 2, 2, 2),
  ('The Lion, the Witch and the Wardrobe', 2, 2, 2),
  ('The Silver Chair', 2, 2, 2),
  ('The Horse and His Boy', 2, 2, 2),
  ('The Magcian''s Nephew', 2, 2, 2),
  ('The Last Battle', 2, 2, 2),
  ('How to Train Your Dragon', 3, 3, 1),
  ('How to Be a Pirate', 3, 3, 2),
  ('How to Speak Dragonese', 3, 3, 1),
  ('How to Cheat a Dragon''s Curse', 3, 3, 1)
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

INSERT INTO loans (book_id, borrower_id, loan_start, loan_end) VALUES
  (1, 2, '2022-04-07', '2022-04-28')
;

INSERT INTO loans (book_id, borrower_id) VALUES
  (2, 2),
  (3, 3)
;
