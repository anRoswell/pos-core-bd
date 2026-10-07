-- =============================================================================
-- SEMILLA 03: PLAN ÚNICO DE CUENTAS (PUC COLOMBIA) Y MAPEO CONTABLE
-- =============================================================================

DO $$ 
DECLARE
    v_business_id UUID := '10000000-0000-0000-0000-000000000001';
    v_caja_id UUID;
    v_caja_menor_id UUID;
    v_bancos_id UUID;
    v_clientes_id UUID;
    v_inventario_id UUID;
    v_proveedores_id UUID;
    v_iva_generado_id UUID;
    v_iva_descontable_id UUID;
    v_impoconsumo_id UUID;
    v_ingresos_id UUID;
    v_sobrante_id UUID;
    v_faltante_id UUID;
    v_costos_id UUID;
BEGIN
    -- 1. Insertar Cuentas Principales (PUC Básico Comercial)
    
    -- ACTIVO
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '110505', 'Caja General', 'DEBIT', true) RETURNING id INTO v_caja_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '110510', 'Caja Menor / Turno POS', 'DEBIT', true) RETURNING id INTO v_caja_menor_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '111005', 'Bancos / Cuentas Corrientes', 'DEBIT', true) RETURNING id INTO v_bancos_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '130505', 'Clientes Nacionales', 'DEBIT', true) RETURNING id INTO v_clientes_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '143505', 'Mercancías no fabricadas por la empresa', 'DEBIT', true) RETURNING id INTO v_inventario_id;

    -- PASIVO
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '220505', 'Proveedores Nacionales', 'CREDIT', true) RETURNING id INTO v_proveedores_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '240805', 'Impuesto a las ventas por pagar - IVA Generado 19%', 'CREDIT', true) RETURNING id INTO v_iva_generado_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '240810', 'Impuesto a las ventas descontable - IVA Compras', 'DEBIT', true) RETURNING id INTO v_iva_descontable_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '249505', 'Impuesto Nacional al Consumo', 'CREDIT', true) RETURNING id INTO v_impoconsumo_id;

    -- INGRESOS
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '413536', 'Comercio al por menor - Ingresos operacionales', 'CREDIT', true) RETURNING id INTO v_ingresos_id;
    
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '429553', 'Ingresos diversos - Sobrante en caja', 'CREDIT', true) RETURNING id INTO v_sobrante_id;

    -- GASTOS
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '519525', 'Gastos extraordinarios - Faltante en caja', 'DEBIT', true) RETURNING id INTO v_faltante_id;

    -- COSTOS
    INSERT INTO contable.accounting_puc_accounts (id, business_id, code, name, nature, is_auxiliary) VALUES 
    (uuid_generate_v4(), v_business_id, '613536', 'Costo de ventas - Comercio al por menor', 'DEBIT', true) RETURNING id INTO v_costos_id;

    -- 2. Insertar Mapeos Automáticos de Conceptos Contables (Concept Mappings)
    
    -- Mapeo para Venta POS en Efectivo
    INSERT INTO contable.accounting_concept_mappings (business_id, concept_type, income_account_id, receivable_account_id, cash_account_id, tax_account_id)
    VALUES (v_business_id, 'SALE_CASH', v_ingresos_id, v_clientes_id, v_caja_id, v_iva_generado_id)
    ON CONFLICT DO NOTHING;

    -- Mapeo para Compras a Proveedores
    INSERT INTO contable.accounting_concept_mappings (business_id, concept_type, income_account_id, receivable_account_id, cash_account_id, tax_account_id)
    VALUES (v_business_id, 'PURCHASE_SUPPLIER', v_inventario_id, v_proveedores_id, v_caja_id, v_iva_descontable_id)
    ON CONFLICT DO NOTHING;

END $$;
