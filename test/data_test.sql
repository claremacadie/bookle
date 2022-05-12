TRUNCATE TABLE books, categories, books_categories, users;

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
  ('Philosopher''s Stone', 'JK Rowling', 1, NULL, NULL),
  ('Chamber of Secrets', 'JK Rowling', 1, 2, NULL),
  ('Prisoner of Azkaban', 'JK Rowling', 1, NULL, 2),
  ('Goblet of Fire', 'JK Rowling', 1, 2, NULL)
;

INSERT INTO books_categories (book_id, category_id) VALUES
  (1, 1), (1, 2),
  (2, 1), (2, 2),
  (3, 1), (3, 2),
  (4, 1), (4, 2)
; 
