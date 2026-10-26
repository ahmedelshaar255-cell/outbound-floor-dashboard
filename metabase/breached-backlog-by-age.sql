-- OB Floor – Breached backlog by age
-- Open B2C orders past their COT deadline, by how long ago they were due.

WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c),
o AS (SELECT CASE WHEN EXTRACT(HOUR FROM order_created_at) < 17 THEN DATE_TRUNC('day', order_created_at) + INTERVAL '1 day' ELSE DATE_TRUNC('day', order_created_at) + INTERVAL '2 day' END AS dl FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD'))
SELECT SUM(CASE WHEN f.now_c >= dl THEN 1 ELSE 0 END) AS "Breached total",
  SUM(CASE WHEN dl = DATE_TRUNC('day', f.now_c) THEN 1 ELSE 0 END) AS "Due yesterday",
  SUM(CASE WHEN dl = DATE_TRUNC('day', f.now_c) - INTERVAL '1 day' THEN 1 ELSE 0 END) AS "Due 2 days ago",
  SUM(CASE WHEN dl < DATE_TRUNC('day', f.now_c) - INTERVAL '1 day' THEN 1 ELSE 0 END) AS "Due 3+ days ago",
  SUM(CASE WHEN f.now_c < dl AND DATEDIFF(minute, f.now_c, dl) <= 180 THEN 1 ELSE 0 END) AS "Due within 3 hours",
  ROUND(MAX(CASE WHEN f.now_c >= dl THEN DATEDIFF(minute, dl, f.now_c) END) / 60.0, 1) AS "Oldest overdue (hrs)"
FROM o CROSS JOIN f
