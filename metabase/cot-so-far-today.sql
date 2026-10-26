-- OB Floor – COT % so far today
-- Cut-off orders due today (created before 5 PM today, or after 5 PM yesterday) shipped on time, as a %. B2C only.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1) SELECT ROUND(100.0 * SUM(CASE WHEN order_shipped_at < p.d1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 1) AS "COT %" FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND order_status <> 'CANCELLED' AND (
  (order_created_at >= p.d AND order_created_at < p.d1 AND EXTRACT(HOUR FROM order_created_at) < 17)
  OR (order_created_at >= DATEADD(day,-1,p.d) AND order_created_at < p.d AND EXTRACT(HOUR FROM order_created_at) >= 17))
