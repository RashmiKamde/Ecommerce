SELECT * FROM [dbo].[Customers];
SELECT * FROM [dbo].[Orders];
SELECT * FROM [dbo].[Products];


UPDATE Customers
SET Email = LOWER(REPLACE(Customer_Name, ' ', '')) + '@gmail.com';

--- when there are duplicate names

WITH RankedCustomers AS (
    SELECT 
        Customer_ID, 
        LOWER(REPLACE(Customer_Name, ' ', '')) + '@gmail.com' AS BaseEmail,
        ROW_NUMBER() OVER (PARTITION BY LOWER(REPLACE(Customer_Name, ' ', '')) ORDER BY Customer_ID) AS Rank
    FROM Customers
)
UPDATE Customers
SET Email = 
    CASE 
        WHEN RankedCustomers.Rank = 1 THEN RankedCustomers.BaseEmail
        ELSE LOWER(REPLACE(Customers.Customer_Name, ' ', '')) + CAST(RankedCustomers.Rank AS VARCHAR) + '@gmail.com'
    END
FROM Customers
INNER JOIN RankedCustomers 
ON Customers.Customer_ID = RankedCustomers.Customer_ID;

SELECT TOP 5 * FROM Customers;

update orders 
set Total_Amount = CEILING(total_amount);

select * from Orders;

update Products 
set Ratings_Avg = CEILING(Ratings_Avg); 
SELECT * FROM Products;

--- Customer Insights
--- Q1. Who are the top 10 highest-spending customers?

--- M1
select top 10
o.Customer_ID, c.customer_name, c.email, c.loyalty_status, sum(o.total_amount) as Total_Amt
from Orders as o
join customers as c
on c.Customer_ID = o.Customer_ID
group by o.Customer_ID, c.customer_name, c.email, c.loyalty_status
order by Total_Amt desc;

--- M2
SELECT TOP 10 c.*, o.Total_Amt
FROM customers AS c
JOIN (
    SELECT customer_id, SUM(total_amount) AS Total_Amt
    FROM orders
    GROUP BY customer_id
) AS o 
ON c.customer_id = o.customer_id
ORDER BY o.Total_Amt DESC;


--- Q2. What is the average order value (AOV) per customer segment (Silver, Gold, Platinum)?

SELECT c.Loyalty_Status, CEILING(AVG(o.Total_Amount)) AS AOV
FROM Customers AS c
JOIN Orders AS o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.Loyalty_Status
ORDER BY AOV DESC;


--- Q3. Which city/state has the highest number of customers and orders?
--City
SELECT c.City, 
       COUNT(DISTINCT c.Customer_ID) AS Cust_Count, 
       COUNT(DISTINCT o.Order_ID) AS Order_Count
FROM Customers c
LEFT JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.City
ORDER BY Cust_Count DESC,Order_Count DESC;

--State
SELECT c.State, 
       COUNT(DISTINCT c.Customer_ID) AS Cust_Count, 
       COUNT(DISTINCT o.Order_ID) AS Order_Count
FROM Customers c
LEFT JOIN Orders o
ON c.Customer_ID = o.Customer_ID
GROUP BY c.State
ORDER BY Cust_Count DESC,Order_Count DESC;

---Q4. How many repeat customers do we have, and what is the repeat purchase rate?
WITH Repeat_Customers AS (
    SELECT Customer_ID
    FROM Orders
    GROUP BY Customer_ID
    HAVING COUNT(Order_ID) > 1)

SELECT 
    (SELECT COUNT(*) FROM Repeat_Customers) AS Repeat_Customer_Count,
    CONCAT(CEILING((SELECT COUNT(*) FROM Repeat_Customers) * 100.0 / 
	COUNT(DISTINCT Customer_ID)),'%') AS Repeat_Purchase_Rate
FROM Orders; 

--- Sales & Revenue Insights
---Q5.What is the total revenue generated per month, and what are the peak sales months?

SELECT * FROM Orders;
 
SELECT YEAR(Shipping_Date) AS Year_Extracted,
       MONTH(Shipping_Date) AS Month_Extracted,
       FORMAT(Shipping_Date, 'MMM') AS Month_Name,
       SUM(Total_Amount) AS Total_Revenue
