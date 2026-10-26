-- OB Floor – Data status
-- When Metabase last received B2C order data from Omniful, the current Cairo time and how far behind the data is.

SELECT MAX(order_updated_at) AS "Data up to (Cairo)", MAX(CONVERT_TIMEZONE('Africa/Cairo', GETDATE())) AS "Checked at (Cairo)",
  DATEDIFF(minute, MAX(order_updated_at), MAX(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()))) AS "Minutes behind",
  CASE WHEN DATEDIFF(minute, MAX(order_updated_at), MAX(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()))) <= 70 THEN 'Current' WHEN DATEDIFF(minute, MAX(order_updated_at), MAX(CONVERT_TIMEZONE('Africa/Cairo', GETDATE()))) <= 180 THEN 'Delayed' ELSE 'Not updating' END AS "Status"
FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_updated_at >= DATEADD(day,-3,CURRENT_DATE)
