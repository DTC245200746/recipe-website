SET NAMES utf8mb4;

CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE recipes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  instructions TEXT NOT NULL,
  category_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE ingredients (
  id INT AUTO_INCREMENT PRIMARY KEY,
  recipe_id INT NOT NULL,
  name VARCHAR(150) NOT NULL,
  quantity VARCHAR(80),
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);

INSERT INTO categories (name) VALUES ('Món chính'), ('Món canh'), ('Món chay'), ('Tráng miệng');

INSERT INTO recipes (title, description, instructions, category_id) VALUES
('Canh chua cá lóc', 'Món canh chua đặc trưng miền Tây.', 'Nấu nước sôi, cho me, cà chua, dứa vào. Thả cá, nêm nếm vừa ăn. Thêm rau thơm trước khi tắt bếp.', 2),
('Đậu hũ sốt cà chua', 'Món chay đơn giản, dễ làm.', 'Chiên vàng đậu hũ. Xào cà chua, thêm gia vị, cho đậu vào đun nhỏ lửa 5 phút.', 3);

INSERT INTO ingredients (recipe_id, name, quantity) VALUES
(1, 'Cá lóc', '500g'), (1, 'Me', '2 muỗng'), (1, 'Cà chua', '2 quả'), (1, 'Dứa', '1/4 quả'),
(2, 'Đậu hũ', '4 miếng'), (2, 'Cà chua', '3 quả'), (2, 'Hành lá', '1 nhúm');
