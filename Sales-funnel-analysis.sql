CREATE TABLE public.user_events (
    event_id        BIGINT PRIMARY KEY,
    user_id         INTEGER NOT NULL,
    event_type      VARCHAR(50) NOT NULL,
    event_date      TIMESTAMP WITH TIME ZONE NOT NULL,
    product_id      INTEGER,
    amount          NUMERIC(12,2),
    traffic_source  VARCHAR(50)
);


COPY public.user_events (event_id, user_id, event_type, event_date, product_id, amount, traffic_source)
FROM 'C:/Users/papad/Downloads/user_events.csv'
WITH (FORMAT csv, DELIMITER ',', HEADER, ENCODING 'UTF8');

select * from user_events


--define sales funnel at different stages


WITH funnel_stages AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view'       THEN user_id END) AS stage1_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'     THEN user_id END) AS stage2_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start'  THEN user_id END) AS stage3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info'    THEN user_id END) AS stage4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase'        THEN user_id END) AS stage5_purchase
    FROM user_events
    WHERE event_date >= CURRENT_DATE - INTERVAL '65 days'
)
SELECT * FROM funnel_stages;
   

--conversation rates through the funnel
WITH funnel_stages AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view'      THEN user_id END) AS stage1_views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart'    THEN user_id END) AS stage2_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS stage3_checkout,
        COUNT(DISTINCT CASE WHEN event_type = 'payment_info'   THEN user_id END) AS stage4_payment,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase'       THEN user_id END) AS stage5_purchase
    FROM user_events
)                            -- ✅ CTE closes here
SELECT                       -- ✅ conversion rates calculated here, AFTER the CTE
    stage1_views,
    stage2_cart,
    ROUND(stage2_cart * 100.0 / stage1_views) AS view_to_cart_rate,
    stage3_checkout,
    ROUND(stage3_checkout * 100.0 / stage2_cart) AS cart_to_checkout_rate,
    stage4_payment,
    ROUND(stage4_payment * 100.0 / stage3_checkout) AS checkout_to_payment_rate,
    stage5_purchase,
    ROUND(stage5_purchase * 100.0 / stage4_payment) AS payment_to_purchase_rate,
    ROUND(stage5_purchase * 100.0 / stage1_views) AS overall_conversion_rate
FROM funnel_stages;

--We can see that we are losing a lot of leads (70% of them) from views to cart


--Funnel by source

WITH source_funnel AS (
    SELECT
        traffic_source,
        COUNT(DISTINCT CASE WHEN event_type = 'page_view'   THEN user_id END) AS views,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS cart,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase'    THEN user_id END) AS purchases
    FROM user_events
    GROUP BY traffic_source
)
SELECT
    traffic_source,
    views,
    cart,
    purchases,                                                    -- ✅ comma added
    ROUND(cart * 100.0 / views) AS cart_conversion_rate,
    ROUND(purchases * 100.0 / views) AS overall_conversion_rate, -- ✅ better name
    ROUND(purchases * 100.0 / cart) AS purchases_conversion_rate  -- ✅ no trailing comma
FROM source_funnel
ORDER BY purchases;


--time to conversion analysis

WITH user_journey AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'page_view'   THEN event_date END) AS views_time,
        MIN(CASE WHEN event_type = 'add_to_cart' THEN event_date END) AS cart_time,
        MIN(CASE WHEN event_type = 'purchase'    THEN event_date END) AS purchases_time
    FROM user_events
    GROUP BY user_id
    HAVING MIN(CASE WHEN event_type = 'purchase' THEN event_date END) IS NOT NULL
)
SELECT
    COUNT(*) AS converted_users,                                                        -- ✅ count rows
    ROUND(AVG(EXTRACT(EPOCH FROM (cart_time - views_time)) / 60), 2) AS avg_view_to_cart_minutes,      -- ✅ comma
    ROUND(AVG(EXTRACT(EPOCH FROM (purchases_time - cart_time)) / 60), 2) AS avg_cart_to_purchase_minutes, -- ✅ comma
    ROUND(AVG(EXTRACT(EPOCH FROM (purchases_time - views_time)) / 60), 2) AS avg_total_journey_minutes  -- ✅ no trailing comma
FROM user_journey;


--Revenue funnel analysis
WITH funnel_revenue AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS total_visitors,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase'  THEN user_id END) AS total_buyers,
        SUM(CASE WHEN event_type = 'purchase'             THEN amount END)  AS total_revenue,
        COUNT(CASE WHEN event_type = 'purchase'           THEN 1 END)       AS total_orders
    FROM user_events
)
SELECT
  total_visitors,
  total_buyers,
  total_orders,
  total_revenue,
  total_revenue / total_orders AS  avg_order_value,
  total_revenue / total_buyers AS  revenue_per_buyer,
  total_revenue / total_visitors AS  revenue_per_visitors

FROM funnel_revenue;


--EXTRAS--
SELECT 
    traffic_source, 
    COUNT(*) AS total_purchases
FROM user_events
WHERE event_type = 'purchase'
GROUP BY traffic_source
ORDER BY total_purchases DESC;


--number of perchases per week---


SELECT 
    traffic_source,
    date_trunc('week', event_date)::date AS purchase_week,
    COUNT(*) AS number_of_purchases,
    COUNT(DISTINCT user_id) AS unique_buyers
FROM user_events
WHERE event_type = 'purchase'
  AND traffic_source IN ('email', 'social')
GROUP BY 
    traffic_source, 
    date_trunc('week', event_date)
ORDER BY 
    traffic_source, 
    purchase_week DESC;

--Weekly breakdown with weekday vs weekend split---

SELECT 
    traffic_source,
    date_trunc('week', event_date)::date AS purchase_week_start,
    
    COUNT(CASE WHEN EXTRACT(DOW FROM event_date) BETWEEN 1 AND 5 
               THEN 1 END) AS weekday_purchases,      -- Mon-Fri
    
    COUNT(CASE WHEN EXTRACT(DOW FROM event_date) IN (0, 6) 
               THEN 1 END) AS weekend_purchases,      -- Sat + Sun
    
    COUNT(*) AS total_purchases,
    
    COUNT(DISTINCT user_id) AS unique_buyers_per_week,

    ROUND(
        COUNT(CASE WHEN EXTRACT(DOW FROM event_date) IN (0, 6) THEN 1 END)::numeric 
        / COUNT(*) * 100, 1
    ) AS weekend_percentage

FROM user_events
WHERE event_type = 'purchase'
  AND traffic_source IN ('email', 'social')
GROUP BY 
    traffic_source, 
    date_trunc('week', event_date)
ORDER BY 
    traffic_source, 
    purchase_week_start DESC;

--Simple overall summary (total weekdays vs weekends — no weeks)---

SELECT 
    traffic_source,
    
    COUNT(CASE WHEN EXTRACT(DOW FROM event_date) BETWEEN 1 AND 5 
               THEN 1 END) AS weekday_purchases,      -- Mon-Fri
    
    COUNT(CASE WHEN EXTRACT(DOW FROM event_date) IN (0, 6) 
               THEN 1 END) AS weekend_purchases,      -- Sat + Sun
    
    COUNT(*) AS total_purchases,
    
    ROUND(
        COUNT(CASE WHEN EXTRACT(DOW FROM event_date) IN (0, 6) THEN 1 END)::numeric 
        / COUNT(*) * 100, 1
    ) AS weekend_percentage

FROM user_events
WHERE event_type = 'purchase'
  AND traffic_source IN ('email', 'social')
GROUP BY traffic_source
ORDER BY traffic_source;


	
