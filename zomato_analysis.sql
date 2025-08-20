create database zomato_analysis;
use zomato_analysis;
drop table if exists restaurant;
CREATE TABLE restaurant (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    opening_hours VARCHAR(100) NOT NULL
);
drop table if exists orders;
create table orders(
order_id int primary key,	
customer_id	int ,
rest_id	int,
order_item	varchar(25),
order_date	date,
order_time	time,
order_status	varchar(25),
total_amount int
);
create table riders(
rider_id	int,
rider_name	varchar(25),
sign_up date
);
create table customers(
customer_id	int,
customer_name	varchar(25),
reg_date date
);
drop table if exists deliveries;
create table deliveries(
delivery_id	int primary key,
order_id	int,
delivery_status	varchar(25),
delivery_time	time,
rider_id int
);
alter table riders
add primary key(rider_id);
alter table customers
add primary key(customer_id);
alter table deliveries
add constraint fk_orders
foreign key (order_id)
references orders(order_id);
SET SQL_SAFE_UPDATES = 0;

delete from deliveries 
where order_id not in(select order_id from orders);

alter table orders
add constraint fk_customers
foreign key (customer_id)
references customers(customer_id);
alter table orders
add constraint fk_restaurant
foreign key (rest_id)
references restaurant(restaurant_id);
delete from orders
where rest_id not in(select restaurant_id from restaurant);
alter table deliveries
add constraint fk_riders
foreign key (rider_id)
references riders(rider_id);
#show the most frequently ordered dish by customer Amam gupta in last 2.5 year
select order_item,count(order_item) as count from customers as c
join orders as o
on o.customer_id=c.customer_id
where customer_name='Aman Gupta'
and datediff(current_date,order_date)<=913
group by 1 order by count(order_item) desc
limit 1;
#identify time slots during which maximum orders are placed
create table slot as(
select order_item,order_time,
floor(extract(hour from order_time)/2) as start_time,
floor(extract(hour from order_time)/2)+2 as end_time from orders);
select start_time,end_time,count(*)from slot
group by 1,2 order by count(*)desc;
#find average order value for customers who has placed more than 3 orders
select c.customer_name,o.customer_id,count(o.customer_id),round(avg(total_amount),2) from orders as o
join customers as c
on c.customer_id=o.customer_id
group by 1,2
having count(o.customer_id)>3
order by 1;
#List the customers who have spent more than 1k in total on food orders
select c.customer_name,o.customer_id,sum(total_amount) from orders as o
join customers as c
on o.customer_id=c.customer_id
group by 1,2
having sum(total_amount)>1000
order by 1;
#orders that were placed but not delivered return restaurant_name ,city and no.of not delivered orders
select o.order_id,order_item,d.delivery_status,restaurant_name,city ,rest_id,count(rest_id) from deliveries as d
 join orders as o