FROM Orders
GROUP BY YEAR(Shipping_Date),
         MONTH(Shipping_Date),
		 FORMAT(Shipping_Date, 'MMM')
--ORDER BY Year_Extracted ASC, Month_Extracted ASC;
ORDER BY Total_Revenue DESC;

--Q6. Which product category contributes the most to total revenue?

select * from Orders;
select * from Products;

--M1
SELECT TOP 1 WITH TIES P.Category,SUM(O.Total_Amount) AS Total_Revenue
FROM Products P
JOIN Orders O
ON O.Product_Name = P.Product_Name
GROUP BY P.Category
ORDER BY Total_Revenue DESC;

--M2
WITH RevenueByCategory AS (
    SELECT 
        P.Category, 
        SUM(O.Total_Amount) AS Total_Revenue,
        RANK() OVER (ORDER BY SUM(O.Total_Amount) DESC) AS RankOrder
    FROM Products P
    JOIN Orders O ON O.Product_Name = P.Product_Name
    GROUP BY P.Category
)
SELECT Category, Total_Revenue
FROM RevenueByCategory
WHERE RankOrder = 1;

--Q7. What are the top 5 best-selling and least-selling products?
SELECT * FROM Products;
SELECT * FROM Orders;

-- TOP 5 Best selling products
SELECT * FROM Products;
SELECT * FROM Orders;

SELECT TOP 5 p.Product_Name,SUM(o.Quantity) AS best_selling
FROM Products p
LEFT JOIN Orders o
ON o.Product_Name = p.Product_Name
Group by p.Product_Name
ORDER BY best_selling DESC;

--First 5 Least selling produucts
SELECT TOP 5 p.Product_Name,SUM(o.Quantity) AS least_selling
FROM Products p
LEFT JOIN Orders o
ON o.Product_Name = p.Product_Name
Group by p.Product_Name
ORDER BY least_selling ASC;

--Q8. Which payment method is most frequently used by customers?
SELECT * FROM Orders;

SELECT --TOP 1 WITH TIES
      Payment_Method, COUNT(*) as pay_COUNT
FROM Orders
GROUP BY Payment_Method
ORDER BY pay_COUNT DESC;

--Order & Delivery Performance

--Q9. What is the average delivery time for orders, and which regions experience the most delays?
SELECT * FROM Orders;
SELECT * FROM Customers;

SELECT c.City, AVG(DATEDIFF(DAY,o.Order_Date, o.Shipping_Date)) AS Dilivery_Time
FROM Orders AS o
JOIN Customers AS c 
ON o.Customer_ID = c.Customer_ID
WHERE o.Order_Status = 'Delivered' 
GROUP BY c.City
ORDER BY Dilivery_Time DESC;

--Q10.What percentage of orders are getting canceled, and what are the common reasons?

SELECT * FROM Orders;

SELECT Order_Status ,COUNT(*) AS StatusWiseCount, (SELECT COUNT(*) FROM Orders) AS TotalCount
FROM Orders 
GROUP BY Order_Status
ORDER BY StatusWiseCount DESC;

-- M1
WITH ORDER_COUNT AS (
    SELECT 
        COUNT(*) AS Total_Orders,
        SUM(CASE WHEN Order_Status = 'Cancelled' THEN 1 ELSE 0 END) AS Canceled_Orders
    FROM Orders
)
SELECT 
    CONCAT(ROUND((CAST(Canceled_Orders AS FLOAT) / Total_Orders) * 100,1), '%') AS Cancelation_Percentage
FROM ORDER_COUNT;


--Q11.Which suppliers are providing the best-selling and highest-rated products?

SELECT p.Supplier AS Supplier_Name,p.Ratings_Avg AS Best_Ratings, sum(o.Total_Amount) as Total_Selling
FROM Products p 
join Orders o ON o.Product_Name = p.Product_Name
where p.Ratings_Avg = 5
GROUP BY p.Supplier,p.Ratings_Avg
ORDER BY Total_Selling DESC;