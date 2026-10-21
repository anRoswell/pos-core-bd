-- Migration: 02_purchase_orders_payment_terms.sql
-- Purpose: Add payment_condition and payment_terms to inventory.purchase_orders

ALTER TABLE inventory.purchase_orders 
  ADD COLUMN IF NOT EXISTS payment_condition VARCHAR(30) DEFAULT 'CREDIT',
  ADD COLUMN IF NOT EXISTS payment_terms INT DEFAULT 30;
