-- Totals per day, week, month
-- B2C totals per day (last 60 days), per Saturday-to-Friday week (last 26 weeks) and per month (last 12 months): cut-off orders due, shipped on time, COT %, breaches, and orders and items picked, packed and shipped. Reads bosta_fulfillment.omniful_orders.
-- Metabase database 11 (Redshift). {{day}} = selected day (YYYY-MM-DD) or NULL for today (Cairo).

WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c, DATE_TRUNC('day', CONVERT_TIMEZONE('Africa/Cairo', GETDATE())) AS today,
                  DATEADD(month, -11, DATE_TRUNC('month', CONVERT_TIMEZONE('Africa/Cairo', GETDATE()))) AS m0),
gr AS (SELECT 'day' AS grain UNION ALL SELECT 'week' UNION ALL SELECT 'month'),
b AS (SELECT o.order_status, o.order_created_at, o.order_picked_at, o.order_packed_at, o.order_shipped_at, o.picked_by, o.packed_by,
             o.total_ordered_quantity, o.total_packed_quantity
      FROM bosta_fulfillment.omniful_orders o CROSS JOIN f WHERE o.order_type = 'B2C'
      AND (o.order_created_at >= DATEADD(day, -1, f.m0) OR o.order_picked_at >= f.m0 OR o.order_packed_at >= f.m0 OR o.order_shipped_at >= f.m0)),
d AS (SELECT CASE WHEN EXTRACT(HOUR FROM order_created_at) < 17 THEN DATE_TRUNC('day', order_created_at) ELSE DATEADD(day, 1, DATE_TRUNC('day', order_created_at)) END AS due_day, order_shipped_at
      FROM b WHERE order_status <> 'CANCELLED' AND order_created_at IS NOT NULL),
ev AS (
  SELECT 'due' AS kind, d.due_day AS t,
         CASE WHEN d.order_shipped_at < DATEADD(day, 1, d.due_day) THEN 1 ELSE 0 END AS ok,
         CASE WHEN d.order_shipped_at >= DATEADD(day, 1, d.due_day) OR (d.order_shipped_at IS NULL AND f.now_c >= DATEADD(day, 1, d.due_day)) THEN 1 ELSE 0 END AS br,
         0::float AS u, CAST(NULL AS VARCHAR(256)) AS who
  FROM d CROSS JOIN f WHERE d.due_day >= f.m0 AND d.due_day <= f.today
  UNION ALL SELECT 'pick', order_picked_at, 0, 0, COALESCE(total_ordered_quantity,0)::float, CAST(picked_by AS VARCHAR(256)) FROM b CROSS JOIN f WHERE order_picked_at >= f.m0
  UNION ALL SELECT 'pack', order_packed_at, 0, 0, COALESCE(total_packed_quantity,0)::float, CAST(packed_by AS VARCHAR(256)) FROM b CROSS JOIN f WHERE order_packed_at >= f.m0
  UNION ALL SELECT 'ship', order_shipped_at, 0, 0, COALESCE(total_packed_quantity, total_ordered_quantity, 0)::float, CAST(NULL AS VARCHAR(256)) FROM b CROSS JOIN f WHERE order_shipped_at >= f.m0),
p AS (SELECT gr.grain, ev.*,
        CASE gr.grain WHEN 'day' THEN DATE_TRUNC('day', ev.t)
                      WHEN 'week' THEN DATEADD(day, -((EXTRACT(DOW FROM ev.t)::int + 1) % 7), DATE_TRUNC('day', ev.t))
                      ELSE DATE_TRUNC('month', ev.t) END AS per
      FROM ev CROSS JOIN gr),
q AS (SELECT p.* FROM p CROSS JOIN f
      WHERE p.per >= CASE p.grain WHEN 'day' THEN DATEADD(day, -59, f.today) WHEN 'week' THEN DATEADD(day, -182, f.today) ELSE f.m0 END)
SELECT grain || ':' || CASE grain WHEN 'month' THEN TO_CHAR(per, 'YYYY-MM') ELSE TO_CHAR(per, 'YYYY-MM-DD') END AS k,
  grain, CASE grain WHEN 'month' THEN TO_CHAR(per, 'YYYY-MM') ELSE TO_CHAR(per, 'YYYY-MM-DD') END AS period,
  SUM(CASE WHEN kind = 'due' THEN 1 ELSE 0 END) AS due,
  SUM(CASE WHEN kind = 'due' THEN ok ELSE 0 END) AS on_time,
  ROUND(100.0 * SUM(CASE WHEN kind = 'due' THEN ok ELSE 0 END) / NULLIF(SUM(CASE WHEN kind = 'due' THEN 1 ELSE 0 END), 0), 1) AS cot_pct,
  SUM(CASE WHEN kind = 'due' THEN br ELSE 0 END) AS breaches,
  SUM(CASE WHEN kind = 'pick' THEN 1 ELSE 0 END) AS picked, SUM(CASE WHEN kind = 'pick' THEN u ELSE 0 END) AS picked_i,
  COUNT(DISTINCT CASE WHEN kind = 'pick' THEN who END) AS pickers,
  SUM(CASE WHEN kind = 'pack' THEN 1 ELSE 0 END) AS packed, SUM(CASE WHEN kind = 'pack' THEN u ELSE 0 END) AS packed_i,
  COUNT(DISTINCT CASE WHEN kind = 'pack' THEN who END) AS packers,
  SUM(CASE WHEN kind = 'ship' THEN 1 ELSE 0 END) AS shipped, SUM(CASE WHEN kind = 'ship' THEN u ELSE 0 END) AS shipped_i,
  COUNT(DISTINCT CASE WHEN kind = 'ship' THEN DATE_TRUNC('day', t) END) AS ship_days,
  ROUND(SUM(CASE WHEN kind = 'ship' THEN 1 ELSE 0 END)::float / NULLIF(COUNT(DISTINCT CASE WHEN kind = 'ship' THEN DATE_TRUNC('day', t) END), 0)) AS shipped_per_day
FROM q GROUP BY grain, per ORDER BY grain, per
