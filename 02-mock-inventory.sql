-- =====================================================================
-- SCRIPT DE MOCK DATA PARA INVENTARIO (PRODUCTOS Y STOCK)
-- =====================================================================

-- Variables base (Asumiendo que el script 01-init-schema.sql ya corrió)
DO $$
DECLARE
    v_business_id UUID := '10000000-0000-0000-0000-000000000001';
    v_branch_id UUID := 'b1000000-0000-0000-0000-000000000001';
    
    -- IDs Categorias
    v_cat_hamb UUID := uuid_generate_v4();
    v_cat_beb UUID := uuid_generate_v4();
    v_cat_parr UUID := uuid_generate_v4();
    v_cat_post UUID := uuid_generate_v4();
    
    -- IDs Productos
    v_prod_1 UUID := uuid_generate_v4();
    v_prod_2 UUID := uuid_generate_v4();
    v_prod_3 UUID := uuid_generate_v4();
    v_prod_4 UUID := uuid_generate_v4();
    v_prod_5 UUID := uuid_generate_v4();
    v_prod_6 UUID := uuid_generate_v4();

BEGIN
    -- 1. Crear Categorías
    INSERT INTO categories (id, business_id, name, code, color, orden, is_active)
    VALUES 
    (v_cat_hamb, v_business_id, 'Hamburguesas & Sandwiches', 'HAMB', '#F59E0B', 2, TRUE),
    (v_cat_beb, v_business_id, 'Bebidas & Refrescos', 'BEB', '#3B82F6', 3, TRUE),
    (v_cat_parr, v_business_id, 'Parrilla & Carnes', 'PARR', '#EF4444', 4, TRUE),
    (v_cat_post, v_business_id, 'Postres & Repostería', 'POST', '#EC4899', 5, TRUE)
    ON CONFLICT (business_id, name) DO NOTHING;

    -- Obtener IDs reales en caso de que ya existieran por un conflicto de nombre (para no romper las FKs)
    SELECT id INTO v_cat_hamb FROM categories WHERE business_id = v_business_id AND name = 'Hamburguesas & Sandwiches';
    SELECT id INTO v_cat_beb FROM categories WHERE business_id = v_business_id AND name = 'Bebidas & Refrescos';
    SELECT id INTO v_cat_parr FROM categories WHERE business_id = v_business_id AND name = 'Parrilla & Carnes';
    SELECT id INTO v_cat_post FROM categories WHERE business_id = v_business_id AND name = 'Postres & Repostería';

    -- 2. Crear Productos
    INSERT INTO products (id, business_id, category_id, sku, barcode, name, description, price, cost, tax_rate, unit_type, status)
    VALUES
    (v_prod_1, v_business_id, v_cat_hamb, 'SKU-HAMB-001', '10001', 'Hamburguesa Angus Artesanal 200g', 'Hamburguesa 200g', 29000, 14500, 19, 'UNIT', 'ACTIVE'),
    (v_prod_2, v_business_id, v_cat_hamb, 'SKU-HAMB-002', '10002', 'Hamburguesa BBQ Doble Carne', 'Hamburguesa BBQ', 34000, 16000, 19, 'UNIT', 'ACTIVE'),
    (v_prod_3, v_business_id, v_cat_beb, 'SKU-BEB-001', '10003', 'Gaseosa Coca-Cola 400ml', 'Gaseosa', 4500, 2100, 19, 'UNIT', 'ACTIVE'),
    (v_prod_4, v_business_id, v_cat_beb, 'SKU-BEB-002', '10004', 'Cerveza Artesanal IPA 330ml', 'Cerveza', 11000, 5500, 19, 'UNIT', 'ACTIVE'),
    (v_prod_5, v_business_id, v_cat_parr, 'SKU-PARR-001', '10005', 'Bife de Chorizo Premium 350g', 'Bife de Chorizo', 49000, 28000, 19, 'UNIT', 'ACTIVE'),
    (v_prod_6, v_business_id, v_cat_post, 'SKU-POST-001', '10006', 'Torta Tres Leches Casera', 'Torta Tres Leches', 9500, 4500, 19, 'UNIT', 'ACTIVE')
    ON CONFLICT (business_id, sku) DO NOTHING;

    -- Obtener IDs reales de productos
    SELECT id INTO v_prod_1 FROM products WHERE business_id = v_business_id AND sku = 'SKU-HAMB-001';
    SELECT id INTO v_prod_2 FROM products WHERE business_id = v_business_id AND sku = 'SKU-HAMB-002';
    SELECT id INTO v_prod_3 FROM products WHERE business_id = v_business_id AND sku = 'SKU-BEB-001';
    SELECT id INTO v_prod_4 FROM products WHERE business_id = v_business_id AND sku = 'SKU-BEB-002';
    SELECT id INTO v_prod_5 FROM products WHERE business_id = v_business_id AND sku = 'SKU-PARR-001';
    SELECT id INTO v_prod_6 FROM products WHERE business_id = v_business_id AND sku = 'SKU-POST-001';

    -- 3. Crear Stock (Inventario)
    INSERT INTO inventory_stock (business_id, branch_id, product_id, quantity, min_stock, max_stock, reorder_point)
    VALUES
    (v_business_id, v_branch_id, v_prod_1, 45, 10, 100, 15),
    (v_business_id, v_branch_id, v_prod_2, 8, 12, 50, 15),
    (v_business_id, v_branch_id, v_prod_3, 120, 24, 200, 30),
    (v_business_id, v_branch_id, v_prod_4, 60, 15, 120, 20),
    (v_business_id, v_branch_id, v_prod_5, 18, 5, 30, 8),
    (v_business_id, v_branch_id, v_prod_6, 15, 4, 25, 6)
    ON CONFLICT DO NOTHING;

END $$;
