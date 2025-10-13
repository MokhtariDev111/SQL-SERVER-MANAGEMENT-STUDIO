---------------------------------------------------------------------------------------------
--DATA EXPLORATION 
---------------------------------------------------------------------------------------------
--tables
select 
table_catalog,
table_schema,
table_name,
table_type
from INFORMATION_SCHEMA.TABLES; 

--table:
select 
column_name,
data_type,
is_nullable,
CHARACTER_MAXIMUM_LENGTH
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='dim_customers'
---------------------------------------------------------------------------------------------
--DIMENSION EXPLORATION
---------------------------------------------------------------------------------------------

-- Retrieve a list of unique countries from which customers originate
select distinct(country) countries 
from gold.dim_customers order by countries

-- Retrieve a list of unique categories, subcategories, and products
SELECT DISTINCT product_name, category, subcategory
FROM gold.dim_products;
 

 --how many category , subcategories and products
 with X as (
 SELECT DISTINCT product_name, category, subcategory
FROM gold.dim_products)
select COUNT(*) numbers_of_cat_subcat_prod from X 
---------------------------------------------------------------------------------------------
--DATE EXPLORATION 
---------------------------------------------------------------------------------------------
 -- Determine the first and last order date and the total duration in months
 select 
 MIN(order_date) as first_dater,
 MAX(order_date) as last_dater,
 DATEDIFF(month, MIN(order_date),MAX(order_date)) as range_diff from gold.fact_sales


 -- Determine the first and last order date and the total duration in months
 -- for a specific customer
create function gold.fn_order_duration (@customer_name nvarchar(50))
returns table
as
return
(
    select 
        concat(c.first_name, ' ', c.last_name) as full_name,
        min(s.order_date) as first_date,
        max(s.order_date) as last_date,
        datediff(month, min(s.order_date), max(s.order_date)) as total_duration_months
    from gold.dim_customers c
    join gold.fact_sales s
        on c.customer_key = s.customer_key
    where lower(concat(c.first_name, ' ', c.last_name)) = lower(@customer_name)
    group by concat(c.first_name, ' ', c.last_name)
);
go
select * from gold.fn_order_duration('tamara liang');


 -- Find the youngest and oldest customer based on birthdate 
select
    min(birthdate) as oldest_birthdate,
    datediff(year, min(birthdate), getdate()) as oldest_age,
    max(birthdate) as youngest_birthdate,
    datediff(year, max(birthdate), getdate()) as youngest_age
from gold.dim_customers;

---------------------------------------------------------------------------------------------
--MEASURES EXPLORATION
---------------------------------------------------------------------------------------------
-- Find the Total Sales
select SUM(sales_amount) as total_sales from gold.fact_sales

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales

-- Find the average selling price
SELECT AVG(price) AS avg_price FROM gold.fact_sales

-- Find the Total number of Orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales

-- Find the total number of products
SELECT COUNT(product_name) AS total_products FROM gold.dim_products

-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;

-- Generate a Report that shows all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;
---------------------------------------------------------------------------------------------
--Magnitude Analysis : data distribution across categories.
---------------------------------------------------------------------------------------------
-- Find total customers by countries
 select 
  country ,
 count(*) as total_customer
 from gold.dim_customers
 group by country 
 order by total_customer desc 

-- Find total customers by gender
  select 
  gender,
 count(*) as total_customer
 from gold.dim_customers
 group by gender 
 order by total_customer desc 

-- Find total products by category
  select 
  category,
 count(*) as total_product
 from gold.dim_products
 group by category
 order by total_product desc 

-- What is the average costs in each category?
   select 
   category,
  AVG(cost) average_cost
 from gold.dim_products
 group by category
 order by average_cost desc


 -- What is the total revenu generated for each category?
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
 JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
 
 


-- What is the total revenue generated by each customer?
 select
    c.customer_key,
    c.first_name,
    c.last_name,
    sum(f.sales_amount) as total_revenue
from gold.fact_sales f
left join gold.dim_customers c
    on c.customer_key = f.customer_key
group by 
    c.customer_key,
    c.first_name,
    c.last_name
order by total_revenue desc;

-- What is the distribution of sold items across countries?
 select
    c.country,
    sum(f.quantity) as total_sold_items
from gold.fact_sales f
left join gold.dim_customers c
    on c.customer_key = f.customer_key
