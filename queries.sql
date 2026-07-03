select * from city;
select * from customers;
select * from products;
select * from sales;


-- 1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name, 
round(population * 0.25)/1000000 as estimated_coffee_consumers, city_rank
from city ;


-- 2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select c.city_name, sum(s.total) as final_revenue
from sales as s
INNER JOIN customers as cu
on s.customer_id = cu.customer_id 
inner join city as c  
on c.city_id = cu.city_id
where
extract (year from s.sale_date) = 2023
and extract (quarter from s.sale_date) = 4
group by c.city_name
order by final_revenue desc;

--3 Sales Count for Each Product
--How many units of each coffee product have been sold?

select p.product_id , p.product_name, sum(s.total) as total_sold, count(s.customer_id) as customers, 
count(s.sale_id) as quantity_sold  
from products as p
inner join sales as s
on p.product_id = s.product_id
group by p.product_id , p.product_name 
order by 5 desc;


-- 4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?


select  c.city_name, count(distinct s.customer_id) as total_customers, sum(s.total) as total_sales, 
sum(s.total) / count(distinct s.customer_id) as average_sale_per_customer
from sales as s
INNER JOIN customers as cu
on s.customer_id = cu.customer_id 
inner join city as c  
on c.city_id = cu.city_id
group by c.city_name
order by average_sale_per_customer desc;


-- 5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.

select c.city_name,
round((c.population * 0.25)/1000000,2) as estimated_coffee_consumers, 
count(cu.city_id) as customers_in_city
from city as c 
inner join customers as cu
on c.city_id  = cu.city_id
group by c.city_name, c.population
order by c.city_name;


-- 6 Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?

with desire as (
select p.product_name, c.city_name, sum(s.total) as sales_volume
from sales as s
inner join products as p
on s.product_id = p.product_id
inner join customers as cu
on s.customer_id = cu.customer_id
inner join city as c
on cu.city_id = c.city_id
group by c.city_name, p.product_name
order by c.city_name desc
)

select * from (
select * ,
rank() over ( partition by city_name order by sales_volume desc ) as ranks
from desire 
) where ranks <=3;

--7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products

select c.city_name, count(distinct s.customer_id) as unique_customers
from sales as s
inner join products as p
on s.product_id = p.product_id
inner join customers as cu
on s.customer_id = cu.customer_id
inner join city as c
on cu.city_id = c.city_id
where p.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14) --even without where clasue the result will be same.
group by c.city_name;


--8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

with avg_table as (
select c.city_name, c.estimated_rent as rent, sum(s.total) as total_sales, count(distinct s.customer_id) as total_customers
from sales as s
inner join products as p
on s.product_id = p.product_id
inner join customers as cu
on s.customer_id = cu.customer_id
inner join city as c
on cu.city_id = c.city_id
group by c.city_name, c.estimated_rent

)

select *  from ( select city_name, round((total_sales / total_customers)::numeric,3) as average_sale_per_customer, 
round((rent/total_customers)::numeric,3) as average_rent_per_customer  -- round cant  be used between double precision and integer so, it needed to be converted to inetger first
from avg_table
)

-- 9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

with temp as (
select
c.city_name as city,
extract(year from s.sale_date) as year,
extract(month from s.sale_date) as month,
sum(s.total) as monthly_sales
from sales as s
inner join customers as cu
on s.customer_id = cu.customer_id
inner join city as c
on cu.city_id = c.city_id
group by c.city_name,
extract(year from s.sale_date),
extract(month from s.sale_date)
),

temp1 as (
select
city,
year,
month,
monthly_sales,
lag(monthly_sales) over(partition by city order by year, month) as previous_month_sales
from temp
)

select
city,
year,
month,
monthly_sales,
previous_month_sales,
case
when previous_month_sales is null then null
else round((((monthly_sales - previous_month_sales) * 100.0) / previous_month_sales)::numeric,2)::text || '%'
end as growth_rate
from temp1
order by city, year, month;


-- 10 Market Potential Analysis
/* Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, 
estimated coffee consumer */




with avg_table as (
select c.city_name, c.estimated_rent as rent, sum(s.total) as total_sales, count(distinct s.customer_id) as total_customers,
c.population as population
from sales as s
inner join customers as cu
on s.customer_id = cu.customer_id
inner join city as c
on cu.city_id = c.city_id
group by c.city_name, c.estimated_rent, c.population

)

select *  from ( select city_name, total_sales, rent,total_customers, 
round((total_sales / total_customers)::numeric,3) as average_sale_per_customer, 
round((rent/total_customers)::numeric,3) as average_rent_per_customer,  
round((population * 0.25)/1000000,2) as estimated_coffee_consumers,
rank() over (  order by total_sales desc ) as ranks
from avg_table 
)



