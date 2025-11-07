-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 04, 2025 at 09:24 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `ecommerce_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `place_order` (IN `userId` INT)   BEGIN
  DECLARE total DECIMAL(10,2);
  SET total = (
    SELECT SUM(p.price * ci.quantity)
    FROM cart_items ci
    JOIN products p ON ci.product_id = p.product_id
    JOIN cart c ON ci.cart_id = c.cart_id
    WHERE c.user_id = userId
  );

  INSERT INTO orders (user_id, total_amount, status)
  VALUES (userId, total, 'Pending');

  INSERT INTO order_items (order_id, product_id, quantity, price)
  SELECT LAST_INSERT_ID(), ci.product_id, ci.quantity, p.price
  FROM cart_items ci
  JOIN cart c ON ci.cart_id = c.cart_id
  JOIN products p ON ci.product_id = p.product_id
  WHERE c.user_id = userId;

  DELETE ci FROM cart_items ci
  JOIN cart c ON ci.cart_id = c.cart_id
  WHERE c.user_id = userId;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `cart_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cart`
--

INSERT INTO `cart` (`cart_id`, `user_id`) VALUES
(1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `cart_items`
--

CREATE TABLE `cart_items` (
  `cart_item_id` int(11) NOT NULL,
  `cart_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`category_id`, `category_name`, `description`) VALUES
(1, 'Electronics', 'Devices and gadgets'),
(2, 'Clothing', 'Men and women apparel'),
(3, 'Books', 'Various genres of books'),
(4, 'Home Decor', 'Items for home decoration'),
(5, 'Sports', 'Sports and fitness equipment');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `order_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `order_item_id` int(11) NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `product_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `order_items`
--
DELIMITER $$
CREATE TRIGGER `reduce_stock` AFTER INSERT ON `order_items` FOR EACH ROW BEGIN
  UPDATE products
  SET stock = stock - NEW.quantity
  WHERE product_id = NEW.product_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `product_name` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `stock` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `category_id`, `product_name`, `description`, `price`, `stock`) VALUES
(1, 1, 'Smartphone', 'Latest model smartphone', 29999.99, 50),
(2, 1, 'Laptop', 'High-performance laptop', 74999.99, 20),
(3, 1, 'Headphones', 'Noise cancelling headphones', 4999.99, 100),
(4, 1, 'Smartwatch', 'Stylish smartwatch', 10999.99, 40),
(5, 1, 'Bluetooth Speaker', 'Portable speaker', 2999.99, 60),
(6, 1, 'Tablet', 'Lightweight tablet', 25999.99, 25),
(7, 2, 'T-Shirt', 'Cotton t-shirt', 499.99, 200),
(8, 2, 'Jeans', 'Slim-fit jeans', 1299.99, 150),
(9, 2, 'Jacket', 'Winter jacket', 2499.99, 80),
(10, 2, 'Sneakers', 'Casual sneakers', 1799.99, 100),
(11, 2, 'Dress', 'Floral print dress', 1599.99, 50),
(12, 2, 'Cap', 'Stylish cap', 299.99, 300),
(13, 3, 'Novel', 'Best-selling novel', 399.99, 100),
(14, 3, 'Textbook', 'Computer Science textbook', 999.99, 70),
(15, 3, 'Comics', 'Graphic novel comics', 299.99, 120),
(16, 3, 'Notebook', 'A5 ruled notebook', 99.99, 500),
(17, 3, 'Biography', 'Inspirational biography', 499.99, 60),
(18, 3, 'Magazine', 'Monthly tech magazine', 199.99, 200),
(19, 4, 'Wall Clock', 'Modern design clock', 799.99, 40),
(20, 4, 'Lamp', 'Bedside table lamp', 1199.99, 30),
(21, 4, 'Painting', 'Canvas wall art', 2499.99, 20),
(22, 4, 'Vase', 'Ceramic flower vase', 699.99, 60),
(23, 4, 'Cushion', 'Comfortable cushion', 499.99, 100),
(24, 4, 'Curtains', 'Set of 2 curtains', 999.99, 50),
(25, 5, 'Football', 'Professional football', 999.99, 70),
(26, 5, 'Cricket Bat', 'Willow cricket bat', 2499.99, 40),
(27, 5, 'Tennis Racket', 'Lightweight racket', 1999.99, 30),
(28, 5, 'Yoga Mat', 'Anti-slip mat', 799.99, 90),
(29, 5, 'Dumbbells', 'Set of 2 dumbbells', 1499.99, 50),
(30, 5, 'Skipping Rope', 'Durable rope', 299.99, 150);

