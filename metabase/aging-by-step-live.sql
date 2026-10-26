-- OB Floor – Aging by step (live)
-- Open B2C orders at pick, pack and ship, with how long they have waited since the step before (minutes) and age buckets.

WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c),
a AS (SELECT CASE WHEN order_status IN ('NEW ORDER','IN PICKING') THEN 1 WHEN order_status IN ('PICKED','IN PACKING') THEN 2 ELSE 3 END AS k,
         DATEDIFF(minute, CASE WHEN order_status IN ('NEW ORDER','IN PICKING') THEN order_created_at WHEN order_status IN ('PICKED','IN PACKING') THEN COALESCE(order_picked_at, order_created_at) ELSE COALESCE(order_packed_at, order_picked_at, order_created_at) END, f.now_c) AS m,
         COALESCE(total_ordered_quantity,0) AS u, CASE WHEN order_status IN ('IN PICKING','IN PACKING') THEN 1 ELSE 0 END AS doing
  FROM bosta_fulfillment.omniful_orders CROSS JOIN f WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP'))
SELECT CASE k WHEN 1 THEN 'Creation → pick' WHEN 2 THEN 'Pick → pack' ELSE 'Pack → ship' END AS "Step",
  COUNT(*) AS "Open orders", SUM(doing) AS "In progress", SUM(u) AS "Units",
  ROUND(AVG(m) / 60.0, 1) AS "Avg age (hrs)", ROUND(MEDIAN(m) / 60.0, 1) AS "Median age (hrs)", ROUND(MAX(m) / 60.0, 1) AS "Oldest (hrs)",
  SUM(CASE WHEN m < 60 THEN 1 ELSE 0 END) AS "Under 1h", SUM(CASE WHEN m >= 60 AND m < 120 THEN 1 ELSE 0 END) AS "1–2h",
  SUM(CASE WHEN m >= 120 AND m < 240 THEN 1 ELSE 0 END) AS "2–4h", SUM(CASE WHEN m >= 240 AND m < 480 THEN 1 ELSE 0 END) AS "4–8h",
  SUM(CASE WHEN m >= 480 AND m < 1440 THEN 1 ELSE 0 END) AS "8–24h", SUM(CASE WHEN m >= 1440 THEN 1 ELSE 0 END) AS "24h+"
FROM a GROUP BY k ORDER BY k
