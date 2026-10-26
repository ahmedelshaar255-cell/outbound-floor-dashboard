-- OB Floor – Yesterday summary
-- Yesterday's final B2C results: cut-off orders due, shipped on time, COT %, breaches, and orders picked, packed and shipped with the people who did them.

WITH p AS (SELECT DATEADD(day,-1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d1),
c AS (SELECT COUNT(*) AS due, SUM(CASE WHEN order_shipped_at < p.d1 THEN 1 ELSE 0 END) AS on_time,
        SUM(CASE WHEN order_shipped_at >= p.d1 OR order_shipped_at IS NULL THEN 1 ELSE 0 END) AS breaches,
        SUM(CASE WHEN order_shipped_at IS NULL THEN 1 ELSE 0 END) AS not_shipped
      FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND order_status <> 'CANCELLED' AND (
  (order_created_at >= p.d AND order_created_at < p.d1 AND EXTRACT(HOUR FROM order_created_at) < 17)
  OR (order_created_at >= DATEADD(day,-1,p.d) AND order_created_at < p.d AND EXTRACT(HOUR FROM order_created_at) >= 17))),
w AS (SELECT SUM(CASE WHEN (order_picked_at >= p.d AND order_picked_at < p.d1) THEN 1 ELSE 0 END) AS picked,
        SUM(CASE WHEN (order_picked_at >= p.d AND order_picked_at < p.d1) THEN COALESCE(total_ordered_quantity,0) ELSE 0 END) AS picked_i,
        COUNT(DISTINCT CASE WHEN (order_picked_at >= p.d AND order_picked_at < p.d1) THEN picked_by END) AS pickers,
        SUM(CASE WHEN (order_packed_at >= p.d AND order_packed_at < p.d1) THEN 1 ELSE 0 END) AS packed,
        SUM(CASE WHEN (order_packed_at >= p.d AND order_packed_at < p.d1) THEN COALESCE(total_packed_quantity,0) ELSE 0 END) AS packed_i,
        COUNT(DISTINCT CASE WHEN (order_packed_at >= p.d AND order_packed_at < p.d1) THEN packed_by END) AS packers,
        SUM(CASE WHEN (order_shipped_at >= p.d AND order_shipped_at < p.d1) THEN 1 ELSE 0 END) AS shipped,
        SUM(CASE WHEN (order_shipped_at >= p.d AND order_shipped_at < p.d1) THEN COALESCE(total_packed_quantity, total_ordered_quantity, 0) ELSE 0 END) AS shipped_i
      FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_picked_at >= p.d OR order_packed_at >= p.d OR order_shipped_at >= p.d))
SELECT MAX(p.d) AS "Day", MAX(c.due) AS "Cut-off due", MAX(c.on_time) AS "Shipped on time", ROUND(100.0 * MAX(c.on_time) / NULLIF(MAX(c.due),0), 1) AS "COT %",
  MAX(c.breaches) AS "Breaches", MAX(c.not_shipped) AS "Never shipped",
  MAX(w.picked) AS "Picked", MAX(w.picked_i) AS "Picked items", MAX(w.pickers) AS "Pickers",
  MAX(w.packed) AS "Packed", MAX(w.packed_i) AS "Packed items", MAX(w.packers) AS "Packers",
  MAX(w.shipped) AS "Shipped", MAX(w.shipped_i) AS "Shipped items"
FROM c CROSS JOIN w CROSS JOIN p
