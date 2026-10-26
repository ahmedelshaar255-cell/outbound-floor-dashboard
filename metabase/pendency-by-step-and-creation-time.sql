-- OB Floor – Pendency by step and creation time
-- Where today's unshipped cut-off orders are now, and when they were created. B2C only.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1),
o AS (SELECT order_status, CASE WHEN order_created_at < p.d THEN 'Yesterday after 5 PM' ELSE 'Today before 5 PM' END AS created FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND order_status <> 'CANCELLED' AND (
  (order_created_at >= p.d AND order_created_at < p.d1 AND EXTRACT(HOUR FROM order_created_at) < 17)
  OR (order_created_at >= DATEADD(day,-1,p.d) AND order_created_at < p.d AND EXTRACT(HOUR FROM order_created_at) >= 17)) AND order_shipped_at IS NULL)
SELECT created AS "Created",
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING') THEN 1 ELSE 0 END) AS "Waiting to pick / picking",
  SUM(CASE WHEN order_status IN ('PICKED','IN PACKING') THEN 1 ELSE 0 END) AS "Waiting to pack / packing",
  SUM(CASE WHEN order_status IN ('PACKED','READY TO SHIP') THEN 1 ELSE 0 END) AS "Packed, waiting to ship",
  SUM(CASE WHEN order_status NOT IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP') THEN 1 ELSE 0 END) AS "Other / on hold",
  COUNT(*) AS "Total"
FROM o GROUP BY 1 ORDER BY 1 DESC
