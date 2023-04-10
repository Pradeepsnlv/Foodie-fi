-- creating database--
CREATE DATABASE foodie_fi;
use foodie_fi;

-- Creating Table--

CREATE TABLE Plans (Plan_id   INT NOT NULL,
					Plan_name VARCHAR(15) NOT NULL ,
                    Price     FLOAT,
                    PRIMARY KEY(Plan_id));
                    
CREATE TABLE subscriptions (customer_id INT NOT NULL,
                            plan_id     INT NOT NULL,
                            start_date DATE NOT NULL,
                            FOREIGN KEY(plan_id) REFERENCES
                            plans(plan_id));
                            
                            
-- Inserting rows into plans table--

INSERT INTO plans   (plan_id,plan_name,price)
                           values(0,'trial',0),
								 (1,'basic monthly', 9.90),
                                 (2,'pro monthly', 19.90),
                                 (3,'pro annual', 199),
                                 (4,'churn', NULL);
                                 
-- contents of the plans table--

select * from plans;


-- Inserting rows into the subscriptions table--

INSERT INTO Subscriptions  (Customer_id, Plan_id, Start_date)
						VALUES (1,	0,	'2020-08-01'),
							   (1,	1,	'2020-08-08'),
							   (2,	0,	'2020-09-20'),
							   (2,	3,	'2020-09-27'),
                               (11,	0,	'2020-11-19'),
                               (11, 4,	'2020-11-26'),
                               (13,	0,	'2020-12-15'),
                               (13,	1,	'2020-12-22'),
                               (13,	2,	'2021-03-29'),
                               (15,	0,	'2020-03-17'),
                               (15,	2,	'2020-03-24'),
                               (15,	4,	'2020-04-29'),
                               (16,	0,	'2020-05-31'),
							   (16,	1,	'2020-06-07'),
                               (16,	3,	'2020-10-21'),
							   (18,	0,	'2020-07-06'),
                               (18,	2,	'2020-07-13'),
                               (19,	0,	'2020-06-22'),
                               (19,	2,	'2020-06-29'),
                               (19,	3,	'2020-08-29');
                               
-- Contents of the Subscription Table--

Select * from subscriptions;

-- Customeer Journey--

SELECT s.Customer_id, p.Plan_id, p.Plan_name, s.Start_date 
				FROM Plans p INNER JOIN
                Subscriptions s ON p.Plan_id = s.Plan_id 
                ORDER BY s.Customer_id;
                

--  any users Individually using giving specific Cutomer_id in the where condition

use foodie_fi;
SELECT s.Customer_id, p.plan_id, p.plan_name, s.start_date
                FROM Plans p INNER  JOIN
                Subscriptions s ON P.plan_id = s.plan_id
                WHERE Customer_id = 2
                ORDER BY Plan_id;
                
-- B.Data Analysis --

-- 1. How many customers has Foodie-Fi ever had?			

SELECT COUNT(DISTINCT customer_id) count from Subscriptions;				
                            
-- 2.	What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT MONTHNAME(Start_date) Month, COUNT(Customer_id) Distributions
        FROM Subscriptions WHERE Plan_id = 0            
        GROUP BY MONTH(Start_date) 
        ORDER BY MONTH(Start_date);                                
                                 
-- 3.	What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT p.Plan_id, p.Plan_name, COUNT(*) No_of_events 
              FROM  Plans p 
              INNER JOIN Subscriptions s
              ON p.plan_id = s.plan_id
          WHERE YEAR(s.Start_date)> 2020
          GROUP BY p.Plan_Name;

-- 4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT COUNT(*) Churned_customers, 
ROUND((COUNT(*)/ (SELECT COUNT(DISTINCT customer_id) FROM Subscriptions)) * 100 ,1)
as percentage_of_customers
FROM Subscriptions
WHERE plan_id = 2 ;

-- 5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

CREATE VIEW ranking AS
SELECT 
  s.customer_id, 
  s.plan_id, 
  p.Plan_name,
  -- Run a Row_Number() to rank plans from 0 to 4
  ROW_NUMBER() OVER (
    PARTITION BY s.customer_id 
    ORDER BY s.Plan_id) plan_rank 
FROM Subscriptions s
INNER JOIN Plans p
  ON s.plan_id = p.Plan_id;

select * from ranking;

SELECT 
  COUNT(*) AS churn_count,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),0) AS churn_percentage
FROM ranking
WHERE plan_id = 4 -- Filter to churn plan
  AND plan_rank = 2; -- Filter to rank 2 as customers who churned immediately after trial have churn plan ranked as 2


-- 6.What is the number and percentage of customer plans after their initial free trial?	

WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  LEAD(plan_id, 1) OVER( -- Offset by 1 to retrieve the immediate row's value below 
    PARTITION BY customer_id 
    ORDER BY plan_id) next_plan
FROM subscriptions)

SELECT 
  next_plan, 
  COUNT(*) conversions,
  ROUND(COUNT(*)*100 / (SELECT COUNT(DISTINCT customer_id) 
  FROM Subscriptions),0) conversion_percentage
  FROM next_plan_cte
  WHERE next_plan IS NOT NULL 
  AND plan_id = 0
  GROUP BY next_plan
  ORDER BY next_plan;				
                           
                            
