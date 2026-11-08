-- =============================================================================
-- Migration 05: Add Remission Bridge Account (220599) and Withholding (236540)
-- to contable.accounting_puc_accounts for all existing and future businesses
-- =============================================================================

DO $$
DECLARE
    r RECORD;
    v_parent_2205 UUID;
    v_parent_2 UUID;
    v_parent_23 UUID;
    v_parent_2365 UUID;
BEGIN
    FOR r IN SELECT id FROM core.businesses LOOP
        -- 1. Asegurar cuenta 220599 (Remisiones por Facturar)
        SELECT id INTO v_parent_2205 
        FROM contable.accounting_puc_accounts 
        WHERE business_id = r.id AND code = '2205' LIMIT 1;

        IF v_parent_2205 IS NOT NULL THEN
            IF NOT EXISTS (
                SELECT 1 FROM contable.accounting_puc_accounts 
                WHERE business_id = r.id AND code = '220599'
            ) THEN
                INSERT INTO contable.accounting_puc_accounts 
                (id, business_id, code, name, nature, is_auxiliary, parent_id, created_at, updated_at)
                VALUES 
                (uuid_generate_v4(), r.id, '220599', 'Proveedores Nacionales - Remisiones por facturar', 'CREDIT', true, v_parent_2205, NOW(), NOW());
            END IF;
        END IF;

        -- 2. Asegurar cuentas 23, 2365 y 236540 (Retención en la fuente compras)
        SELECT id INTO v_parent_2 
        FROM contable.accounting_puc_accounts 
        WHERE business_id = r.id AND code = '2' LIMIT 1;

        SELECT id INTO v_parent_23 
        FROM contable.accounting_puc_accounts 
        WHERE business_id = r.id AND code = '23' LIMIT 1;

        IF v_parent_23 IS NULL AND v_parent_2 IS NOT NULL THEN
            INSERT INTO contable.accounting_puc_accounts 
            (id, business_id, code, name, nature, is_auxiliary, parent_id, created_at, updated_at)
            VALUES 
            (uuid_generate_v4(), r.id, '23', 'Cuentas por Pagar', 'CREDIT', false, v_parent_2, NOW(), NOW())
            RETURNING id INTO v_parent_23;
        END IF;

        IF v_parent_23 IS NOT NULL THEN
            SELECT id INTO v_parent_2365 
            FROM contable.accounting_puc_accounts 
            WHERE business_id = r.id AND code = '2365' LIMIT 1;

            IF v_parent_2365 IS NULL THEN
                INSERT INTO contable.accounting_puc_accounts 
                (id, business_id, code, name, nature, is_auxiliary, parent_id, created_at, updated_at)
                VALUES 
                (uuid_generate_v4(), r.id, '2365', 'Retención en la fuente', 'CREDIT', false, v_parent_23, NOW(), NOW())
                RETURNING id INTO v_parent_2365;
            END IF;

            IF NOT EXISTS (
                SELECT 1 FROM contable.accounting_puc_accounts 
                WHERE business_id = r.id AND code = '236540'
            ) THEN
                INSERT INTO contable.accounting_puc_accounts 
                (id, business_id, code, name, nature, is_auxiliary, parent_id, created_at, updated_at)
                VALUES 
                (uuid_generate_v4(), r.id, '236540', 'Retención en la fuente - Compras (2.5%)', 'CREDIT', true, v_parent_2365, NOW(), NOW());
            END IF;
        END IF;
    END LOOP;
END $$;

