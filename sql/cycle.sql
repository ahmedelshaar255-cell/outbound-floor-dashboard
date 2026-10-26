-- Step times on the day
-- Median and average minutes each step took for B2C orders that finished it on the chosen day. Reads bosta_fulfillment.omniful_orders.
-- Metabase database 11 (Redshift). {{day}} = selected day (YYYY-MM-DD) or NULL for today (Cairo).

WITH p0 AS (SELECT COALESCE(CAST({{day}} AS DATE), CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d),
p AS (SELECT d, DATEADD(day,1,d) AS d1, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS today FROM p0)
SELECT 'pick' AS stage, COUNT(*) AS n, ROUND(AVG(m)) AS avg_m, MEDIAN(m) AS med_m, SUM(CASE WHEN m <= 120 THEN 1 ELSE 0 END) AS in_target
FROM (SELECT DATEDIFF(minute, order_created_at, order_picked_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p
      WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1) AND order_created_at IS NOT NULL) x
UNION ALL
SELECT 'pack' AS stage, COUNT(*) AS n, ROUND(AVG(m)) AS avg_m, MEDIAN(m) AS med_m, SUM(CASE WHEN m <= 120 THEN 1 ELSE 0 END) AS in_target
FROM (SELECT DATEDIFF(minute, order_picked_at, order_packed_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p
      WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1) AND order_picked_at IS NOT NULL) x
UNION ALL
SELECT 'ship' AS stage, COUNT(*) AS n, ROUND(AVG(m)) AS avg_m, MEDIAN(m) AS med_m, SUM(CASE WHEN m <= 120 THEN 1 ELSE 0 END) AS in_target
FROM (SELECT DATEDIFF(minute, order_packed_at, order_shipped_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p
      WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1) AND order_packed_at IS NOT NULL) x
UNION ALL
SELECT 'total' AS stage, COUNT(*) AS n, ROUND(AVG(m)) AS avg_m, MEDIAN(m) AS med_m, SUM(CASE WHEN m <= 1440 THEN 1 ELSE 0 END) AS in_target
FROM (SELECT DATEDIFF(minute, order_created_at, order_shipped_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p
      WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1) AND order_created_at IS NOT NULL) x
