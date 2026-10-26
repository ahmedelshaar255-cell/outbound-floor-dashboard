-- OB Floor – Order flow now
-- Live B2C orders at each step, with items, plus what was done today and by how many people.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1),
o AS (SELECT order_status, COALESCE(total_ordered_quantity,0) AS qo, COALESCE(total_packed_quantity, total_ordered_quantity, 0) AS qp FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD')),
s AS (
  SELECT 1 AS k, 'Waiting to pick' AS step, SUM(CASE WHEN order_status='NEW ORDER' THEN 1 ELSE 0 END) AS orders, SUM(CASE WHEN order_status='NEW ORDER' THEN qo ELSE 0 END) AS items FROM o
  UNION ALL SELECT 2, 'Picking now', SUM(CASE WHEN order_status='IN PICKING' THEN 1 ELSE 0 END), SUM(CASE WHEN order_status='IN PICKING' THEN qo ELSE 0 END) FROM o
  UNION ALL SELECT 3, 'Waiting to pack', SUM(CASE WHEN order_status='PICKED' THEN 1 ELSE 0 END), SUM(CASE WHEN order_status='PICKED' THEN qo ELSE 0 END) FROM o
  UNION ALL SELECT 4, 'Packing now', SUM(CASE WHEN order_status='IN PACKING' THEN 1 ELSE 0 END), SUM(CASE WHEN order_status='IN PACKING' THEN qo ELSE 0 END) FROM o
  UNION ALL SELECT 5, 'Waiting to ship', SUM(CASE WHEN order_status IN ('PACKED','READY TO SHIP') THEN 1 ELSE 0 END), SUM(CASE WHEN order_status IN ('PACKED','READY TO SHIP') THEN qp ELSE 0 END) FROM o
  UNION ALL SELECT 6, 'On hold', SUM(CASE WHEN order_status='ON HOLD' THEN 1 ELSE 0 END), SUM(CASE WHEN order_status='ON HOLD' THEN qo ELSE 0 END) FROM o
  UNION ALL SELECT 7, 'Picked today', COUNT(*), SUM(COALESCE(total_ordered_quantity,0)) FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1)
  UNION ALL SELECT 8, 'Packed today', COUNT(*), SUM(COALESCE(total_packed_quantity,0)) FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1)
  UNION ALL SELECT 9, 'Shipped today', COUNT(*), SUM(COALESCE(total_packed_quantity, total_ordered_quantity, 0)) FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1))
SELECT step AS "Step", orders AS "Orders", items AS "Items" FROM s ORDER BY k
