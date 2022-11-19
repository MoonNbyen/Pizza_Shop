# Pizza_Shop

## Analytic plan

The data include year 2015's sale record from pizza shop which include pizza type, date and time of order and the price of each type of pizza.
Therefore it will be interesting to analysis following:

Annual Total Sales
Monthly Sales
Sales in time, day and month
Analysis the sales by pizza type.
Find out the best seller pizza type and size

## Database diagram

<img width="413" alt="image" src="https://user-images.githubusercontent.com/115092078/202870320-45441dfb-ad53-4f90-bccf-b2a74a92366f.png">



<img width="679" alt="Screen Shot 2022-11-19 at 21 21 42" src="https://user-images.githubusercontent.com/115092078/202870062-eaacd546-62c9-4a9e-9ff5-e9f92a9bb1e6.png">

## Data Dimention

<img width="749" alt="Screen Shot 2022-11-19 at 21 20 54" src="https://user-images.githubusercontent.com/115092078/202870064-ef97d617-8b82-45ca-a3d4-0482e225a726.png">

## Datasets Used

I uploaded data into gihub but my code's file path are from my computer.

https://github.com/MoonNbyen/Pizza_Shop/blob/main/pizzas.csv

https://github.com/MoonNbyen/Pizza_Shop/blob/main/orders.csv

https://github.com/MoonNbyen/Pizza_Shop/blob/main/pizza_types%20.csv

https://github.com/MoonNbyen/Pizza_Shop/blob/main/order_details.csv



## SQL Code

## Importing data

Creating database called Pizza_sales.
```sql
Create schema Pizza_Sales;
USE Pizza_Sales;
```
```sql
drop table order_details;
drop table pizza_order;
drop table pizza_type;
drop table pizzas;
```
Crate Order details
```sql
CREATE TABLE order_details

(order_detail_id INTEGER NOT NULL,
order_id INTEGER NOT NULL,
pizza_id VARCHAR(50),
quantity int,
PRIMARY KEY(order_detail_id));
```
Load order details data into created table
```sql
SHOW VARIABLES LIKE "secure_file_priv";
SHOW VARIABLES LIKE "local_infile";


LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/order_details.csv' 
INTO TABLE order_details
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(order_id,pizza_id,quantity);
```
Create Pizza Order table
```sql
CREATE TABLE pizza_order(
   order_id INTEGER  NOT NULL PRIMARY KEY ,
   date     DATE  NOT NULL,
   time     VARCHAR(8) NOT NULL
);
```
Load data
```sql

SHOW VARIABLES LIKE "secure_file_priv";
SHOW VARIABLES LIKE "local_infile";

LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/orders.csv' 
INTO TABLE pizza_order 
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(order_id,date,time);
```
Pizza Type table
```sql
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
```
Create Pizza Table
```sql
CREATE TABLE pizza(
   pizza_id      VARCHAR(30) NOT NULL PRIMARY KEY,
   pizza_type_id VARCHAR(20) NOT NULL,
   size          VARCHAR(5) NOT NULL,
   price         NUMERIC(5,2) NOT NULL
);
```
Load data
```sql
LOAD DATA INFILE '/Users/sengmoonja/Desktop/Pizza+Place+Sales/pizza_sales/pizzas.csv' 
INTO TABLE pizza
FIELDS TERMINATED BY ';' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES 
(pizza_id,pizza_type_id,size,price);
```
To check data
```sql
Show tables;
```
## Pizza Type information
To see detail information for selected pizza type.

```sql
DROP PROCEDURE IF EXISTS GetSalesByPizzaType;

DELIMITER //

CREATE PROCEDURE GetSalesByPizzaType(
	IN pizzaID VARCHAR(255)
)
BEGIN
	SELECT * 
 		FROM pizza AS p
        JOIN pizza_type AS pt
		ON p.pizza_type_id = pt.pizza_type_id
			WHERE pizza_id = pizzaID ;
END //
DELIMITER ;
```

-- Testing
```sql

CALL GetsalesByPizzaType('bbq_ckn_l');

```

 ## Annual Sales 
 
```sql
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
```
-- Testing
```sql
CALL Annual_Sales();
```
## Monthly Sales

```sql
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
```

-- Testing
```sql
CALL Monthly_Sales();
```

## Number of orders by,time,day and month 

```sql

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

```

-- Testing

```sql
CALL PizzaSalesTimeDate();
```

## Best Seller: Most ordered pizza type and size

```sql
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

```
-- Testing
```sql
CALL Best_Seller_Pizza();
```

## Pizza Sales Operation 

```sql

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

```

-- Testing

```sql
CALL CreatePizzaSalesShop();
```

-- Checking
```sql
SELECT * FROM pizza_sales ORDER BY OrderId;
```

## Trigger for after order 
```sql
use Pizza_Sales;
```
```sql
DROP TRIGGER IF EXISTS after_order_insert; 

DELIMITER $$

CREATE TRIGGER after_order_insert
AFTER INSERT
ON order_details FOR EACH ROW
BEGIN
	
    	INSERT INTO messages SELECT CONCAT('new order_id:', NEW.order_id);
		
		INSERT INTO pizza_sales
	SELECT 
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
```

Activating the trigger 
```sql
SELECT * FROM pizza_sales ORDER BY OrderId;
INSERT INTO pizza_order VALUES(99354,'2016-01-1','21:02:05'); 
SELECT * FROM pizza_sales ORDER BY OrderId;
```
## Data Marts 
```sql

 
 DROP VIEW IF EXISTS `Pizza_Sales_by_time_and_date_view`;
 
CREATE VIEW `Pizza_Sales_by_time_and_date_view` AS
	SELECT *
    FROM pizza_sales_by_time_and_date;
SELECT * FROM `Pizza_Sales_by_time_and_date_view`; 
```
```sql
   
 DROP VIEW IF EXISTS `Annual_Sales_View`;
 
CREATE VIEW `Annual_Sales_View` AS
	SELECT *
    FROM annual_sales;
SELECT * FROM `Annual_Sales_View`;
```
```sql
 
DROP VIEW IF EXISTS `Monthly_Sales_View`;   
CREATE VIEW `Monthly_Sales_View` AS
	SELECT *
    FROM monthly_sales;
SELECT * FROM `Monthly_Sales_View`;
```
```sql

DROP VIEW IF EXISTS `Pizza_Sales_View`;      
CREATE VIEW `Pizza_Sales_View` AS
	SELECT *
    FROM pizza_sales;
SELECT * FROM `Pizza_Sales_View`;
```
```sql

DROP VIEW IF EXISTS `Best_Seller_View`; 
CREATE VIEW `Best_Seller_View` AS
	SELECT *
    FROM best_seller_pizza;
SELECT * FROM `Best_Seller_View`;
```





