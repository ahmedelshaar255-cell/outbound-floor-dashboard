-- OB Floor – Aging since creation (live)
-- Every open B2C order by where it is now, bucketed by time since it was created, with an all-orders total.

WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c),
a AS (SELECT CASE order_status WHEN 'NEW ORDER' THEN '1' WHEN 'IN PICKING' THEN '2' WHEN 'PICKED' THEN '3' WHEN 'IN PACKING' THEN '4' WHEN 'PACKED' THEN '5' WHEN 'READY TO SHIP' THEN '5' ELSE '6' END AS st,
         DATEDIFF(minute, order_created_at, f.now_c) AS m, COALESCE(total_ordered_quantity,0) AS u
  FROM bosta_fulfillment.omniful_orders CROSS JOIN f WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD')),
g AS (SELECT COALESCE(st,'9') AS st, COUNT(*) AS n, SUM(u) AS units, MEDIAN(m) AS med_m, MAX(m) AS max_m,
  SUM(CASE WHEN m < 120 THEN 1 ELSE 0 END) AS b0, SUM(CASE WHEN m >= 120 AND m < 240 THEN 1 ELSE 0 END) AS b1,
  SUM(CASE WHEN m >= 240 AND m < 480 THEN 1 ELSE 0 END) AS b2, SUM(CASE WHEN m >= 480 AND m < 1440 THEN 1 ELSE 0 END) AS b3,
  SUM(CASE WHEN m >= 1440 AND m < 2880 THEN 1 ELSE 0 END) AS b4, SUM(CASE WHEN m >= 2880 THEN 1 ELSE 0 END) AS b5
  FROM a GROUP BY ROLLUP(st))
SELECT CASE st WHEN '1' THEN 'Waiting to pick' WHEN '2' THEN 'Picking now' WHEN '3' THEN 'Waiting to pack' WHEN '4' THEN 'Packing now' WHEN '5' THEN 'Waiting to ship' WHEN '6' THEN 'On hold' ELSE 'All open orders' END AS "Where the order is now",
  n AS "Orders", units AS "Units", b0 AS "Under 2h", b1 AS "2–4h", b2 AS "4–8h", b3 AS "8–24h", b4 AS "1–2 days", b5 AS "2+ days",
  ROUND(med_m / 60.0, 1) AS "Median age (hrs)", ROUND(max_m / 60.0, 1) AS "Oldest (hrs)"
FROM g ORDER BY st
