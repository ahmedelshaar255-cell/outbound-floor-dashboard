-- OB Floor – Step times today
-- How long each step took for B2C orders that finished it today. Within target = 2 hours per step, 24 hours created → shipped.

WITH p AS (SELECT CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE) AS d, DATEADD(day,1,CAST(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) AS DATE)) AS d1), c AS (
SELECT 1 AS k, 'Created → picked' AS step, COUNT(*) AS n, ROUND(AVG(m)/60.0,1) AS avg_h, ROUND(MEDIAN(m)/60.0,1) AS med_h, ROUND(100.0*SUM(CASE WHEN m <= 120 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),1) AS pct
FROM (SELECT DATEDIFF(minute, order_created_at, order_picked_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_picked_at >= p.d AND order_picked_at < p.d1) AND order_created_at IS NOT NULL) x
UNION ALL SELECT 2 AS k, 'Picked → packed' AS step, COUNT(*) AS n, ROUND(AVG(m)/60.0,1) AS avg_h, ROUND(MEDIAN(m)/60.0,1) AS med_h, ROUND(100.0*SUM(CASE WHEN m <= 120 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),1) AS pct
FROM (SELECT DATEDIFF(minute, order_picked_at, order_packed_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_packed_at >= p.d AND order_packed_at < p.d1) AND order_picked_at IS NOT NULL) x
UNION ALL SELECT 3 AS k, 'Packed → shipped' AS step, COUNT(*) AS n, ROUND(AVG(m)/60.0,1) AS avg_h, ROUND(MEDIAN(m)/60.0,1) AS med_h, ROUND(100.0*SUM(CASE WHEN m <= 120 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),1) AS pct
FROM (SELECT DATEDIFF(minute, order_packed_at, order_shipped_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1) AND order_packed_at IS NOT NULL) x
UNION ALL SELECT 4 AS k, 'Created → shipped' AS step, COUNT(*) AS n, ROUND(AVG(m)/60.0,1) AS avg_h, ROUND(MEDIAN(m)/60.0,1) AS med_h, ROUND(100.0*SUM(CASE WHEN m <= 1440 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0),1) AS pct
FROM (SELECT DATEDIFF(minute, order_created_at, order_shipped_at) AS m FROM bosta_fulfillment.omniful_orders CROSS JOIN p WHERE order_type = 'B2C' AND (order_shipped_at >= p.d AND order_shipped_at < p.d1) AND order_created_at IS NOT NULL) x)
SELECT step AS "Step", n AS "Orders done today", med_h AS "Median (hrs)", avg_h AS "Average (hrs)", pct AS "% within target" FROM c ORDER BY k
