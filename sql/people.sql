-- Scans by user and hour
-- B2C orders and units each picker and packer scanned in each hour of the chosen day. Reads bosta_fulfillment.omniful_orders.
-- Metabase database 11 (Redshift). {{day}} = selected day (YYYY-MM-DD) or NULL for today (Cairo).

WITH p0 AS (SELECT COALESCE(CAST({{day}} AS DATE), CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d),
p AS (SELECT d, DATEADD(day,1,d) AS d1, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS today FROM p0),
act AS (
  SELECT 'pick' AS role, picked_by AS emp, order_picked_at AS ts, COALESCE(total_ordered_quantity,0) AS u FROM bosta_fulfillment.omniful_orders CROSS JOIN p
   WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1) AND picked_by IS NOT NULL
  UNION ALL
  SELECT 'pack', packed_by, order_packed_at, COALESCE(total_packed_quantity,0) FROM bosta_fulfillment.omniful_orders CROSS JOIN p
   WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1) AND packed_by IS NOT NULL)
SELECT role, emp, EXTRACT(HOUR FROM ts)::int AS h, COUNT(*) AS n, SUM(u) AS units, MAX(ts) AS last_scan
FROM act GROUP BY 1,2,3 ORDER BY 1,2,3
