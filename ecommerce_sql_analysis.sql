-- CREATING DATABASE
create database ecommerce_project;

-- SELECTING DATABASE
use ecommerce_project;

-- CREATE TABLE
CREATE TABLE ecommerce_orders (
    OrderID         VARCHAR(20)     PRIMARY KEY,
    Date            DATE            NOT NULL,
    CustomerID      VARCHAR(20)     NOT NULL,
    Product         VARCHAR(50)     NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10,2)   NOT NULL,
    ShippingAddress VARCHAR(100),
    PaymentMethod   VARCHAR(30),
    OrderStatus     VARCHAR(30),
    TrackingNumber  VARCHAR(30),
    ItemsInCart     INT,
    CouponCode      VARCHAR(20)     DEFAULT 'NO COUPON',
    ReferralSource  VARCHAR(30),
    TotalPrice      DECIMAL(10,2)   NOT NULL
);

-- Imported the dataset through Table Data Import Wizard in .csv format
select * from ecommerce_orders limit 10;
/*
What does the dataset contain?
Row count, date range, distinct products, unique customers 
*/

select count(*) as total_orders,
	min(date) as earliest_order,
	max(date) as latest_order,
	count(distinct product) as unique_products,
	count(distinct CustomerID) as unique_customers
 from ecommerce_orders;
 
 /*
 Is the data clean?
 Checking NULL values
 */
 
 SELECT
    SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS null_orderid,
    SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customerid,
    SUM(CASE WHEN Product IS NULL THEN 1 ELSE 0 END) AS null_product,
    SUM(CASE WHEN CouponCode IS NULL THEN 1 ELSE 0 END) AS null_coupon,
    SUM(CASE WHEN TotalPrice IS NULL THEN 1 ELSE 0 END) AS null_totalprice
FROM ecommerce_orders;
/*
What is the breakdown of order outcomes?
Order status in Percentage
*/

SELECT 
	orderstatus,
	count(*) as num_of_orders,
    round(count(*)*100/(select sum(count(*)) over() from ecommerce_orders),1) as percentage
from ecommerce_orders
	group by 
	orderstatus
    order by num_of_orders DESC;
    
-- REVENUE ANALYSIS
-- Overall business performance
-- Find total revenue, total number of orders and average order value.
Select 
sum(totalprice) as total_revenue,
count(*) as total_orders,
avg(totalprice) as average_order_value
from ecommerce_orders
where orderstatus NOT IN ('Cancelled','Returned');

-- Monthly revenue trend
-- Shows revenue, order count and average order value broken down by month.
select date_format(date,"%Y") as order_year,
date_format(date,"%m") as order_month,
sum(totalprice) as total_revenue,
round(avg(totalprice),2) as average_order_value,
count(*) as total_orders
from ecommerce_orders
where orderstatus NOT IN ('Cancelled','Returned')
group by order_year,order_month
order by order_year,order_month ASC;

-- Year over year comparison
-- Compare total orders, total revenue and average order value across 2023, 2024 and 2025.
select year(date) as order_year,
sum(totalprice) as total_revenue,
round(avg(totalprice),2) as average_order_value,
count(*) as total_orders
 from ecommerce_orders
 where orderstatus NOT IN ("Cancelled","Returned")
 group by order_year
 order by order_year;
 
-- Quarterly revenue
-- Break revenue down by quarter across all years.
select sum(totalprice) as total_revenue,
year(date) as order_year,
quarter(date) as order_quarter
from ecommerce_orders
where orderstatus NOT IN ("Cancelled","Returned")
group by order_year,order_quarter
order by order_year,order_quarter;

-- Product Analysis
-- Revenue and units sold by product.Show each product's total revenue and total units sold, ordered by highest revenue first.
select count(quantity) as units_sold,product,
sum(totalprice) as product_revenue
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by product
order by product_revenue DESC;

-- Average order value by product
-- Show the average order value for each product, highest first.
select product,avg(totalprice) as average_revenue,
count(orderid) as total_orders
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by product
order by average_revenue DESC;

-- Cancellation and return rate by product
-- For each product show total orders, number of cancellations, number of returns and their respective rates as percentages.
select product ,count(orderid) as total_orders,
round(sum(case when orderstatus = "Cancelled" then 1 else 0 END)*100/
(count(orderid)),1) as Order_cancelled_percent,
round(sum(case when orderstatus="Returned" then 1 else 0 END)*100/
(count(orderid)),1) as Order_returned_percent
from ecommerce_orders
group by product;

-- Best selling product per month
-- Show which product sold the most units each month.

