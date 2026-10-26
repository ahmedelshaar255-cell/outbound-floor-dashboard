-- OB Floor – Pending per seller (live)
-- Every open B2C order grouped by seller: where it is, breached, due today, and how old (hours). Not limited to today.

WITH f AS (SELECT CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS now_c, CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d),
o AS (SELECT seller_name, order_status, order_created_at, COALESCE(total_ordered_quantity,0) AS u, CASE WHEN EXTRACT(HOUR FROM order_created_at) < 17 THEN DATE_TRUNC('day', order_created_at) + INTERVAL '1 day' ELSE DATE_TRUNC('day', order_created_at) + INTERVAL '2 day' END AS dl, DATEDIFF(minute, order_created_at, CONVERT_TIMEZONE('Africa/Cairo', GETDATE())) AS m
      FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD')),
s AS (SELECT COALESCE(seller_name,'(no seller)') AS seller, COUNT(*) AS pending, SUM(u) AS units,
  SUM(CASE WHEN order_status='NEW ORDER' THEN 1 ELSE 0 END) AS wait_pick, SUM(CASE WHEN order_status='IN PICKING' THEN 1 ELSE 0 END) AS picking,
  SUM(CASE WHEN order_status='PICKED' THEN 1 ELSE 0 END) AS wait_pack, SUM(CASE WHEN order_status='IN PACKING' THEN 1 ELSE 0 END) AS packing,
  SUM(CASE WHEN order_status IN ('PACKED','READY TO SHIP') THEN 1 ELSE 0 END) AS wait_ship, SUM(CASE WHEN order_status='ON HOLD' THEN 1 ELSE 0 END) AS on_hold,
  SUM(CASE WHEN f.now_c >= dl THEN 1 ELSE 0 END) AS breached, SUM(CASE WHEN dl = f.d + INTERVAL '1 day' THEN 1 ELSE 0 END) AS due_today,
  SUM(CASE WHEN order_created_at >= f.d THEN 1 ELSE 0 END) AS created_today, MIN(order_created_at) AS oldest_created,
  MAX(m) AS oldest_m, MEDIAN(m) AS med_m, SUM(CASE WHEN m >= 1440 THEN 1 ELSE 0 END) AS over24
  FROM o CROSS JOIN f GROUP BY 1)
SELECT seller AS "Seller", pending AS "Pending", ROUND(100.0 * pending / SUM(pending) OVER (), 1) AS "Share %",
  wait_pick AS "Waiting to pick", picking AS "Picking", wait_pack AS "Waiting to pack", packing AS "Packing", wait_ship AS "Waiting to ship", on_hold AS "On hold",
  breached AS "Breached", due_today AS "Due today", created_today AS "New today", units AS "Units",
  ROUND(oldest_m / 60.0, 1) AS "Oldest (hrs)", ROUND(med_m / 60.0, 1) AS "Median age (hrs)", over24 AS "Over 24h", oldest_created AS "Oldest created"
FROM s ORDER BY pending DESC
