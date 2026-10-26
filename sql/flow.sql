-- Order flow and cut-off
-- Live counts of B2C orders at each step, what was done on the chosen day, the breached backlog, when Metabase last synced, and the chosen day's cut-off orders (due, shipped on time, still to ship). Reads bosta_fulfillment.omniful_orders.
-- Metabase database 11 (Redshift). {{day}} = selected day (YYYY-MM-DD) or NULL for today (Cairo).

WITH p0 AS (SELECT COALESCE(CAST({{day}} AS DATE), CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d),
p AS (SELECT d, DATEADD(day,1,d) AS d1, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS today FROM p0),
f AS (SELECT MAX(order_updated_at) AS last_upd, CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_updated_at >= DATEADD(day,-3,CURRENT_DATE)),
o AS (SELECT order_status, order_picked_at, picked_by, order_packed_at, packed_by, order_shipped_at, CASE WHEN EXTRACT(HOUR FROM order_created_at) < 17 THEN DATE_TRUNC('day', order_created_at) + INTERVAL '1 day' ELSE DATE_TRUNC('day', order_created_at) + INTERVAL '2 day' END AS dl,
             COALESCE(total_ordered_quantity,0) AS qo, COALESCE(total_packed_quantity, total_ordered_quantity, 0) AS qp
      FROM bosta_fulfillment.omniful_orders CROSS JOIN p
      WHERE order_type = 'B2C' AND (order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') OR (order_picked_at >= p.d AND order_picked_at < p.d1) OR (order_packed_at >= p.d AND order_packed_at < p.d1) OR (order_shipped_at >= p.d AND order_shipped_at < p.d1))),
c AS (SELECT COUNT(*) AS due, SUM(COALESCE(o.total_ordered_quantity,0)) AS due_i,
  SUM(CASE WHEN o.order_shipped_at < p.d1 THEN 1 ELSE 0 END) AS on_time,
  SUM(CASE WHEN o.order_shipped_at < p.d1 THEN COALESCE(o.total_ordered_quantity,0) ELSE 0 END) AS on_time_i,
  SUM(CASE WHEN o.order_shipped_at IS NULL THEN 1 ELSE 0 END) AS not_shipped,
  SUM(CASE WHEN o.order_shipped_at IS NULL THEN COALESCE(o.total_ordered_quantity,0) ELSE 0 END) AS not_shipped_i,
  SUM(CASE WHEN o.order_shipped_at >= p.d1 OR (o.order_shipped_at IS NULL AND CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) >= p.d1) THEN 1 ELSE 0 END) AS breaches,
  SUM(CASE WHEN o.order_created_at < p.d THEN 1 ELSE 0 END) AS due_prev,
  SUM(CASE WHEN o.order_created_at < p.d AND o.order_shipped_at IS NULL THEN 1 ELSE 0 END) AS pend_prev,
  SUM(CASE WHEN o.order_created_at >= p.d THEN 1 ELSE 0 END) AS due_tod,
  SUM(CASE WHEN o.order_created_at >= p.d AND o.order_shipped_at IS NULL THEN 1 ELSE 0 END) AS pend_tod,
  SUM(CASE WHEN o.order_shipped_at IS NULL AND o.order_status IN ('NEW ORDER','IN PICKING') THEN 1 ELSE 0 END) AS p_pick,
  SUM(CASE WHEN o.order_shipped_at IS NULL AND o.order_status IN ('PICKED','IN PACKING') THEN 1 ELSE 0 END) AS p_pack,
  SUM(CASE WHEN o.order_shipped_at IS NULL AND o.order_status IN ('PACKED','READY TO SHIP') THEN 1 ELSE 0 END) AS p_ship,
  ROUND(100.0 * SUM(CASE WHEN o.order_shipped_at < p.d1 THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0), 1) AS cot_pct
FROM bosta_fulfillment.omniful_orders o CROSS JOIN p
WHERE o.order_type = 'B2C' AND o.order_status <> 'CANCELLED' AND (
  (o.order_created_at >= p.d AND o.order_created_at < p.d1 AND EXTRACT(HOUR FROM o.order_created_at) < 17)
  OR (o.order_created_at >= DATEADD(day,-1,p.d) AND o.order_created_at < p.d AND EXTRACT(HOUR FROM o.order_created_at) >= 17)))
SELECT MAX(p.d) AS day, MAX(CASE WHEN p.d = p.today THEN 1 ELSE 0 END) AS is_today,
  MAX(f.last_upd) AS last_upd, MAX(f.now_c) AS now_c,
  SUM(CASE WHEN order_status='NEW ORDER' THEN 1 ELSE 0 END) AS wait_pick,
  SUM(CASE WHEN order_status='IN PICKING' THEN 1 ELSE 0 END) AS picking,
  SUM(CASE WHEN order_status='PICKED' THEN 1 ELSE 0 END) AS wait_pack,
  SUM(CASE WHEN order_status='IN PACKING' THEN 1 ELSE 0 END) AS packing,
  SUM(CASE WHEN order_status IN ('PACKED','READY TO SHIP') THEN 1 ELSE 0 END) AS wait_ship,
  SUM(CASE WHEN order_status='ON HOLD' THEN 1 ELSE 0 END) AS on_hold,
  SUM(CASE WHEN order_status='NEW ORDER' THEN qo ELSE 0 END) AS wait_pick_i,
  SUM(CASE WHEN order_status='IN PICKING' THEN qo ELSE 0 END) AS picking_i,
  SUM(CASE WHEN order_status='PICKED' THEN qo ELSE 0 END) AS wait_pack_i,
  SUM(CASE WHEN order_status='IN PACKING' THEN qo ELSE 0 END) AS packing_i,
  SUM(CASE WHEN order_status IN ('PACKED','READY TO SHIP') THEN qp ELSE 0 END) AS wait_ship_i,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') THEN 1 ELSE 0 END) AS backlog,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') THEN qo ELSE 0 END) AS backlog_i,
  SUM(CASE WHEN (order_picked_at >= p.d AND order_picked_at < p.d1) THEN 1 ELSE 0 END) AS picked_d,
  SUM(CASE WHEN (order_picked_at >= p.d AND order_picked_at < p.d1) THEN qo ELSE 0 END) AS picked_d_i,
  COUNT(DISTINCT CASE WHEN (order_picked_at >= p.d AND order_picked_at < p.d1) THEN picked_by END) AS pickers_d,
  SUM(CASE WHEN (order_packed_at >= p.d AND order_packed_at < p.d1) THEN 1 ELSE 0 END) AS packed_d,
  SUM(CASE WHEN (order_packed_at >= p.d AND order_packed_at < p.d1) THEN qp ELSE 0 END) AS packed_d_i,
  COUNT(DISTINCT CASE WHEN (order_packed_at >= p.d AND order_packed_at < p.d1) THEN packed_by END) AS packers_d,
  SUM(CASE WHEN (order_shipped_at >= p.d AND order_shipped_at < p.d1) THEN 1 ELSE 0 END) AS shipped_d,
  SUM(CASE WHEN (order_shipped_at >= p.d AND order_shipped_at < p.d1) THEN qp ELSE 0 END) AS shipped_d_i,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND f.now_c >= dl THEN 1 ELSE 0 END) AS breached_open,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND f.now_c < dl AND DATEDIFF(minute, f.now_c, dl) <= 180 THEN 1 ELSE 0 END) AS at_risk_open,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND dl = DATE_TRUNC('day', f.now_c) THEN 1 ELSE 0 END) AS br_yday,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND dl = DATE_TRUNC('day', f.now_c) - INTERVAL '1 day' THEN 1 ELSE 0 END) AS br_2d,
  SUM(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND dl < DATE_TRUNC('day', f.now_c) - INTERVAL '1 day' THEN 1 ELSE 0 END) AS br_3d,
  ROUND(MAX(CASE WHEN order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND f.now_c >= dl THEN DATEDIFF(minute, dl, f.now_c) END) / 60.0, 1) AS oldest_overdue_h,
  MAX(c.due) AS due, MAX(c.due_i) AS due_i, MAX(c.on_time) AS on_time, MAX(c.on_time_i) AS on_time_i, MAX(c.not_shipped) AS not_shipped, MAX(c.not_shipped_i) AS not_shipped_i, MAX(c.breaches) AS breaches, MAX(c.due_prev) AS due_prev, MAX(c.pend_prev) AS pend_prev, MAX(c.due_tod) AS due_tod, MAX(c.pend_tod) AS pend_tod, MAX(c.p_pick) AS p_pick, MAX(c.p_pack) AS p_pack, MAX(c.p_ship) AS p_ship, MAX(c.cot_pct) AS cot_pct
FROM o CROSS JOIN f CROSS JOIN p CROSS JOIN c
