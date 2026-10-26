-- OB Floor – Breached backlog (open, past deadline)
-- Open B2C orders already past their COT deadline.

SELECT COUNT(*) AS "Breached open orders" FROM bosta_fulfillment.omniful_orders WHERE order_type = 'B2C' AND order_status IN ('NEW ORDER','IN PICKING','PICKED','IN PACKING','PACKED','READY TO SHIP','ON HOLD') AND CONVERT_TIMEZONE('Africa/Cairo', GETDATE()) >= CASE WHEN EXTRACT(HOUR FROM order_created_at) < 17 THEN DATE_TRUNC('day', order_created_at) + INTERVAL '1 day' ELSE DATE_TRUNC('day', order_created_at) + INTERVAL '2 day' END
