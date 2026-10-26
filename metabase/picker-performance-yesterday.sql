-- OB Floor – Picker performance yesterday
-- Each picker yesterday: B2C orders and units, active hours, rate per hour vs a 70 units/hour target, and achieved % of an 8-hour daily target (560 units).

WITH p AS (SELECT DATEADD(day,-1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d1),
a AS (SELECT picked_by AS emp, EXTRACT(HOUR FROM order_picked_at)::int AS h, COUNT(*) AS n, SUM(COALESCE(total_ordered_quantity,0)) AS u, MAX(order_picked_at) AS last_scan
      FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1) AND picked_by IS NOT NULL GROUP BY 1,2)
SELECT emp AS "Picker", SUM(n) AS "Orders", SUM(u) AS "Units", COUNT(*) AS "Active hours",
  ROUND(SUM(n)::float / COUNT(*), 1) AS "Orders / hr", ROUND(SUM(u)::float / COUNT(*), 1) AS "Units / hr",
  70 AS "Target units / hr", SUM(CASE WHEN u >= 70 THEN 1 ELSE 0 END) AS "Hours at target",
  ROUND(100.0 * SUM(u) / (70 * 8), 1) AS "Achieved % of daily target",
  ROUND(100.0 * (SUM(u)::float / COUNT(*)) / 70, 1) AS "Rate vs target %",
  MAX(last_scan) AS "Last scan"
FROM a GROUP BY 1 ORDER BY 2 DESC