--  7.	What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

 WITH next_plan AS(
  SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
  FROM 
      subscriptions
  WHERE 
      start_date <= '2020-12-31'),
      
-- Find customer breakdown with existing plans on or after 31 Dec 2020

customer_breakdown AS (
    SELECT 
        plan_id, 
        COUNT(DISTINCT customer_id) AS customers
    FROM 
        next_plan
    WHERE 
        (next_date IS NOT NULL AND (start_date < '2020-12-31' 
	AND 
        next_date > '2020-12-31'))
    OR 
        (next_date IS NULL AND start_date < '2020-12-31')
    GROUP BY 
         plan_id)

    SELECT 
         plan_id, customers, 
         ROUND(100 * customers / (
    SELECT 
         COUNT(DISTINCT customer_id) 
    FROM 
         foodie_fi.subscriptions),1) AS percentage
    FROM 
         customer_breakdown
    GROUP BY 
         plan_id, customers
    ORDER BY 
         plan_id;
         

-- 8.	How many customers have upgraded to an annual plan in 2020?

SELECT 
    COUNT(DISTINCT customer_id) AS unique_customer
FROM 
    Subscriptions
WHERE 
    plan_id = 3
AND 
    start_date <= '2020-12-31';
    
    
-- 9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
    

WITH trial_plan AS 
  (SELECT 
    customer_id, 
    start_date trial_date
  FROM 
	subscriptions
  WHERE 
	plan_id = 0
),

-- Filter results to customers at pro annual plan = 3

annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM 
     subscriptions
  WHERE 
     plan_id = 3
)
SELECT 
  ROUND(AVG(annual_date - trial_date),0)  avg_days_to_upgrade
FROM 
  trial_plan tp
JOIN 
  annual_plan ap
ON 
  tp.customer_id = ap.customer_id;
  
  
  -- 10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

use foodie_fi;
WITH trial_plan AS 
  (
  SELECT 
    customer_id, 
    start_date AS trial_date
  FROM 
     subscriptions
  WHERE 
     plan_id = 0
),
-- Filter results to customers at pro annual plan = 3

annual_plan AS
  (SELECT 
    customer_id, 
    start_date AS annual_date
  FROM 
	subscriptions
  WHERE 
	plan_id = 3
),
time_lapse_tb as (
	SELECT 
	   tp.customer_id,
	   tp.trial_date,
	   ap.annual_date,
	   DATEDIFF(ap.annual_date,tp.trial_date) as diff
	FROM 
	   trial_plan tp
	LEFT JOIN 
       annual_plan ap
	ON 
       tp.customer_id = ap.customer_id
	WHERE 
       annual_date IS NOT NULL
),
bins  AS (
 SELECT *,
	FLOOR(diff/30) AS bins
    FROM time_lapse_tb)

SELECT 
    CONCAT((bins*30)+1,'-',(bins+1)*30,'days') AS Days,
    COUNT(diff) AS Total
FROM
    bins
GROUP BY 
    bins;
    
    
-- 11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH next_plan_cte AS (
  SELECT 
    customer_id, 
    plan_id, 
    start_date,
    LEAD(plan_id, 1) 
    OVER(PARTITION BY customer_id 
	     ORDER BY plan_id)  next_plan
    FROM subscriptions)

  SELECT 
    COUNT(*) AS downgraded
  FROM 
	next_plan_cte
  WHERE 
	start_date <= '2020-12-31'
  AND 
     plan_id = 2 
  AND 
     next_plan = 1;
     
     
-- SECTION C -> New payments table

CREATE TABLE payments as
WITH payment as (
    SELECT
      s.customer_id as customer_id,
      s.plan_id as plan_id,
      p.plan_name as plan_name,
      
      CASE
          WHEN s.plan_id = 1 THEN s.start_date
          WHEN s.plan_id = 2 THEN s.start_date
          WHEN s.plan_id = 3 THEN s.start_date
          WHEN s.plan_id = 4 THEN NULL
          ELSE '2020-12-31' 
        END AS payment_date,
      price AS amount
    FROM
      subscriptions AS s
      JOIN plans AS p ON s.plan_id = p.plan_id
    WHERE
      s.plan_id != 0
      AND s.start_date < '2021-01-01' 
    GROUP BY
      s.customer_id,
      s.plan_id,
      p.plan_name,
      s.start_date,
      p.price
	ORDER BY
	  s.customer_id)

SELECT
  customer_id,
  plan_id,
  plan_name,
  payment_date,
  CASE
    WHEN LAG(plan_id) OVER (
      PARTITION BY customer_id
      ORDER BY
        plan_id
    ) != plan_id
    AND (
      DATEDIFF(payment_date, LAG(payment_date) OVER (
        PARTITION BY customer_id
        ORDER BY
          plan_id
      ))
    ) < 30 THEN amount - LAG(amount) OVER (
      PARTITION BY customer_id
      ORDER BY
        plan_id
    )
    ELSE amount
  END AS amount,
  RANK() OVER(
    PARTITION BY customer_id
    ORDER BY payment_date
  ) AS payment_order
  from payment
  order by customer_id,plan_id;
  
SELECT * FROM payments;



