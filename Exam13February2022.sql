CREATE SCHEMA online_store;

USE online_store;

-- Section 1: Data Definition Language (DDL)
-- 1. Table Design

CREATE TABLE `brands` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(40) NOT NULL UNIQUE );

CREATE TABLE `categories` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(40) NOT NULL UNIQUE );

CREATE TABLE `reviews` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`content` TEXT,
`rating` DECIMAL(10,2) NOT NULL,
`picture_url` VARCHAR(80) NOT NULL,
`published_at` DATETIME NOT NULL );

CREATE TABLE `products` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`name` VARCHAR(40) NOT NULL,
`price` DECIMAL(19, 2) NOT NULL,
`quantity_in_stock` INT,
`description` TEXT,
`brand_id` INT NOT NULL,
`category_id` INT NOT NULL,
`review_id` INT,
CONSTRAINT fk_product_brand
FOREIGN KEY (brand_id) REFERENCES brands(id),
CONSTRAINT fk_product_category
FOREIGN KEY (category_id) REFERENCES categories (id),
CONSTRAINT fk_product_review
FOREIGN KEY (review_id) REFERENCES reviews (id));

CREATE TABLE `customers` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`first_name` VARCHAR(20) NOT NULL,
`last_name` VARCHAR(20) NOT NULL,
`phone` VARCHAR(30) NOT NULL UNIQUE,
`address` VARCHAR(60) NOT NULL,
`discount_card` BIT DEFAULT 0 NOT NULL);

CREATE TABLE `orders` (
`id` INT PRIMARY KEY AUTO_INCREMENT,
`order_datetime` DATETIME NOT NULL,
`customer_id` INT NOT NULL,
CONSTRAINT fk_customer_order
FOREIGN KEY (customer_id) REFERENCES customers(id));

CREATE TABLE `orders_products` (
`order_id` INT,
`product_id` INT,
KEY pk_orders_products (order_id, product_id),
CONSTRAINT fk_id_orders
FOREIGN KEY (order_id) REFERENCES orders(id),
CONSTRAINT fk_id_products
FOREIGN KEY (product_id) REFERENCES products(id));

-- Section 2: Data Manipulation Language(DML)
-- 2. Insert

INSERT INTO reviews (content, rating , picture_url, published_at)
SELECT left(`description`, 15), price/8, reverse(`name`), '2010-10-10'
FROM products WHERE id >= 5;

-- 3. Update

UPDATE products
SET quantity_in_stock = quantity_in_stock - 5
WHERE quantity_in_stock BETWEEN 60 AND 70;

-- 4. Delete

DELETE c FROM customers AS c
LEFT JOIN orders AS o
ON c.id = o.customer_id
WHERE o.customer_id IS NULL;

-- Section 3: Querying
-- 5. Categories

SELECT * FROM categories
ORDER BY `name` DESC;

-- 6. Quantity

SELECT id, brand_id, `name`, quantity_in_stock FROM products
WHERE price > 1000 AND quantity_in_stock < 30
ORDER BY quantity_in_stock;

-- 7. Review

SELECT id, content,	rating,	picture_url, published_at FROM reviews
WHERE LEFT(content, 2) = 'My' AND LENGTH(content) > 61
ORDER BY rating DESC;

-- 8. First customers

SELECT CONCAT_WS(' ', customers.first_name, customers.last_name) AS full_name, customers.address, orders.order_datetime 
FROM customers RIGHT JOIN orders 
ON customers.id = orders.customer_id
WHERE year(orders.order_datetime) <= 2018
ORDER BY full_name DESC;

-- 9. Best categories

SELECT COUNT(products.id) AS items_count, categories.`name`, SUM(products.quantity_in_stock) AS total_quantity 
FROM products RIGHT JOIN categories 
ON products.category_id = categories.id
GROUP BY products.category_id
ORDER BY items_count DESC, total_quantity
LIMIT 5;

-- 10. Extract client cards count 

CREATE FUNCTION udf_customer_products_count(name VARCHAR(30))
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE total_products INT;
    SET total_products := (
		SELECT COUNT(op.product_id)
        FROM orders_products AS op
        JOIN orders AS o
        ON op.order_id = o.id
        JOIN customers AS c
        ON o.customer_id = c.id
        WHERE c.first_name = `name`
    );
    RETURN total_products;
END

-- 11. Reduce price

CREATE PROCEDURE udp_reduce_price(category_name VARCHAR(50))
BEGIN UPDATE products AS p
	  JOIN categories AS c
      ON c.id = p.category_id
      JOIN reviews AS r
      ON p.review_id = r.id
      SET p.price = p.price * 0.7
	  WHERE r.rating < 4.00 AND c.`name` = category_name;
END