-- --------------------------------------------------------

--
-- Table structure for table `product_images`
--

CREATE TABLE `product_images` (
  `image_id` int(11) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `product_images`
--

INSERT INTO `product_images` (`image_id`, `product_id`, `image_url`) VALUES
(1, 1, 'https://placehold.co/300x300?text=Product+1'),
(2, 2, 'https://placehold.co/300x300?text=Product+2'),
(3, 3, 'https://placehold.co/300x300?text=Product+3'),
(4, 4, 'https://placehold.co/300x300?text=Product+4'),
(5, 5, 'https://placehold.co/300x300?text=Product+5'),
(6, 6, 'https://placehold.co/300x300?text=Product+6'),
(7, 7, 'https://placehold.co/300x300?text=Product+7'),
(8, 8, 'https://placehold.co/300x300?text=Product+8'),
(9, 9, 'https://placehold.co/300x300?text=Product+9'),
(10, 10, 'https://placehold.co/300x300?text=Product+10'),
(11, 11, 'https://placehold.co/300x300?text=Product+11'),
(12, 12, 'https://placehold.co/300x300?text=Product+12'),
(13, 13, 'https://placehold.co/300x300?text=Product+13'),
(14, 14, 'https://placehold.co/300x300?text=Product+14'),
(15, 15, 'https://placehold.co/300x300?text=Product+15'),
(16, 16, 'https://placehold.co/300x300?text=Product+16'),
(17, 17, 'https://placehold.co/300x300?text=Product+17'),
(18, 18, 'https://placehold.co/300x300?text=Product+18'),
(19, 19, 'https://placehold.co/300x300?text=Product+19'),
(20, 20, 'https://placehold.co/300x300?text=Product+20'),
(21, 21, 'https://placehold.co/300x300?text=Product+21'),
(22, 22, 'https://placehold.co/300x300?text=Product+22'),
(23, 23, 'https://placehold.co/300x300?text=Product+23'),
(24, 24, 'https://placehold.co/300x300?text=Product+24'),
(25, 25, 'https://placehold.co/300x300?text=Product+25'),
(26, 26, 'https://placehold.co/300x300?text=Product+26'),
(27, 27, 'https://placehold.co/300x300?text=Product+27'),
(28, 28, 'https://placehold.co/300x300?text=Product+28'),
(29, 29, 'https://placehold.co/300x300?text=Product+29'),
(30, 30, 'https://placehold.co/300x300?text=Product+30');

-- --------------------------------------------------------

--
-- Stand-in structure for view `product_summary`
-- (See below for the actual view)
--
CREATE TABLE `product_summary` (
`product_id` int(11)
,`product_name` varchar(100)
,`category_name` varchar(100)
,`price` decimal(10,2)
,`stock` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `password`, `created_at`) VALUES
(1, 'ashutosh', 'ashu@example.com', '12345', '2025-11-03 16:10:42');

-- --------------------------------------------------------

--
-- Structure for view `product_summary`
--
DROP TABLE IF EXISTS `product_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `product_summary`  AS SELECT `p`.`product_id` AS `product_id`, `p`.`product_name` AS `product_name`, `c`.`category_name` AS `category_name`, `p`.`price` AS `price`, `p`.`stock` AS `stock` FROM (`products` `p` join `categories` `c` on(`p`.`category_id` = `c`.`category_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`cart_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`cart_item_id`),
  ADD KEY `cart_id` (`cart_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`category_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `product_images`
--
ALTER TABLE `product_images`
  ADD PRIMARY KEY (`image_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `cart`
--
ALTER TABLE `cart`
  MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `cart_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `order_item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `product_images`
--
ALTER TABLE `product_images`
  MODIFY `image_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cart`
--
ALTER TABLE `cart`
  ADD CONSTRAINT `cart_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`cart_id`) REFERENCES `cart` (`cart_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE CASCADE;

--
-- Constraints for table `product_images`
--
ALTER TABLE `product_images`
  ADD CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
