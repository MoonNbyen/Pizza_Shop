Create schema Pizza_Sales;
use Pizza_Sales;

drop table order_details;
drop table pizza_order;
drop table pizza_type;
drop table pizzas;

CREATE TABLE order_details

(order_detail_id INTEGER NOT NULL,
order_id INTEGER NOT NULL,
pizza_id VARCHAR(50),
quantity int,
PRIMARY KEY(order_detail_id));

SHOW VARIABLES LIKE "secure_file_priv";
SHOW VARIABLES LIKE "local_infile";


LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/order_details.csv' 
INTO TABLE order_details
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(order_id,pizza_id,quantity);


CREATE TABLE pizza_order(
   order_id INTEGER  NOT NULL PRIMARY KEY ,
   date     DATE  NOT NULL,
   time     VARCHAR(8) NOT NULL
);


SHOW VARIABLES LIKE "secure_file_priv";
SHOW VARIABLES LIKE "local_infile";

LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/orders.csv' 
INTO TABLE pizza_order 
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(order_id,date,time);

CREATE TABLE pizza_type(
   pizza_type_id VARCHAR(12) NOT NULL PRIMARY KEY,
   name          VARCHAR(42) NOT NULL,
   category      VARCHAR(7) NOT NULL
);

SHOW VARIABLES LIKE "secure_file_priv";
SHOW VARIABLES LIKE "local_infile";

LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/pizza_types .csv' 
INTO TABLE pizza_type
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(pizza_type_id,name,category);

CREATE TABLE pizza(
   pizza_id      VARCHAR(30) NOT NULL PRIMARY KEY,
   pizza_type_id VARCHAR(20) NOT NULL,
   size          VARCHAR(5) NOT NULL,
   price         NUMERIC(5,2) NOT NULL
);

LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/pizzas.csv' 
INTO TABLE pizza
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(pizza_id,pizza_type_id,size,price);



Show tables;



-- -----------------------------Get SalesbyPizzaType -----------------------------------------

DROP PROCEDURE IF EXISTS GetSalesByPizzaType;

DELIMITER //

CREATE PROCEDURE GetSalesByPizzaType(
	IN pizzaID VARCHAR(255)
)
BEGIN
	SELECT * 
 		FROM pizza
			WHERE pizza_id = pizzaID ;
END //
DELIMITER ;

-- Testing
CALL GetsalesByPizzaType('bbq_ckn_l');

-- ----------------------------------  Annual Sales ---------------------------------

DROP PROCEDURE IF EXISTS Annual_Sales;

DELIMITER //

CREATE PROCEDURE Annual_Sales()
BEGIN

	DROP TABLE IF EXISTS annual_sales;

	CREATE TABLE annual_sales AS
    
	SELECT 
		EXTRACT(year from a.date),
		COUNT(b.quantity) AS quantity,
		SUM(ROUND(p.price)) AS Total_Price
		FROM pizza_order AS a
		JOIN order_details AS b
		ON a.order_id = b.order_id
		JOIN pizza AS p
		ON b.pizza_id = p.pizza_id
		
        GROUP BY a.date,b.pizza_id
		ORDER BY quantity DESC;

END //
DELIMITER ;
-- Testing
CALL Annual_Sales();

-- ----------------------------------------------Get Sales by Month --------------------------------------

DROP PROCEDURE IF EXISTS Monthly_Sales;

DELIMITER //

CREATE PROCEDURE Monthly_Sales()
BEGIN

	DROP TABLE IF EXISTS Monthly_Sales;

	CREATE TABLE monthly_sales AS
    
		SELECT DISTINCT
		a.date,b.pizza_id,COUNT(b.quantity) AS quantity,SUM(ROUND(c.price)) AS price,
		EXTRACT(month from a.date) as Month
		
		FROM pizza_order AS a
		JOIN order_details AS b
		ON a.order_id=b.order_id
		JOIN pizza AS c
		ON b.pizza_id=c.pizza_id
		GROUP BY a.date,b.pizza_id
		ORDER BY quantity DESC;
       

END //
DELIMITER ;
-- Testing
CALL Monthly_Sales();


-- ------------------------Aggregating number of orders by,time,day and month ---------------------------------


DROP PROCEDURE IF EXISTS PizzaSalesTimeDate;

DELIMITER //

CREATE PROCEDURE PizzaSalesTimeDate()
BEGIN

	DROP TABLE IF EXISTS pizza_sales_by_time_and_date;

	CREATE TABLE pizza_sales_by_time_and_date AS
    
	SELECT DISTINCT 

		count(a.quantity) AS quantity,b.time, b.date,
		EXTRACT(day FROM date ) as day,
		EXTRACT(month from date) AS month,
		EXTRACT(year from date) AS year
		FROM order_details AS a
		JOIN pizza_order AS b
		ON a.order_id=b.order_id
		GROUP BY date,time
		ORDER BY date, time DESC;
       
	
