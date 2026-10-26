-- Open-order aging (live)
-- Open B2C orders by pick, pack and ship step (time since the step before) and by current status (time since creation), bucketed by age. Reads bosta_fulfillment.omniful_orders.
-- Metabase database 11 (Redshift). {{day}} = selected day (YYYY-MM-DD) or NULL for today (Cairo).

SELECT * FROM (WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c),
a AS (
  SELECT CASE WHEN order_status IN ('NEW ORDER','IN PICKING') THEN 'pick'
              WHEN order_status IN ('PICKED','IN PACKING') THEN 'pack' ELSE 'ship' END AS stage,
         DATEDIFF(minute, CASE WHEN order_status IN ('NEW ORDER','IN PICKING') THEN order_created_at
                               WHEN order_status IN ('PICKED','IN PACKING') THEN COALESCE(order_picked_at, order_created_at)
                               ELSE COALESCE(order_packed_at, order_picked_at, order_created_at) END, f.now_c) AS m,
         COALESCE(total_ordered_quantity,0) AS u,
         CASE WHEN order_status IN ('IN PICKING','IN PACKING') THEN 1 ELSE 0 END AS doing
  FROM bosta_fulfillment.omniful_orders CROSS JOIN f
  WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP'))
SELECT 'step' AS grp, stage, COUNT(*) AS n, SUM(doing) AS n_doing, SUM(u) AS units, ROUND(AVG(m)) AS avg_m, MEDIAN(m) AS med_m, MAX(m) AS max_m,
  SUM(CASE WHEN m < 60 THEN 1 ELSE 0 END) AS b0,
  SUM(CASE WHEN m >= 60 AND m < 120 THEN 1 ELSE 0 END) AS b1,
  SUM(CASE WHEN m >= 120 AND m < 240 THEN 1 ELSE 0 END) AS b2,
  SUM(CASE WHEN m >= 240 AND m < 480 THEN 1 ELSE 0 END) AS b3,
  SUM(CASE WHEN m >= 480 AND m < 1440 THEN 1 ELSE 0 END) AS b4,
  SUM(CASE WHEN m >= 1440 THEN 1 ELSE 0 END) AS b5
FROM a GROUP BY stage) x1
UNION ALL
SELECT * FROM (WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c),
a AS (
  SELECT CASE order_status WHEN 'NEW ORDER' THEN '1' WHEN 'IN PICKING' THEN '2' WHEN 'PICKED' THEN '3' WHEN 'IN PACKING' THEN '4'
              WHEN 'PACKED' THEN '5' WHEN 'READY TO SHIP' THEN '5' ELSE '6' END AS st,
         DATEDIFF(minute, order_created_at, f.now_c) AS m, COALESCE(total_ordered_quantity,0) AS u
  FROM bosta_fulfillment.omniful_orders CROSS JOIN f
  WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD'))
SELECT 'all' AS grp, COALESCE(st,'all') AS stage, COUNT(*) AS n, CAST(NULL AS BIGINT) AS n_doing, SUM(u) AS units, ROUND(AVG(m)) AS avg_m, MEDIAN(m) AS med_m, MAX(m) AS max_m,
  SUM(CASE WHEN m < 120 THEN 1 ELSE 0 END) AS b0, SUM(CASE WHEN m >= 120 AND m < 240 THEN 1 ELSE 0 END) AS b1,
  SUM(CASE WHEN m >= 240 AND m < 480 THEN 1 ELSE 0 END) AS b2, SUM(CASE WHEN m >= 480 AND m < 1440 THEN 1 ELSE 0 END) AS b3,
  SUM(CASE WHEN m >= 1440 AND m < 2880 THEN 1 ELSE 0 END) AS b4, SUM(CASE WHEN m >= 2880 THEN 1 ELSE 0 END) AS b5
FROM a GROUP BY ROLLUP(st)) x2