with monthly_product_sales AS
(
select product,
date_format(date,"%Y %m") as order_yearmonth,
-- date_format(date,"%m") as order_month,
sum(quantity) as units_sold
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by product,order_yearmonth
order by units_sold DESC
),
max_units_per_month AS
(
select order_yearmonth,max(units_sold) as max_units
from monthly_product_sales
group by order_yearmonth
)
select m.product,m.order_yearmonth,m.units_sold
from monthly_product_sales m
join max_units_per_month mx
on m.order_yearmonth=mx.order_yearmonth
AND m.units_sold=mx.max_units
Order BY m.order_yearmonth;

-- Customer & Marketing
-- Orders and revenue by referral source
-- Show each referral source with total orders, total revenue and number of unique customers, ordered by highest revenue first.
select count(distinct customerid) as unique_customers,
referralsource,
count(*) as total_orders,
sum(totalprice) as total_revenue
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by ReferralSource
order by total_revenue DESC;

-- Average order value by referral source
-- Which referral source brings in the highest value customers on average?

select round(avg(totalprice),2) as average_order_value,
referralsource from ecommerce_orders
where orderstatus NOT IN ("Cancelled","Returned")
group by ReferralSource 
order by average_order_value DESC;

-- Coupon usage comparison
-- Compare orders that used a coupon vs those that didn't. Show order count, total revenue and average order value for each group.
select count(*) as order_count,
sum(totalprice) as total_revenue, 
round(avg(totalprice),2) as average_order_value,
case when CouponCode="NO COUPON" then "No Coupon used"
else "Coupon used"
end as coupon_usage
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by coupon_usage;

-- Performance of each coupon code
-- Show each coupon code with order count and average order value. Exclude 'NO COUPON' rows this time.

select couponcode,
count(*) as order_count,
round(avg(totalprice),2) as average_order_value
from ecommerce_orders
where couponcode<>"NO COUPON"
AND orderstatus NOT IN ("Cancelled","Returned")
group by couponcode
order by order_count DESC;

-- Query 16 — Payment method distribution
-- Show each payment method with order count, total revenue and percentage share of total orders.
select paymentmethod,
count(*) as order_count,
sum(totalprice) as total_revenue,
round(count(*)*100/sum(count(*)) over(),1) as percentage_share
from ecommerce_orders
where OrderStatus NOT IN("Returned","Cancelled")
group by paymentmethod
order by order_count DESC;

-- Running total of monthly revenue
-- Show each month with its revenue AND a cumulative running total that keeps adding up month by month.

With monthly_revenue as
(
select sum(totalprice) as total_revenue,
date_format(date,"%Y") as order_year,
date_format(date,"%m") as order_month
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by order_year,order_month
)
select total_revenue,order_year,order_month,
sum(total_revenue) over(order by order_year,order_month) as running_total
from monthly_revenue;

-- Rank products by revenue
-- Show each product with its total revenue and a rank, where rank 1 is the highest revenue product.

select product,
sum(totalprice) as total_revenue,
rank() over(order by sum(TotalPrice) DESC) as ranking
from ecommerce_orders
where OrderStatus NOT IN("Cancelled","Returned")
group by product;

-- Month over month revenue change
-- Show each month, its revenue, the previous month's revenue and the difference between them.
select sum(totalprice) as total_revenue,
date_format(date,"%Y") as order_year,
date_format(date,"%m") as order_month,
lag(sum(totalprice)) over(order by date_format(date,"%Y") ASC,date_format(date,"%m") ASC) as previous_month_revenue,
sum(totalprice)-lag(sum(totalprice)) over(order by date_format(date,"%Y"),date_format(date,"%m") ASC) as revenue_difference
from ecommerce_orders
where orderstatus NOT IN("Cancelled","Returned")
group by order_year,order_month;

-- Customer purchase frequency
-- Categorise customers as:
/*One-time buyer — ordered only once
Occasional buyer — ordered 2 to 3 times
Loyal buyer — ordered 4 or more times
Show the count of customers and average lifetime value in each category*/

WITH Buyer AS
(
select customerid,
count(*) as Number_of_purchases,
sum(TotalPrice) as lifetime_value from ecommerce_orders
where OrderStatus NOT IN ("Cancelled","Returned")
group by customerid
)
select 
case 
when Number_of_purchases=1 then "One-time buyer"
when Number_of_purchases between 2 AND 3 then "Occasional buyer"
when Number_of_purchases >=4 then "Local buyer"
END as purchase_category,
count(customerid) as num_of_customers,
round(avg(lifetime_value),2) as average_lifetime_value
from Buyer
group by purchase_category;



























































    
