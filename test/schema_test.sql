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
  ('Beth Broom', '$2a$12$sUdn9PHhPRKc2AVvRZj/r.uTGNh0Hu1Ell0yVdQKSXo6dyBGo0Rjm')
;

INSERT INTO categories (name) VALUES 
  ('Children''s'),
  ('Fantasy'),
  ('Education')
;

INSERT INTO books (title, author, owner_id, requester_id, borrower_id) VALUES
  ('Philospher''s Stone', 'JK Rowling', 1, NULL, 2),
  ('Chamber of Secrets', 'JK Rowling', 1, NULL, 2),
  ('Prisoner of Azkaban', 'JK Rowling', 1, 3, NULL),
  ('Goblet of Fire', 'JK Rowling', 1, 2, NULL),
  ('Order of the Phoenix', 'JK Rowling', 1, NULL, NULL),
  ('Half-Blood Prince', 'JK Rowling', 1, NULL, NULL),
  ('Deathly Hallows', 'JK Rowling', 1, NULL, NULL),
  ('Prince Caspian', 'CS Lewis', 2, NULL, 3),
  ('The Voyage of the Dawn Treader', 'CS Lewis', 2, NULL, 1),
  ('The Lion, the Witch and the Wardrobe', 'CS Lewis', 2, NULL, NULL),
  ('The Silver Chair', 'CS Lewis', 2, 1, NULL),
  ('The Horse and His Boy', 'CS Lewis', 2, NULL, NULL),
  ('The Magcian''s Nephew', 'CS Lewis', 2, NULL, NULL),
  ('The Last Battle', 'CS Lewis', 2, NULL, NULL),
  ('How to Train Your Dragon', 'Cressida Cowell', 2, NULL, NULL),
  ('How to Be a Pirate', 'Cressida Cowell', 2, NULL, NULL),
  ('How to Speak Dragonese', 'Cressida Cowell', 2, NULL, NULL),
  ('How to Cheat a Dragon''s Curse', 'Cressida Cowell', 2, NULL, NULL)
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