on d.order_id=o.order_id
join restaurant as r
on rest_id=restaurant_id
where delivery_status='Not Delivered'
group by 1,2,3,4,5,6
order by count(rest_id)desc;
#rank restaurant by their total revenues from last year including their name,total revenue 
#and rank  within their city
select * from restaurant;
create table restaurant_revenue as(
select  rest_id,restaurant_name,city,sum(total_amount)as total_revenue from orders as o
join restaurant as r
on rest_id=restaurant_id
group by 1,2,3 order by 3,4 desc);
select rest_id,restaurant_name,city,total_revenue,
rank() over(partition by city order by total_revenue desc)
from restaurant_revenue ;
#identify most popular dish in each city
drop table if exists most_popular_dish;
create table most_popular_dish as(
select order_item,city,count(order_item) as item_count from orders as o
join restaurant as r 
on rest_id=restaurant_id
group by 1,2
order by 2,count(order_item)desc);
select order_item,city,item_count,
rank() over(partition by city order by item_count desc) 
from
most_popular_dish;
#find cancellation rate of each restaurant
select rest_id,restaurant_name,count(rest_id) as total_count,count(case when delivery_status='Not delivered' then 1 end) as cancelled_count,
(count(case when delivery_status='Not delivered' then 1 end)/count(rest_id) )*100 as cancelled_percentage from orders as o
join deliveries as d
on d.order_id=o.order_id
join restaurant as r
on rest_id=restaurant_id
group by 1,2 ;
#find each riders average delivery time
drop table if exists delivery_time;
create table delivery_time as(
select r.rider_id,rider_name,order_time,delivery_time,timestampdiff(minute,delivery_time, order_time) as time_taken from riders as r
join deliveries as d
on d.rider_id=r.rider_id
join orders as o
on o.order_id=d.order_id);
select * from orders;
#find monthwise number of orders
select rest_id,DATE_FORMAT(order_date, '%b') as current_month,count(rest_id) from  orders as o
join restaurant as r
on rest_id=restaurant_id
group by 1,2 order by 1;
#seggregate customers into gold and silver 1)gold-if placed order>avg value 2)silver otherwise 
#display each category total orders and total revenue
select avg(total_amount) as avg_value from orders;
drop table if exists gold_or_silver;
create table gold_or_silver as(
select customer_id,sum(total_amount) as customer_revenue,count(customer_id) as customer_order_count ,case when sum(total_amount)>331.7105 then 'Gold' else 'Silver' end as category from orders
group by 1);
select category,sum(customer_order_count) as total_count,sum(customer_revenue) as total_sales from gold_or_silver
group by 1;
#calculate each riders monthly earnings assumming they earn 8% of order amount
create table rider_earning as(
select r.rider_id,rider_name,DATE_FORMAT(order_date, '%b') as current_month,total_amount from riders as r
join deliveries as d
on r.rider_id=d.rider_id
join orders as o
on d.order_id=o.order_id
where delivery_status='Delivered'
order by 1);
select rider_id,rider_name,current_month,(0.08*sum(total_amount)) from rider_earning
group by 1,2,3 order by 1;
# find no. of 5 star , 4 star and 3 star rating each rider has 5-<150minutes delivery time 4-150-200 and 3->200 minutes
select * from delivery_time;
create table rating as(
select rider_id,rider_name,time_taken,case when time_taken<150 then '5' when time_taken between 150 and 200 then '4' else '3' end as rating from delivery_time
group by 1,2,3 order by 1);
select rider_id,rider_name,count(case when rating='5'then 1 end) as five_star ,count(case when rating='4' then 1 end) as four_star ,
count(case when rating ='3' then 1 end) as three_star from rating group by 1,2 order by 1;
#analyze order frequency per day of the week and identify peak day of each restaurant
select * from orders;
CREATE TABLE frequency AS
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    o.order_id,
    o.order_date,
    DAYNAME(o.order_date) AS order_day
FROM restaurant r
JOIN orders o
    ON r.rest_id = o.restaurant_id;

SELECT
    restaurant_id,
    restaurant_name,
    order_day,
    COUNT(order_id) AS frequency,
    RANK() OVER (
        PARTITION BY restaurant_id
        ORDER BY COUNT(order_id) DESC
    ) AS day_rank
FROM frequency
GROUP BY restaurant_id, restaurant_name, order_day
ORDER BY restaurant_id, day_rank;

#calculate total revenue generated by each customer
select * from gold_or_silver;
select g.customer_id,net_amount , customer_name from gold_or_silver as g
join customers as c
on c.customer_id=g.customer_id;
#identify sales trends by comparing current month sales to previous month sales
create table monthly_sales as(
select rest_id,DATE_FORMAT(order_date, '%b') as current_month,count(rest_id) as frequency from  orders as o
join restaurant as r
on rest_id=restaurant_id
group by 1,2 order by 1);
create table total_monthly_sales as(
select current_month,sum(frequency) as total_orders from monthly_sales
group by 1 order by FIELD(current_month, 
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec') );
  select current_month,total_orders as current_month_sales, lag(total_orders) over(order by FIELD(current_month, 
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')) as previous_month_sales from total_monthly_sales;
  #identify riders with highest and lowest average delivery times
  create table average_time as(
  select rider_name,avg(time_taken) as average_time from delivery_time
  group by 1 order by 1);
  create table rider_rank as (
select rider_name,average_time,rank() over(order by average_time) as rank_ from average_time);
select rider_name,average_time,case when rank_=1 then 'highest' else 'lowest' end as position from rider_rank where rank_=1 or rank_=14;
#make a seasonal demand chart of each order_item
create table season_chart as(
select order_item,extract(month from order_date) as order_month,case when extract(month from order_date)  between 3 and 4 then 'spring'
when extract(month from order_date ) between 5 and 9 then 'summer' when extract(month from order_date )= 10 then 'autumn' else 'winter' end as season from  orders group by 1,2,3 order by 1,2 desc);
select order_item,season,count(season) from season_chart
group by 1,2 order by 1,3 desc;
#Rank each city based on revenue
create table city_revenue as(
select order_item,total_amount,city from orders as o
join restaurant as r
on rest_id=restaurant_id
group by 1,2,3 order by 3);
create table city_rank as(
select city,sum(total_amount) as total_revenue from city_revenue group by 1);
select city,total_revenue,rank() over(order by total_revenue desc) as rank_ from city_rank;