END //
DELIMITER ;
-- Testing
CALL PizzaSalesTimeDate();

-- ----------------Best Seller: Most ordered pizza type and size


DROP PROCEDURE IF EXISTS Best_Seller_Pizza;

DELIMITER //

CREATE PROCEDURE Best_Seller_Pizza()
BEGIN

	DROP TABLE IF EXISTS best_seller_pizza;

	CREATE TABLE best_seller_pizza AS
    
	SELECT DISTINCT 

	a.pizza_id AS pizza_type,SUM(a.quantity) AS quantity,
	b.size
	FROM order_details AS a
	JOIN pizza AS b
	ON a.pizza_id=b.pizza_id
	GROUP BY a.pizza_id,b.size,a.quantity
	ORDER BY quantity DESC;
       
	
END //
DELIMITER ;
-- Testing
CALL Best_Seller_Pizza();


-- ----------------------------------------------- Pizza Sales Shop -------------------------------------------------

DROP PROCEDURE IF EXISTS CreatePizzaSalesShop;

DELIMITER //

CREATE PROCEDURE CreatePizzaSalesShop()
BEGIN

	DROP TABLE IF EXISTS pizza_sales;

	CREATE TABLE pizza_sales AS
    
	SELECT DISTINCT 
	   a.order_id AS OrderId, 
	   p.pizza_id As Pizza_ID,  
       pt.name AS Pizza_Name,
	   p.price AS Price, 
	   b.quantity AS Unit,
       p.price * b.quantity AS Total_Price,
	   a.time As Time,
	   a.date AS Date
       
		FROM pizza_order AS a
		JOIN order_details AS b
		ON a.order_id = b.order_id
		JOIN pizza AS p
		ON b.pizza_id = p.pizza_id
		JOIN pizza_type AS pt
		ON p.pizza_type_id = pt.pizza_type_id
		ORDER BY a.order_id, pt.name;

END //
DELIMITER ;
-- Testing
CALL CreatePizzaSalesShop();

-- Checking
SELECT * FROM pizza_sales ORDER BY OrderId;

-- ------------------------------------------Trigger for after order ----------------------------------
use Pizza_Sales;
DROP TRIGGER IF EXISTS after_order_insert; 

DELIMITER $$

CREATE TRIGGER after_order_insert
AFTER INSERT
ON order_details FOR EACH ROW
BEGIN
	
    	INSERT INTO messages SELECT CONCAT('new order_id:', NEW.order_id);
		
		INSERT INTO pizza_sales
			SELECT DISTINCT 
	   a.order_id AS OrderId, 
	   p.pizza_id As Pizza_ID,  
       pt.name AS Pizza_Name,
	   p.price AS Price, 
	   b.quantity AS Unit,
       p.price * b.quantity AS Total_Price,
	   a.time As Time,
	   a.date AS Date
       
		FROM pizza_order AS a
		JOIN order_details AS b
		ON a.order_id = b.order_id
		JOIN pizza AS p
		ON b.pizza_id = p.pizza_id
		JOIN pizza_type AS pt
		ON p.pizza_type_id = pt.pizza_type_id
		ORDER BY a.order_id, pt.name;
        
END $$

DELIMITER ;

-- ------------------------------------Activating the trigger ------------------------------------------------
SELECT * FROM pizza_sales ORDER BY OrderId;
INSERT INTO pizza_order VALUES(99354,'2016-01-1','21:02:05'); 
INSERT INTO order_details VALUES(99354,21350,'bbq_ckn_s',2);
SELECT * FROM pizza_sales ORDER BY OrderId;

-- -----------------------------------Data Marts --------------------------------------------------------------

 DROP VIEW IF EXISTS `Pizza Sales by time and date`;
 
CREATE VIEW `Pizza Sales by time and date` AS
	SELECT *
    FROM pizza_sales_by_time_and_date
    Group by date;
 DROP VIEW IF EXISTS `Annual Sales`;
 
CREATE VIEW `Annual Sales` AS
	SELECT *
    FROM annual_sales;
   
DROP VIEW IF EXISTS `Monthly Sales`;   
CREATE VIEW `Monthly Sales` AS
	SELECT *
    FROM monthly_sales;

DROP VIEW IF EXISTS `Pizza Sales`;      
CREATE VIEW `Pizza Sales` AS
	SELECT *
    FROM pizza_sales;


DROP VIEW IF EXISTS `Best Seller`; 
CREATE VIEW `Best Seller` AS
	SELECT *
    FROM best_seller_pizza







