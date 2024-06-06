CREATE DATABASE coffeebeans;

CREATE TABLE coffeecustomers;
CREATE TABLE coffeeprods;
CREATE TABLE orders;

-- --Data cleaning
-- --DROPPING USELESS COLUMNS

ALTER TABLE orders
DROP Customer_Name,
DROP Email,
DROP Country,
DROP Coffeetype,
DROP Roasttype,
DROP Size,
DROP Unitprice,
DROP Sales;

-- --CHECKING FOR DUPLICATES

WITH duplicates as(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY OrderID, OrderDate, CustomerID, ProductID, Quantity) AS row_num
FROM orders
)
SELECT * 
FROM duplicates
WHERE row_num > 1;

WITH duplicates_cte as(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY CustomerID, Customer_Name, Email, PhoneNumber, AddressLine1, City, Country, Postcode, LoyaltyCard) AS row_num
FROM coffeecustomers
)
SELECT * 
FROM duplicates_cte
WHERE row_num > 1;


UPDATE orders
SET orderdate = date_format(str_to_date(orderdate, '%d/%m/%Y'), '%Y-%m-%d');

-- --Changing the dates column data type 
ALTER TABLE orders
MODIFY COLUMN orderdate DATE;

CREATE VIEW SALES_SUMMARY AS
SELECT orders.customerid, orderdate, orders.productid, coffeetype, Roasttype, size, country, LoyaltyCard, unitprice, quantity, profit, sum(UnitPrice*quantity) AS revenue, sum(profit*quantity) AS profits
FROM orders
JOIN coffeeprods on coffeeprods.productid = orders.productid
JOIN coffeecustomers ON coffeecustomers.CustomerID = orders.customerID
GROUP BY orders.customerid, orderdate, orders.productid, coffeetype, Roasttype, size, country, LoyaltyCard, unitprice, quantity, profit;

-- --ANALYSIS
-- --What is the total revenue? 
SELECT round(sum(revenue),0) AS Total_revenue 
FROM sales_summary;

-- --What is the total profit?
SELECT round(sum(profits),0) AS Total_profit 
FROM sales_summary;

-- --profit by coffeetype
SELECT coffeetype, round(sum(profits)) AS Total_profit
FROM sales_summary
GROUP BY coffeetype
ORDER BY Total_profit DESC;   

-- --Revenue by coffee type.
SELECT coffeetype, round(sum(unitprice*quantity)) AS Total_revenue
FROM sales_summary
GROUP BY coffeetype;

-- --Revenue by country
SELECT country, round(sum(unitprice*quantity))AS Total_revenue
FROM sales_summary
GROUP BY country;

-- --Revenue by year
WITH revenue_by_year AS(
SELECT YEAR(orderdate) AS year, monthname(orderdate) AS monthname, MONTH(orderdate) AS month, round(sum(unitprice*quantity)) AS Total_revenue
FROM sales_summary
GROUP BY YEAR(orderdate), monthname(orderdate), MONTH(orderdate)
)
SELECT year, monthname, Total_revenue
FROM revenue_by_year
ORDER BY year, month;

-- --What is the distribution of of the quantities of coffee types ordered?
SELECT coffeetype, SUM(quantity) AS quantity
FROM sales_summary
GROUP BY coffeetype
ORDER BY SUM(quantity) DESC;

-- --Coffee types with the highest and lowest quantity demanded across countries
SELECT country, coffeetype, SUM(quantity) AS quantity
FROM sales_summary
GROUP BY country, coffeetype
ORDER BY SUM(quantity) DESC;

-- -Number of custoers with and without loyalty cards.
WITH LOYALTY_CARD AS(
SELECT Distinct(customerid), loyaltycard
from sales_summary
)
SELECT loyaltycard, count(*) AS count
FROM loyalty_card
GROUP BY loyaltycard 
ORDER BY count desc; 


-- --What roast types are the most preferred in the various countries?
SELECT Roasttype, country, sum(quantity) AS quantity
FROM sales_summary
GROUP BY Roasttype, country
ORDER BY roasttype;