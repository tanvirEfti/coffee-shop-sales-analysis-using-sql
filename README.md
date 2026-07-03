# ☕ coffee shop sales analysis using sql

> a real-world sql project that transforms coffee shop sales data into actionable business insights using postgresql.

<p align="center">
  <img src="https://raw.githubusercontent.com/tanvirEfti/coffee-shop-sales-analysis-using-sql/main/Gemini_Generated_Image_w0nm3jw0nm3jw0nm.png" width="900">
</p>


---

## 📖 project overview

this project focuses on analyzing a coffee shop sales dataset using **postgresql** to solve real-world business problems. by writing analytical sql queries, the project uncovers insights related to customer behavior, product performance, sales trends, and market opportunities that can support business decision-making.

the project demonstrates practical use of sql for data analysis rather than simple data retrieval.

---

## 🛠️ tools used

- postgresql
- pgadmin 4
- sql

---

## 📂 dataset

the database consists of four relational tables:

| table | description |
|------|-------------|
| `city` | city information including population and estimated rent |
| `customers` | customer details and city mapping |
| `products` | coffee product information |
| `sales` | transaction records containing sales data |

---

# 📋 business questions solved

### 1. coffee consumers count
> how many people in each city are estimated to consume coffee, given that 25% of the population does?

```sql

select city_name, 
round(population * 0.25)/1000000 as estimated_coffee_consumers, city_rank
from city ;


```

### 2. total revenue from coffee sales
> what is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

```sql

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

```

### 3. sales count for each product
> how many units of each coffee product have been sold?

```sql

select p.product_id , p.product_name, sum(s.total) as total_sold, count(s.customer_id) as customers, 
count(s.sale_id) as quantity_sold  
from products as p
inner join sales as s
on p.product_id = s.product_id
group by p.product_id , p.product_name 
order by 5 desc;

```

### 4. average sales amount per city
> what is the average sales amount per customer in each city?

```sql

select  c.city_name, count(distinct s.customer_id) as total_customers, sum(s.total) as total_sales, 
sum(s.total) / count(distinct s.customer_id) as average_sale_per_customer
from sales as s
INNER JOIN customers as cu
on s.customer_id = cu.customer_id 
inner join city as c  
on c.city_id = cu.city_id
group by c.city_name
order by average_sale_per_customer desc;

```

### 5. city population and coffee consumers
> provide a list of cities along with their populations and estimated coffee consumers.

```sql

select c.city_name,
round((c.population * 0.25)/1000000,2) as estimated_coffee_consumers, 
count(cu.city_id) as customers_in_city
from city as c 
inner join customers as cu
on c.city_id  = cu.city_id
group by c.city_name, c.population
order by c.city_name;
```

### 6. top selling products by city
> what are the top 3 selling products in each city based on sales volume?

```sql

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


```

### 7. customer segmentation by city
> how many unique customers are there in each city who have purchased coffee products?

```sql

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


```

### 8. average sale vs rent
> find each city and their average sale per customer and average rent per customer.

```sql

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


```
### 9. monthly sales growth
> calculate the monthly sales growth (or decline) percentage over different time periods.

```sql
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
```
> 🚀 this was the most challenging query in the project and the one i'm most proud of. it combines ctes, window functions, and business calculations to analyze month-over-month sales growth.


### 10. market potential analysis
> identify the top 3 cities based on highest sales and return city name, total sales, total rent, total customers, average sale per customer, average rent per customer, and estimated coffee consumers.

```sql

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


```

# 📌 final business recommendations

based on the analysis of sales performance, customer spending, rental costs, customer distribution, and estimated coffee consumer population, the following business recommendations are proposed:

## 🥇 1. pune — highest priority for expansion

**why?**
- highest total sales among all cities.
- highest average sales per customer.
- relatively low average rent per customer.
- demonstrates strong revenue generation and excellent return on investment.

**recommendation:**
- prioritize opening additional outlets.
- increase marketing efforts to strengthen market presence.
- maintain inventory levels to meet growing demand.

