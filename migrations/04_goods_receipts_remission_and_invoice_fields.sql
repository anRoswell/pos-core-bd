-- =============================================================================
-- Migration 04: Add remission and invoice tracking columns to inventory.goods_receipts
-- Permite distinguir entre entradas con Remisión vs. Factura de Compra
-- y enlazar el cruce contable de la cuenta puente (220599)
-- =============================================================================

ALTER TABLE inventory.goods_receipts 
  ADD COLUMN IF NOT EXISTS document_type VARCHAR(30) DEFAULT 'INVOICE',
  ADD COLUMN IF NOT EXISTS supplier_remission_number VARCHAR(50),
  ADD COLUMN IF NOT EXISTS invoice_status VARCHAR(30) DEFAULT 'NOT_APPLICABLE',
  ADD COLUMN IF NOT EXISTS invoice_date DATE,
  ADD COLUMN IF NOT EXISTS subtotal DECIMAL(15, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS tax_amount DECIMAL(15, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS invoice_journal_entry_id UUID;

-- Índices para optimizar consultas de remisiones pendientes por facturar
CREATE INDEX IF NOT EXISTS idx_goods_receipts_invoice_status 
  ON inventory.goods_receipts (business_id, invoice_status) 
  WHERE document_type = 'REMISSION';

CREATE INDEX IF NOT EXISTS idx_goods_receipts_document_type 
  ON inventory.goods_receipts (business_id, document_type);
