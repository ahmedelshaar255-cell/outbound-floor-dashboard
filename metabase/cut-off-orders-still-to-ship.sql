-- OB Floor – Cut-off orders still to ship
-- Cut-off orders due today that are not shipped yet. B2C only.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1) SELECT SUM(CASE WHEN order_shipped_at IS NULL THEN 1 ELSE 0 END) AS "Still to ship" FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND order_status <> 'CANCELLED' AND (
  (order_created_at >= p.d AND order_created_at < p.d1 AND EXTRACT(HOUR FROM order_created_at) < 17)
  OR (order_created_at >= DATEADD(day,-1,p.d) AND order_created_at < p.d AND EXTRACT(HOUR FROM order_created_at) >= 17))
