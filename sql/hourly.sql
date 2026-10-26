-- Picked, packed, shipped by hour
-- B2C orders picked, packed and shipped in each hour of the chosen day. Reads bosta_fulfillment.omniful_orders.
-- Metabase database 11 (Redshift). {{day}} = selected day (YYYY-MM-DD) or NULL for today (Cairo).

WITH p0 AS (SELECT COALESCE(CAST({{day}} AS DATE), CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d),
p AS (SELECT d, DATEADD(day,1,d) AS d1, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS today FROM p0),
ev AS (
  SELECT 'picked' AS s, order_picked_at AS ts FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1)
  UNION ALL SELECT 'packed', order_packed_at FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1)
  UNION ALL SELECT 'shipped', order_shipped_at FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1))
SELECT s || '-' || LPAD(EXTRACT(HOUR FROM ts)::int::varchar, 2, '0') AS k, s, EXTRACT(HOUR FROM ts)::int AS h, COUNT(*) AS n
FROM ev GROUP BY 1,2,3 ORDER BY 3,2
