-- OB Floor – Shipped vs even pace today
-- Cumulative B2C orders shipped through the day against an even pace to clear today's cut-off orders by midnight.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1), h AS (SELECT 0 AS h UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23),
c AS (SELECT COUNT(*) AS due FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND order_status <> 'CANCELLED' AND (
  (order_created_at >= p.d AND order_created_at < p.d1 AND EXTRACT(HOUR FROM order_created_at) < 17)
  OR (order_created_at >= DATEADD(day,-1,p.d) AND order_created_at < p.d AND EXTRACT(HOUR FROM order_created_at) >= 17))),
sh AS (SELECT EXTRACT(HOUR FROM order_shipped_at)::int AS h, COUNT(*) AS n FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1) GROUP BY 1),
nowh AS (SELECT EXTRACT(HOUR FROM CONVERT_TIMEZONE('Africa/Cairo', GETDATE()))::int AS nh)
SELECT LPAD(h.h::varchar, 2, '0') || ':00' AS "Hour",
  CASE WHEN h.h <= nowh.nh THEN SUM(COALESCE(sh.n,0)) OVER (ORDER BY h.h ROWS UNBOUNDED PRECEDING) END AS "Cumulative shipped",
  ROUND(c.due * (h.h + 1) / 24.0) AS "Even pace"
FROM h LEFT JOIN sh ON sh.h = h.h CROSS JOIN c CROSS JOIN nowh ORDER BY h.h
