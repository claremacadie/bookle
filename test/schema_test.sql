DROP TABLE books_categories;
DROP TABLE categories;
DROP TABLE books;
DROP TABLE users;

CREATE TABLE users (
  id serial PRIMARY KEY,
  name text NOT NULL,
  password text NOT NULL UNIQUE
);

CREATE TABLE categories (
  id serial PRIMARY KEY,
  name text NOT NULL
);

CREATE TABLE books (
  id serial PRIMARY KEY,
  title text NOT NULL,
  author text NOT NULL,
  owner_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  requester_id integer REFERENCES users(id),
  borrower_id integer REFERENCES users(id)
);

CREATE TABLE books_categories (
  id serial PRIMARY KEY,
  book_id integer NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  category_id integer NOT NULL REFERENCES categories(id) ON DELETE CASCADE
);

INSERT INTO users (name, password) VALUES
  ('Clare MacAdie', '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
  ('Alice Allbright', '$2a$12$ujZUWGjRsLNXJkz8RsYooeGc1gfR/TCn.nBui99y0sSnkg9Soi2D.'),
  ('Beth Broom', '$2a$12$sUdn9PHhPRKc2AVvRZj/r.uTGNh0Hu1Ell0yVdQKSXo6dyBGo0Rjm'),
  ('admin', '$2a$12$dJR3ZSHERpUWHM2llKxVaOsoBm5zGtNRwF/BQLXZcYgxF0u/ak0bu')
;

INSERT INTO categories (name) VALUES 
  ('Children''s'),
  ('Fantasy'),
  ('Education')
;

INSERT INTO books (title, author, owner_id, requester_id, borrower_id) VALUES
  ('Philospher''s Stone', 'JK Rowling', 1, NULL, 2),
  ('Chamber of Secrets', 'JK Rowling', 1, NULL, 2),
  ('Prisoner of Azkaban', 'JK Rowling', 1, NULL, NULL),
  ('Goblet of Fire', 'JK Rowling', 1, 2, NULL)
;

INSERT INTO books_categories (book_id, category_id) VALUES
  (1, 1), (1, 2),
  (2, 1), (2, 2),
  (3, 1), (3, 2),
  (4, 1), (4, 2)
; 
