-- OB Floor – Team productivity by hour today
-- Picking and packing per hour today: users working, orders, units, units per user and how many users hit target (70 pick / 90 pack units per hour). B2C only.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1),
a AS (
  SELECT 'Picking' AS task, 70 AS tgt, picked_by AS emp, EXTRACT(HOUR FROM order_picked_at)::int AS h, COUNT(*) AS n, SUM(COALESCE(total_ordered_quantity,0)) AS u FROM bosta_fulfillment.omniful_orders CROSS JOIN p
   WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1) AND picked_by IS NOT NULL GROUP BY 1,2,3,4
  UNION ALL
  SELECT 'Packing', 90, packed_by, EXTRACT(HOUR FROM order_packed_at)::int, COUNT(*), SUM(COALESCE(total_packed_quantity,0)) FROM bosta_fulfillment.omniful_orders CROSS JOIN p
   WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1) AND packed_by IS NOT NULL GROUP BY 1,2,3,4)
SELECT LPAD(h::varchar, 2, '0') || ':00' AS "Hour", task AS "Task", COUNT(*) AS "Users", SUM(n) AS "Orders", SUM(u) AS "Units",
  ROUND(SUM(u)::float / COUNT(*), 1) AS "Units / user", SUM(CASE WHEN u >= tgt THEN 1 ELSE 0 END) AS "Users at target",
  ROUND(100.0 * SUM(u) / (COUNT(*) * MAX(tgt)), 1) AS "% of team capacity"
FROM a GROUP BY h, task ORDER BY h, task
