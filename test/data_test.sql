TRUNCATE TABLE books, categories, books_categories, users
  RESTART IDENTITY;

INSERT INTO users (name, password) VALUES
  ('admin', '$2a$12$RDlwS.8sAOWA74qZYYe4yO2rHsO3ZKx2JohYcx5Ectd.Kul2JtGQi'),
  ('Clare MacAdie', '$2a$12$bEpZUdqQkgZpNe2wKL3vkO1xsCJzjTDNwolKVSMpKHMhtV6xm4vD6'),
  ('Alice Allbright', '$2a$12$ujZUWGjRsLNXJkz8RsYooeGc1gfR/TCn.nBui99y0sSnkg9Soi2D.'),
  ('Beth Broom', '$2a$12$sUdn9PHhPRKc2AVvRZj/r.uTGNh0Hu1Ell0yVdQKSXo6dyBGo0Rjm')
;

INSERT INTO categories (name) VALUES 
  ('Fantasy'),
  ('Magic'),
  ('History')
;

INSERT INTO books (title, author, owner_id, requester_id, borrower_id) VALUES
  ('Philosopher''s Stone', 'JK Rowling', 2, NULL, NULL),
  ('Chamber of Secrets', 'JK Rowling', 2, 3, NULL),
  ('Prisoner of Azkaban', 'JK Rowling', 2, NULL, 3),
  ('Goblet of Fire', 'JK Rowling', 2, 3, NULL),
  ('Order of the Phoenix', 'JK Rowling', 2, NULL, NULL),
  ('Half-Blood Prince', 'JK Rowling', 2, NULL, NULL),
  ('Deathly Hallows', 'JK Rowling', 2, NULL, NULL),
  ('Prince Caspian', 'CS Lewis', 3, NULL, 4),
  ('The Voyage of the Dawn Treader', 'CS Lewis', 3, NULL, 2),
  ('The Lion, the Witch and the Wardrobe', 'CS Lewis', 3, NULL, NULL),
  ('The Silver Chair', 'CS Lewis', 3, 2, NULL),
  ('The Horse and His Boy', 'CS Lewis', 3, NULL, NULL),
  ('The Magcian''s Nephew', 'CS Lewis', 3, NULL, NULL),
  ('The Last Battle', 'CS Lewis', 3, NULL, NULL),
  ('How to Train Your Dragon', 'Cressida Cowell', 3, NULL, NULL),
  ('How to Be a Pirate', 'Cressida Cowell', 3, NULL, NULL),
  ('How to Speak Dragonese', 'Cressida Cowell', 3, NULL, NULL),
  ('How to Cheat a Dragon''s Curse', 'Cressida Cowell', 3, NULL, NULL)
;

INSERT INTO books_categories (book_id, category_id) VALUES
  (1, 1), (1, 2),
  (2, 1), (2, 2),
  (3, 1), (3, 2),
  (4, 1), (4, 2)
; 
