-- OB Floor – Projected COT % at midnight
-- COT % if the current packing pace (last full hour + current partial hour) holds until midnight. B2C only.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1),
f AS (SELECT MAX(order_updated_at) AS last_upd FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_updated_at >= DATEADD(day,-3,CURRENT_DATE)),
c AS (SELECT COUNT(*) AS due, SUM(CASE WHEN order_shipped_at < p.d1 THEN 1 ELSE 0 END) AS on_time, SUM(CASE WHEN order_shipped_at IS NULL THEN 1 ELSE 0 END) AS not_shipped
      FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND order_status <> 'CANCELLED' AND (
  (order_created_at >= p.d AND order_created_at < p.d1 AND EXTRACT(HOUR FROM order_created_at) < 17)
  OR (order_created_at >= DATEADD(day,-1,p.d) AND order_created_at < p.d AND EXTRACT(HOUR FROM order_created_at) >= 17))),
pk AS (SELECT EXTRACT(HOUR FROM order_packed_at)::int AS h, COUNT(*) AS n FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1) GROUP BY 1),
x AS (SELECT EXTRACT(HOUR FROM f.last_upd)::int AS uh, EXTRACT(MINUTE FROM f.last_upd)::int AS um, GREATEST(DATEDIFF(minute, f.last_upd, p.d1), 0) / 60.0 AS hrs_left FROM f CROSS JOIN p),
pc AS (SELECT SUM(CASE WHEN pk.h IN (x.uh - 1, x.uh) THEN pk.n ELSE 0 END) / ((CASE WHEN x.uh >= 1 THEN 1 ELSE 0 END) + (x.um + 1) / 60.0) AS pace FROM x CROSS JOIN pk GROUP BY x.uh, x.um),
r AS (SELECT c.*, x.hrs_left, pc.pace FROM c CROSS JOIN x LEFT JOIN pc ON 1 = 1)
SELECT ROUND(100.0 * (on_time + LEAST(not_shipped, COALESCE(pace,0) * hrs_left)) / NULLIF(due,0), 1) AS "Projected COT %" FROM r