group by c.country
order by total_sold_items desc;
---------------------------------------------------------------------------
--Ranking Analysis : rank items (e.g., products, customers) based on performance or other metrics.
---------------------------------------------------------------------------
-- Which 5 products Generating the Highest Revenue?
-- Simple Ranking
select top 5
s.product_key,
(select product_name from gold.dim_products p where p.product_key=s.product_key ) product_name,
SUM(sales_amount)  as total_sales
from gold.fact_sales s 
group by product_key
order by total_sales desc 
  

-- Complex but Flexibly Ranking Using Window Functions
 with top_5 as (
select s.product_key,p.product_name,SUM(sales_amount) as total_sales,
RANK() over(order by SUM(sales_amount)  desc) as ranking
from gold.dim_products p 
join gold.fact_sales s 
on p.product_key=s.product_key
group by s.product_key,p.product_name
)
select *  from top_5 where ranking <=5

-- What are the 5 worst-performing products in terms of sales?
 select top 5
s.product_key,
(select product_name from gold.dim_products p where p.product_key=s.product_key ) product_name,
SUM(sales_amount)  as total_sales
from gold.fact_sales s 
group by product_key
order by total_sales asc 

-- Find the top 10 customers who have generated the highest revenue
select top 10 
c.customer_key,CONCAT(c.first_name,' ' , c.last_name)  full_name,SUM(sales_amount) as total_sales
from gold.dim_customers c join gold.fact_sales s on c.customer_key=s.customer_key
group by c.customer_key,CONCAT(c.first_name,' ' , c.last_name)
order by total_sales desc 

-- The 3 customers with the fewest orders placed
 select top 3 
 customer_key , COUNT (distinct order_number) as total_orders from gold.fact_sales
 group by customer_key 
 order by total_orders 



 SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
INNER JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders;

/*
Change Over Time Analysis : measure growth or decline over specific periods, track trends
*/

-- Analyse sales performance over time
--saleSover time 
select order_date, sales_amount from gold.fact_sales
where order_date is not null 
order by order_date

select order_date, sum(sales_amount) as total_sales from gold.fact_sales
where order_date is not null 
group by order_date
order by order_date --granularity on the day level

-- year()
select 
YEAR(order_date) as yearly , sum(sales_amount) as total_sales from gold.fact_sales
where order_date is not null 
group by  YEAR(order_date)
order by yearly --granularity on year level

--best year
select top 1 yearly 
from (select 
YEAR(order_date) as yearly , sum(sales_amount) as total_sales 
from gold.fact_sales
where order_date is not null 
group by  YEAR(order_date)) as best_sales
order by total_sales desc --granularity on year level)


