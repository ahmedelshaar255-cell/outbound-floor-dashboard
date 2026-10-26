-- OB Floor – Output per hour today
-- B2C orders picked, packed and shipped in each hour today (Cairo time).

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1), h AS (SELECT 0 AS h UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23),
ev AS (
  SELECT 'picked' AS s, EXTRACT(HOUR FROM order_picked_at)::int AS h FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1)
  UNION ALL SELECT 'packed', EXTRACT(HOUR FROM order_packed_at)::int FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1)
  UNION ALL SELECT 'shipped', EXTRACT(HOUR FROM order_shipped_at)::int FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1))
SELECT LPAD(h.h::varchar, 2, '0') || ':00' AS "Hour",
  SUM(CASE WHEN ev.s = 'picked' THEN 1 ELSE 0 END) AS "Picked",
  SUM(CASE WHEN ev.s = 'packed' THEN 1 ELSE 0 END) AS "Packed",
  SUM(CASE WHEN ev.s = 'shipped' THEN 1 ELSE 0 END) AS "Shipped"
FROM h LEFT JOIN ev ON ev.h = h.h GROUP BY h.h ORDER BY h.h
