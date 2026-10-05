-- Migration: 01_online_orders_and_webhooks.sql
-- Purpose: Extend webhook_event_enum, inventory_movement_type_enum, and online_orders table

-- 1. Extend webhook_event_enum
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'INVOICE_ISSUED';
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'PURCHASE_RECEIVED';
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'CASH_CLOSED';
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'invoice.issued';
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'purchase.received';
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'cash.closed';
ALTER TYPE webhook_event_enum ADD VALUE IF NOT EXISTS 'sale.completed';

-- 2. Extend inventory_movement_type_enum
ALTER TYPE inventory_movement_type_enum ADD VALUE IF NOT EXISTS 'OUT_ONLINE_ORDER';
ALTER TYPE inventory_movement_type_enum ADD VALUE IF NOT EXISTS 'OUT_SALE';
ALTER TYPE inventory_movement_type_enum ADD VALUE IF NOT EXISTS 'RETURN_IN';

-- 3. Extend online_orders table
ALTER TABLE online_orders ADD COLUMN IF NOT EXISTS confirmation_otp VARCHAR(10) DEFAULT '1234';
ALTER TABLE online_orders ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'CASH';
ALTER TABLE online_orders ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'PENDING';
