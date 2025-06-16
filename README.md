# 🍽️ Zomato Data Analysis Project (SQL)

This project is a comprehensive SQL-based data analysis of a hypothetical Zomato-like food delivery platform. It involves creating and populating several relational tables and performing insightful analytical queries to derive meaningful business insights such as customer behavior, restaurant performance, rider efficiency, and seasonal trends.

## 📁 Project Structure

- **Database**: `zomato_analysis`
- **Tables**:
  - `restaurant`
  - `orders`
  - `riders`
  - `customers`
  - `deliveries`

**Analytical Tables Created:**

- `restaurant_revenue`
- `most_popular_dish`
- `delivery_time`
- `gold_or_silver`
- `rider_earning`
- `rating`
- `frequency`
- `monthly_sales`, `total_monthly_sales`
- `average_time`, `rider_rank`
- `season_chart`
- `city_revenue`, `city_rank`

## ✅ Features & Insights

### 📊 Customer Insights

- Most frequently ordered dish by customer `Aman Gupta` in the last 2.5 years:
```sql
SELECT order_item, COUNT(order_item) AS count 
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.customer_id
WHERE customer_name = 'Aman Gupta' AND DATEDIFF(CURRENT_DATE, order_date) <= 913
GROUP BY 1 ORDER BY count DESC
LIMIT 1;
```

- Average order value for customers who placed more than 3 orders:
```sql
SELECT c.customer_name, o.customer_id, COUNT(o.customer_id), ROUND(AVG(total_amount), 2) 
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
GROUP BY 1,2
HAVING COUNT(o.customer_id) > 3
ORDER BY 1;
```

- Customers who spent more than ₹1000:
```sql
SELECT c.customer_name, o.customer_id, SUM(total_amount) 
FROM orders AS o
JOIN customers AS c ON o.customer_id = c.customer_id
GROUP BY 1,2
HAVING SUM(total_amount) > 1000;
```

- Customer segmentation: Gold (total > avg), Silver otherwise:
```sql
SELECT customer_id, SUM(total_amount) AS net_amount,
CASE 
  WHEN SUM(total_amount) > 331.7105 THEN 'Gold' 
  ELSE 'Silver' 
END AS category
FROM orders
GROUP BY 1;
```

### 🍽️ Restaurant Analysis

- Rank restaurants by revenue within each city:
```sql
SELECT rest_id, restaurant_name, city, total_revenue,
RANK() OVER (PARTITION BY city ORDER BY total_revenue DESC) AS city_rank
FROM restaurant_revenue;
```

- Cancellation rate by restaurant:
```sql
SELECT rest_id, restaurant_name,
COUNT(*) AS total_orders,
COUNT(CASE WHEN delivery_status = 'Not Delivered' THEN 1 END) AS cancelled_orders,
(COUNT(CASE WHEN delivery_status = 'Not Delivered' THEN 1 END) / COUNT(*)) * 100 AS cancel_percentage
FROM orders AS o
JOIN deliveries AS d ON o.order_id = d.order_id
JOIN restaurant AS r ON r.restaurant_id = o.rest_id
GROUP BY 1, 2;
```

- Most popular dish in each city:
```sql
SELECT order_item, city, item_count,
RANK() OVER (PARTITION BY city ORDER BY item_count DESC) AS rank_
FROM most_popular_dish;
```

### 🚴 Rider Performance

- Average delivery time per rider:
```sql
SELECT rider_id, rider_name, AVG(TIMESTAMPDIFF(MINUTE, delivery_time, order_time)) AS avg_delivery_time
FROM riders r
JOIN deliveries d ON r.rider_id = d.rider_id
JOIN orders o ON o.order_id = d.order_id
GROUP BY 1, 2;
```

- Rider earnings (8% of order amount):
```sql
SELECT rider_id, rider_name, current_month, 0.08 * SUM(total_amount) AS earnings
FROM rider_earning
GROUP BY 1,2,3;
```

- Rating riders:
```sql
SELECT rider_id, rider_name,
COUNT(CASE WHEN rating = '5' THEN 1 END) AS five_star,
COUNT(CASE WHEN rating = '4' THEN 1 END) AS four_star,
COUNT(CASE WHEN rating = '3' THEN 1 END) AS three_star
FROM rating
GROUP BY 1, 2;
```

- Highest and lowest average delivery time:
```sql
SELECT rider_name, average_time,
CASE 
  WHEN rank_ = 1 THEN 'highest'
  ELSE 'lowest'
END AS position
FROM rider_rank
WHERE rank_ = 1 OR rank_ = (SELECT MAX(rank_) FROM rider_rank);
```

### ⏱️ Time-Based & Seasonal Analysis

- Time slots with max orders:
```sql
SELECT start_time, end_time, COUNT(*) 
FROM slot
GROUP BY 1,2 ORDER BY COUNT(*) DESC;
```

- Monthly order frequency:
```sql
SELECT rest_id, DATE_FORMAT(order_date, '%b') AS month, COUNT(*) 
FROM orders
GROUP BY 1,2;
```

- Monthly sales comparison:
```sql
SELECT current_month, total_orders AS current_month_sales,
LAG(total_orders) OVER (ORDER BY FIELD(current_month,
  'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec')) AS previous_month_sales
FROM total_monthly_sales;
```

- Seasonal dish demand:
```sql
SELECT order_item, season, COUNT(*) 
FROM season_chart
GROUP BY 1,2
ORDER BY 1,3 DESC;
```

### 🏙️ City-Level Analysis

- City ranking by total revenue:
```sql
SELECT city, total_revenue,
RANK() OVER (ORDER BY total_revenue DESC) AS rank_
FROM city_rank;
```

## 🛠️ Tech Stack

- SQL (MySQL / MariaDB)
- Window Functions, Aggregate Functions, Date Functions
- Grouping & Joins
- Views and Derived Tables

## 🚀 How to Run

1. Create the database:
```sql
CREATE DATABASE zomato_analysis;
USE zomato_analysis;
```

2. Execute table creation and data insertion scripts.
3. Run the analysis queries to explore different insights.

## 📌 Future Enhancements

- Integrate with **Tableau** or **Power BI** for visualization.
- Automate ETL using Python and SQLAlchemy.
- Apply clustering for customer segmentation using ML.

## 🙌 Acknowledgements

This project is intended for educational purposes and to showcase SQL proficiency in real-world-like datasets.

## 📫 Contact

For feedback or suggestions:  
📧 rishabh.kapoor.ug22@nsut.ac.in 
https://github.com/rishabh2859