-- best year , worst year ,  gaining customer ? quantity sold 
select 
YEAR(order_date) as yearly ,
sum(sales_amount) as total_sales ,
COUNT(distinct customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by  YEAR(order_date)
order by yearly --granularity on year level


select 
YEAR(order_date) as yearly ,
MONTH(order_date)as monthly,
sum(sales_amount) as total_sales ,
COUNT(distinct customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by  YEAR(order_date),MONTH(order_date)
order by yearly,monthly


select 
DATETRUNC(MONTH,order_date) as order_date,
sum(sales_amount) as total_sales ,
COUNT(distinct customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by  DATETRUNC(MONTH,order_date)
order by DATETRUNC(MONTH,order_date)

--format 
select 
format(order_date,'yyyy-MMM') as order_date,
sum(sales_amount) as total_sales ,
COUNT(distinct customer_key) as total_customers,
SUM(quantity) as total_quantity
from gold.fact_sales
where order_date is not null 
group by  format(order_date,'yyyy-MMM')
order by format(order_date,'yyyy-MMM')

--cumulative analysis:aggregate the data progressively over time ( how the business is grouwing )
--total sales for each month 
select 
DATETRUNC(MONTH,order_date) as sales_by_month, --monthly
SUM(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by DATETRUNC(MONTH,order_date) 
order by DATETRUNC(MONTH,order_date)

with M as (
select
DATETRUNC(MONTH,order_date) as sales_by_month,
SUM(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by DATETRUNC(MONTH,order_date) 
)
select * , SUM(total_sales) over (order by sales_by_month) AS running_total from M
--select * , SUM(total_sales) over (partition by sales_by_month order by sales_by_month) AS running_total from Y

--granularity year 
WITH S AS (
    SELECT
        DATETRUNC(YEAR, order_date) AS sales_by_year,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(YEAR, order_date)
)
SELECT 
    *,
    SUM(total_sales) OVER (ORDER BY sales_by_year) AS running_total
FROM S
ORDER BY sales_by_year;
------------
WITH S AS (
    SELECT
        DATETRUNC(YEAR, order_date) AS sales_by_year,
        SUM(sales_amount) AS total_sales,
		AVG(sales_amount) as avg_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(YEAR, order_date)
)
SELECT 
    *,
    SUM(total_sales) OVER (ORDER BY sales_by_year) AS running_total,
	SUM(avg_sales) over (order by sales_by_year) as running_avg
FROM S
ORDER BY sales_by_year;

-------------------------
--performance analysis
--------------------------
with yearly_product_sales as (
select  
year(order_date) as order_year,
p.product_name ,
sum(f.sales_amount) as current_sales
from gold.fact_sales f 
left join gold.dim_products p 
on f.product_key=p.product_key 
where order_date is not null
group by year(order_date),p.product_name)

select 
order_year,
product_name,
current_sales,
AVG(current_sales) over(partition by product_name) as average,
AVG(current_sales) over(partition by product_name)-current_sales  as differences,
case 
	when AVG(current_sales) over(partition by product_name)-current_sales >0 then 'above avg'
	when AVG(current_sales) over(partition by product_name)-current_sales <0 then 'below_avg'
	else 'avg'
	end avg_change,
	LAG(current_sales) over(partition by product_name order by order_year) as prv_year_sales,
	current_sales-LAG(current_sales) over(partition by product_name order by order_year) as diff_prv_year_sales,
	case 
	when current_sales-LAG(current_sales) over(partition by product_name order by order_year)>0 then 'Increase'
	when current_sales-LAG(current_sales) over(partition by product_name order by order_year)<0 then 'decrease'
	else 'no change'
	end py_change
from yearly_product_sales
order by product_name , order_year

/*
part to whole analyze: how an individual category is performaing compared to overall
which category has the the greatest impact on the business (donut chart)
*/

--which categories contribute the most to overall sales ?
with Z as (
select 
category,
sum(sales_amount) as total_sales
from gold.dim_products p 
join gold.fact_sales s
on  p.product_key = s.product_key
group by category
)
select * ,concat(round(cast(total_sales*100.0/ SUM(total_sales) over() AS float),2),' %') as pourcentage
from Z 
--majority:bike

----------------------------------------
--data segmentation
----------------------------------------
--segment products into cost ranges and count how many products fall into each segment
select product_key , product_name , cost ,
case when cost<100 then 'belo< 100'
	when cost between 100 and 500 then '100-500'
	when cost between 500 and 1000 then '500-1000'
	else 'above 1000'
end cost_range
from gold.dim_products



with product_seg as (select product_key , product_name , cost ,
case when cost<100 then 'below < 100'
	when cost between 100 and 500 then '100-500'
	when cost between 500 and 1000 then '500-1000'
	else 'above 1000'
end cost_range
from gold.dim_products)
select cost_range,COUNT(product_key) as total_products
from product_seg 
group by cost_range
order by total_products desc 

/*group customers based on their spending behavior
VIP: at least 12 months of history and spending more than 5000
REGULAR:at least 12 months of history but spending 50100 or less
new:lifespan less than 12 months 
*/

 

select c.customer_key,SUM(sales_amount) total_sales, DATEDIFF(month,MIN(order_date),max(order_date)) lifespan,
case 
	when DATEDIFF(month,MIN(order_date),max(order_date)) >= 12 and SUM(sales_amount)>5000 then 'vip'
	when DATEDIFF(month,MIN(order_date),max(order_date)) >= 12 and SUM(sales_amount)<=5000 then 'regular'
	else 'new'
	end cust_type

from gold.dim_customers c 
right join gold.fact_sales s 
on  c.customer_key=s.customer_key
group by c.customer_key
order by customer_key ,cust_type


with customer_seg as 
(select c.customer_key,SUM(sales_amount) total_sales, DATEDIFF(month,MIN(order_date),max(order_date)) lifespan,
case 
	when DATEDIFF(month,MIN(order_date),max(order_date)) >= 12 and SUM(sales_amount)>5000 then 'vip'
	when DATEDIFF(month,MIN(order_date),max(order_date)) >= 12 and SUM(sales_amount)<=5000 then 'regular'
	else 'new'
	end cust_type

from gold.dim_customers c 
right join gold.fact_sales s 
on  c.customer_key=s.customer_key
group by c.customer_key

) 
select COUNT(*) nmbr,cust_type from customer_seg group by cust_type

--------------------------------------------------



