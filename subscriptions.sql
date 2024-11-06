SELECT *
FROM plans;
SELECT *
FROM subscriptions; 

-- 1 How many customers has Foodie-Fi ever had?
SELECT count(distinct customer_id) AS total_customers
FROM subscriptions;



 -- 2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month AS the GROUP BY  value.
SELECT monthname(start_date) AS month ,
		count(*) AS subscription_count
FROM subscriptions
join plans using(plan_id)
WHERE plan_name='trial'
GROUP BY  month(start_date),monthname(start_date)
ORDER BY  month(start_date); 



-- 3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name,
		 count(start_date) AS count
FROM subscriptions s
JOIN plans p using(plan_id)
WHERE year(start_date)>2020
GROUP BY  p.plan_name; 



-- 4 What is the customer count AND percentage of customers who have churned rounded to 1 decimal place?
SELECT count(case
	WHEN plan_name='churn' THEN
	1 end) AS total_churned_customers, count(distinct customer_id) AS total_customers, round(count(case
	WHEN plan_name='churn' THEN
	1 end)*100.0/count(distinct customer_id),1) AS 'churn%'
FROM subscriptions s
JOIN plans p using(plan_id); 

-- 5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte AS 
    (SELECT plan_name,
		 s.*,
		 row_number() over(partition by customer_id
    ORDER BY  start_date) r
    FROM subscriptions s
    JOIN plans using(plan_id) )
SELECT count(case
	WHEN r=2
		AND plan_name='churn' THEN
	1 end) AS trial_to_churn_count,round(count(case
	WHEN r=2
		AND plan_name='churn' THEN
	1 end)*100/count(distinct customer_id)) trial_to_churn_count_pct
FROM cte ; 


    -- 6 What is the number AND percentage of customer plans after their initial free trial?
WITH cte AS 
    (SELECT *,
		 row_number() over(partition by customer_id
    ORDER BY  start_date) AS r
    FROM subscriptions)
SELECT DISTINCT plan_name,
		count(*) over(partition by cte.plan_id) as_2ndplan_count,
		 round(count(*)over(partition by cte.plan_id)*100.0/count(*) over() ,
		2)as_2ndplan_count_pct
FROM cte
JOIN plans using(plan_id)where r=2 ; 

-- 7. What is the customer count AND percentage breakdown of ALL active 5 plan_name values at 2020-12-31?
WITH cte AS 
    (SELECT *,
		 row_number() over(partition by customer_id
    ORDER BY  start_date desc) AS r
    FROM subscriptions
    WHERE start_date<='2020-12-31' )
SELECT DISTINCT p.plan_id,
		plan_name,
		 count(*)over(partition by p.plan_id) AS plan_count,
		count(*) over(partition by p.plan_id)*100/count(*) over() AS plan_pct
FROM cte
JOIN plans p using(plan_id)
WHERE r=1; 

-- 8 How many customers have upgraded to an annual plan IN 2020?
SELECT count(*) AS anual_plan_count
FROM subscriptions
JOIN plans using(plan_id)
WHERE year(start_date)=2020
		AND plan_name='pro annual'; 
        
        
        -- 9 How many days ON average does it take for a customer to an annual plan FROM the day they JOIN Foodie-Fi?
WITH cte AS 
    (SELECT *,
		count(*)over(partition by customer_id) c
    FROM subscriptions s
    JOIN plans p using(plan_id)
    WHERE plan_name IN ('trial','pro annual')
    ORDER BY  customer_id), cte1 as
    (SELECT * ,
		 datediff(max(start_date) over(partition by customer_id),
		min(start_date) over(partition by customer_id)) AS d
    FROM cte
    WHERE c=2)
SELECT avg(d) AS average
FROM cte1 ;


 -- 10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH cte AS 
    (SELECT *,
		count(*)over(partition by customer_id) c
    FROM subscriptions s
    JOIN plans p using(plan_id)
    WHERE plan_name IN ('trial','pro annual')
    ORDER BY  customer_id), cte1 as
    (SELECT * ,
		 datediff(max(start_date) over(partition by customer_id),
		min(start_date) over(partition by customer_id)) AS d
    FROM cte
    WHERE c=2)
SELECT concat(d-d%30 +1,
		"-",
		d-d%30+30) AS group30days,
		count(distinct customer_id) as customer_count
FROM cte1
GROUP BY  concat(d-d%30+1,'-',d-d%30+30) ; 


-- 11 How many customers downgraded FROM a pro monthly to a basic monthly plan IN 2020?
WITH basic_monthly AS 
    (SELECT customer_id,
		 start_date AS basic_monthly_date
    FROM subscriptions
    JOIN plans using(plan_id)
    WHERE year(start_date)=2020
    		AND plan_name="basic monthly"), pro_monthly AS 
    (SELECT customer_id,
		 start_date AS pro_monthly_date
    FROM subscriptions
    JOIN plans using(plan_id)
    WHERE year(start_date)=2020
    		AND plan_name="pro monthly")
SELECT 
		count(case
	WHEN pro_monthly_date<basic_monthly_date THEN
	1 end) as downgrade_count
FROM basic_monthly
JOIN pro_monthly using(customer_id);