---

## 🥈 2. delhi — highest growth potential

**why?**
- largest estimated coffee consumer market (7.75 million).
- one of the highest customer counts.
- reasonable average rent per customer.
- significant opportunity to capture a much larger customer base.

**recommendation:**
- invest in customer acquisition campaigns.
- strengthen brand awareness through targeted marketing.
- expand gradually to capitalize on the city's untapped market potential.

---

## 🥉 3. jaipur — cost-efficient expansion

**why?**
- highest number of unique customers.
- lowest average rent per customer.
- healthy average customer spending.
- offers an excellent balance between operating costs and customer demand.

**recommendation:**
- continue expanding while maintaining operational efficiency.
- focus on customer retention and loyalty programs.

---

## ⚠️ cities requiring operational improvement

### bangalore

- strong customer spending and good revenue.
- comparatively higher rental costs reduce overall efficiency.

**recommendation:**
- optimize operating costs before considering further expansion.

---

### chennai

- consistent sales performance and healthy customer spending.
- moderate rental costs.

**recommendation:**
- maintain current operations and continue monitoring growth trends.

---

### mumbai

- high estimated coffee consumer population.
- highest rental cost among all cities.
- comparatively lower sales performance.

**recommendation:**
- investigate operational inefficiencies and customer preferences before making additional investments.

---

# 📊 overall conclusion

this analysis indicates that **pune**, **delhi**, and **jaipur** provide the strongest opportunities for future investment based on a combination of revenue generation, customer engagement, rental efficiency, and market potential.

cities such as **bangalore** and **chennai** should continue normal operations while focusing on improving efficiency, whereas **mumbai** requires further business analysis to understand the gap between its large market potential and comparatively lower sales performance.

> **note:** these recommendations are based solely on the available sales, customer, rent, and population data. additional business metrics such as operating expenses, profit margins, employee costs, and customer satisfaction would be required before making strategic decisions such as closing existing stores.











# 🧠 sql concepts covered

- select
- where
- group by
- order by
- inner join
- aggregate functions
- count(distinct)
- common table expressions (ctes)
- window functions
  - rank()
  - lag()
- case
- extract()
- round()
- type casting
- business metric calculations

---

# 📈 business insights

- estimated coffee-consuming population across different cities.
- identified the highest revenue-generating cities.
- analyzed product-wise sales performance.
- compared customer spending across cities.
- ranked the best-selling products within each city.
- measured month-over-month sales growth.
- evaluated rental efficiency for each city.
- recommended the best cities for future coffee shop expansion.

---

# 📁 repository structure

```text
coffee-shop-sales-analysis-using-sql/
│
├── images/
│   └── banner.png
├── queries.sql
├── city.csv
├── customers.csv
├── products.csv
├── sales.csv
└── README.md
```

---

# 🚀 what i learned

through this project i strengthened my understanding of:

- writing analytical sql queries from scratch
- solving real-world business problems using sql
- working with relational databases
- using ctes to simplify complex queries
- applying window functions for ranking and trend analysis
- converting raw data into business insights

---

## Special Note

You may notice that some queries use a mix of uppercase and lowercase SQL keywords. While the formatting may not always be consistent, all queries were written and tested as part of my hands-on practice and learning process.
If you find any mistakes, bugs, or opportunities for improvement, please feel free to contact me or open an issue. Constructive feedback is always appreciated and helps me continue growing as a data analyst.

Thank you for checking out my project!

## Acknowledgments

Special thanks to ([Najir H.](https://github.com/najirh)) for providing the dataset and practice questions that inspired this project. All SQL solutions, analysis, documentation, and project implementation in this repository were completed independently as part of my learning journey.



## 👨‍💻 author

**Eftekhar Tanvir Efti**

if you found this project helpful, feel free to ⭐ the repository.

GitHub: https://github.com/tanvirEfti
LinkedIn: *(www.linkedin.com/in/eftekhar-tanvir-efti-1216843b1)*
