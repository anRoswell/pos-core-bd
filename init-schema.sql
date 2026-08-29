-- =============================================================================
-- POS CORE OS - ESQUEMA DE BASE DE DATOS (FASE 1 & 2: CORE, TPV, CAJA & CRÉDITO)
-- Soporte: PostgreSQL 14+
-- Módulos: Multi-Tenant, RBAC, Multi-Sucursal, TPV (Terminal Punto de Venta),
--          Control de Caja & Cierre de Turno, Cuentas por Cobrar & Crédito
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- TIPOS ENUMERADOS (Cero Magic Strings)
-- -----------------------------------------------------------------------------
DO $$ BEGIN
    -- Fase 1 Enums
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'business_status_enum') THEN
        CREATE TYPE business_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status_enum') THEN
        CREATE TYPE user_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'BLOCKED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_type_enum') THEN
        CREATE TYPE document_type_enum AS ENUM ('CC', 'CE', 'NIT', 'PASSPORT', 'OTHER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'branch_type_enum') THEN
        CREATE TYPE branch_type_enum AS ENUM ('STORE', 'WAREHOUSE', 'DISTRIBUTION_CENTER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transfer_status_enum') THEN
        CREATE TYPE transfer_status_enum AS ENUM ('PENDING', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transfer_priority_enum') THEN
        CREATE TYPE transfer_priority_enum AS ENUM ('NORMAL', 'URGENT', 'EXPRESS');
    END IF;

    -- Fase 2 Enums
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'product_status_enum') THEN
        CREATE TYPE product_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'DISCONTINUED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'unit_type_enum') THEN
        CREATE TYPE unit_type_enum AS ENUM ('UNIT', 'KG', 'GRAM', 'LITER', 'PORTION', 'BOX');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sale_status_enum') THEN
        CREATE TYPE sale_status_enum AS ENUM ('COMPLETED', 'PENDING', 'CANCELLED', 'REFUNDED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_enum') THEN
        CREATE TYPE payment_method_enum AS ENUM ('CASH', 'CARD', 'NEQUI', 'DAVIPLATA', 'TRANSFER', 'CREDIT', 'POINTS', 'OTHER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_status_enum') THEN
        CREATE TYPE session_status_enum AS ENUM ('OPEN', 'CLOSED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cash_movement_type_enum') THEN
        CREATE TYPE cash_movement_type_enum AS ENUM ('OPENING_BASE', 'SALE', 'WITHDRAWAL', 'EXPENSE', 'INCOME', 'CREDIT_PAYMENT', 'ADJUSTMENT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'denomination_type_enum') THEN
        CREATE TYPE denomination_type_enum AS ENUM ('BILL', 'COIN');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'credit_account_status_enum') THEN
        CREATE TYPE credit_account_status_enum AS ENUM ('PENDING', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'WRITE_OFF');
    END IF;

    -- Fase 3 Enums (Inventario, Lotes, Compras, Facturación DIAN)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inventory_movement_type_enum') THEN
        CREATE TYPE inventory_movement_type_enum AS ENUM ('SALE', 'PURCHASE', 'ADJUSTMENT_IN', 'ADJUSTMENT_OUT', 'TRANSFER_IN', 'TRANSFER_OUT', 'EXPIRATION_WASTE');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'physical_count_status_enum') THEN
        CREATE TYPE physical_count_status_enum AS ENUM ('OPEN', 'COMPLETED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lot_status_enum') THEN
        CREATE TYPE lot_status_enum AS ENUM ('ACTIVE', 'NEAR_EXPIRATION', 'EXPIRED', 'DEPLETED', 'QUARANTINE');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'supplier_status_enum') THEN
        CREATE TYPE supplier_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'BLOCKED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'purchase_order_status_enum') THEN
        CREATE TYPE purchase_order_status_enum AS ENUM ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'SENT', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'goods_receipt_status_enum') THEN
        CREATE TYPE goods_receipt_status_enum AS ENUM ('COMPLETED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_payable_status_enum') THEN
        CREATE TYPE account_payable_status_enum AS ENUM ('PENDING', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_type_enum') THEN
        CREATE TYPE invoice_type_enum AS ENUM ('ELECTRONIC_INVOICE', 'POS_INVOICE', 'CREDIT_NOTE', 'DEBIT_NOTE');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dian_status_enum') THEN
        CREATE TYPE dian_status_enum AS ENUM ('PENDING', 'VALIDATED', 'REJECTED', 'ANNULLED');
    END IF;

    -- Fase 4 Enums (Restaurantes, Mesas, Comandas, KDS Cocina)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'table_shape_enum') THEN
        CREATE TYPE table_shape_enum AS ENUM ('SQUARE', 'ROUND', 'RECTANGLE', 'BAR');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'table_status_enum') THEN
        CREATE TYPE table_status_enum AS ENUM ('FREE', 'OCCUPIED', 'BILL_REQUESTED', 'CLEANING', 'RESERVED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'table_order_status_enum') THEN
        CREATE TYPE table_order_status_enum AS ENUM ('OPEN', 'PRINTED_BILL', 'PAID', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kitchen_station_enum') THEN
        CREATE TYPE kitchen_station_enum AS ENUM ('KITCHEN_HOT', 'KITCHEN_COLD', 'BAR', 'DESSERT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kitchen_item_status_enum') THEN
        CREATE TYPE kitchen_item_status_enum AS ENUM ('PENDING', 'IN_PREPARATION', 'READY', 'DELIVERED');
    END IF;

    -- Fase 5 Enums (CRM, Fidelización, Promociones, Delivery, Notificaciones, Automatizaciones)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'crm_segment_enum') THEN
        CREATE TYPE crm_segment_enum AS ENUM ('CHAMPION', 'LOYAL', 'POTENTIAL_LOYALIST', 'NEW_CUSTOMER', 'AT_RISK', 'HIBERNATING', 'PROMO_HUNTER', 'INACTIVE', 'VIP', 'FREQUENT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'crm_trigger_type_enum') THEN
        CREATE TYPE crm_trigger_type_enum AS ENUM ('BIRTHDAY', 'WELCOME_FIRST_PURCHASE', 'INACTIVITY_REACTIVATION', 'TIER_UPGRADE', 'HIGH_TICKET_PURCHASE');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'campaign_channel_enum') THEN
        CREATE TYPE campaign_channel_enum AS ENUM ('EMAIL', 'SMS', 'WHATSAPP', 'PUSH_NOTIFICATION');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'campaign_status_enum') THEN
        CREATE TYPE campaign_status_enum AS ENUM ('DRAFT', 'SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'loyalty_tier_enum') THEN
        CREATE TYPE loyalty_tier_enum AS ENUM ('BRONZE', 'SILVER', 'GOLD', 'DIAMOND');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'loyalty_transaction_type_enum') THEN
        CREATE TYPE loyalty_transaction_type_enum AS ENUM ('EARNED', 'REDEEMED', 'EXPIRED', 'ADJUSTMENT');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'promotion_type_enum') THEN
        CREATE TYPE promotion_type_enum AS ENUM ('PERCENTAGE_DISCOUNT', 'FIXED_AMOUNT_DISCOUNT', 'BUY_X_GET_Y', 'COMBO_SPECIAL', 'FREE_SHIPPING');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'online_order_channel_enum') THEN
        CREATE TYPE online_order_channel_enum AS ENUM ('WEB_STORE', 'MOBILE_APP', 'WHATSAPP_BOT', 'EXTERNAL_INTEGRATION');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'online_order_status_enum') THEN
        CREATE TYPE online_order_status_enum AS ENUM ('ORDER_PLACED', 'ACCEPTED', 'IN_PREPARATION', 'ON_THE_WAY', 'DELIVERED', 'CANCELLED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_type_enum') THEN
        CREATE TYPE delivery_type_enum AS ENUM ('DELIVERY', 'PICKUP');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_status_enum') THEN
        CREATE TYPE notification_status_enum AS ENUM ('QUEUED', 'SENT', 'FAILED', 'DELIVERED');
    END IF;

    -- Fase 6 Enums (API Pública, Webhooks, IA & Seguridad Forense)
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'api_key_status_enum') THEN
        CREATE TYPE api_key_status_enum AS ENUM ('ACTIVE', 'REVOKED', 'EXPIRED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'webhook_event_enum') THEN
        CREATE TYPE webhook_event_enum AS ENUM ('SALE_COMPLETED', 'SALE_CANCELLED', 'INVENTORY_LOW_STOCK', 'ONLINE_ORDER_CREATED', 'ONLINE_ORDER_DELIVERED', 'CUSTOMER_CREATED');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'webhook_delivery_status_enum') THEN
        CREATE TYPE webhook_delivery_status_enum AS ENUM ('SUCCESS', 'FAILED', 'RETRYING');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ai_prediction_type_enum') THEN
        CREATE TYPE ai_prediction_type_enum AS ENUM ('DEMAND_FORECAST', 'CROSS_SELL_RECOMMENDATION', 'ANOMALY_DETECTION');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'anomaly_severity_enum') THEN
        CREATE TYPE anomaly_severity_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 1. TABLA BUSINESSES (Inquilinos / Empresas Multi-Tenant)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255),
    tax_id VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Colombia',
    logo_url VARCHAR(500),
    status business_status_enum NOT NULL DEFAULT 'ACTIVE',
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- -----------------------------------------------------------------------------
-- 2. TABLA PARAMETROS (Catálogo Dinámico Centralizado)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS parametros (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    modulo VARCHAR(100) NOT NULL,
    clave VARCHAR(100) NOT NULL,
    valor VARCHAR(255) NOT NULL,
    etiqueta VARCHAR(255) NOT NULL,
    tipo_dato VARCHAR(50) NOT NULL DEFAULT 'STRING',
    descripcion TEXT,
    orden INTEGER NOT NULL DEFAULT 0,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_parametro_clave_business UNIQUE (business_id, modulo, clave, valor)
);

CREATE INDEX IF NOT EXISTS idx_parametros_modulo_bus ON parametros (modulo, business_id, estado);

-- -----------------------------------------------------------------------------
-- 3. TABLA ROLES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_role_slug_business UNIQUE (business_id, slug)
);

-- -----------------------------------------------------------------------------
-- 4. TABLA PERMISSIONS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    slug VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_permissions_module ON permissions (module);

-- -----------------------------------------------------------------------------
-- 5. TABLA ROLE_PERMISSIONS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- -----------------------------------------------------------------------------
-- 6. TABLA USERS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    document_type document_type_enum NOT NULL DEFAULT 'CC',
    document_number VARCHAR(50),
    password_hash VARCHAR(255) NOT NULL,
    pin_hash VARCHAR(255),
    role_id UUID REFERENCES roles(id) ON DELETE RESTRICT,
    status user_status_enum NOT NULL DEFAULT 'ACTIVE',
    blocked_until TIMESTAMP WITH TIME ZONE,
    blocked_reason TEXT,
    failed_login_attempts INTEGER NOT NULL DEFAULT 0,
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip VARCHAR(45),
    password_changed_at TIMESTAMP WITH TIME ZONE,
    must_change_password BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_users_email_business UNIQUE (business_id, email)
);

CREATE INDEX IF NOT EXISTS idx_users_business_status ON users (business_id, status);

-- -----------------------------------------------------------------------------
-- 7. TABLA USER_ROLES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- -----------------------------------------------------------------------------
-- 8. TABLA REFRESH_TOKENS
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    user_agent VARCHAR(255),
    ip_address VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 9. TABLA BRANCHES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20) NOT NULL,
    type branch_type_enum NOT NULL DEFAULT 'STORE',
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
    parent_branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    schedule JSONB DEFAULT '{"monday": {"open": "08:00", "close": "20:00"}}'::jsonb,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_branch_code_business UNIQUE (business_id, code)
);

-- -----------------------------------------------------------------------------
-- 10. TABLA USER_BRANCHES
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_branches (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, branch_id)
);

-- -----------------------------------------------------------------------------
-- 11. TABLA TIME_TRACKING
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS time_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    clock_in TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    clock_out TIMESTAMP WITH TIME ZONE,
    hours_worked DECIMAL(5, 2),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 12. TABLA AUDIT_LOG
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID REFERENCES businesses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(100),
    details JSONB DEFAULT '{}'::jsonb,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FASE 2: TABLAS DE PRODUCTOS, CLIENTES, CAJAS, VENTAS POS Y CRÉDITO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 13. TABLA CATEGORIES (Categorías de Productos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50),
    color VARCHAR(20) DEFAULT '#6366F1',
    icon VARCHAR(50) DEFAULT 'tag',
    orden INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_category_name_business UNIQUE (business_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_business ON categories (business_id, is_active);

-- -----------------------------------------------------------------------------
-- 14. TABLA PRODUCTS (Catálogo Maestro de Productos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    sku VARCHAR(50) NOT NULL,
    barcode VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    cost DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 19.00, -- IVA estándar 19%, 5%, 0%
    track_inventory BOOLEAN NOT NULL DEFAULT TRUE,
    unit_type unit_type_enum NOT NULL DEFAULT 'UNIT',
    image_url VARCHAR(500),
    status product_status_enum NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_product_sku_business UNIQUE (business_id, sku)
);

CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (business_id, barcode);
CREATE INDEX IF NOT EXISTS idx_products_category ON products (business_id, category_id);

-- -----------------------------------------------------------------------------
-- 15. TABLA CUSTOMERS (Directorio de Clientes CRM)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_number VARCHAR(30) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(255),
    document_type document_type_enum NOT NULL DEFAULT 'CC',
    document_number VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customer_number_business UNIQUE (business_id, customer_number)
);

CREATE INDEX IF NOT EXISTS idx_customers_search ON customers (business_id, document_number, phone);

-- -----------------------------------------------------------------------------
-- 16. TABLA CASH_REGISTERS (Cajas Físicas / Terminales de Sucursal)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cash_registers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,          -- ej: 'Caja Principal 01'
    code VARCHAR(20) NOT NULL,           -- ej: 'CAJA-01'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cash_register_code UNIQUE (branch_id, code)
);

-- -----------------------------------------------------------------------------
-- 17. TABLA CASH_REGISTER_SESSIONS (Turnos de Caja y Arqueos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cash_register_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    cash_register_id UUID NOT NULL REFERENCES cash_registers(id) ON DELETE RESTRICT,
    cashier_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    session_number VARCHAR(30) NOT NULL,
    opening_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closing_date TIMESTAMP WITH TIME ZONE,
    opening_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    expected_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    counted_amount DECIMAL(15, 2),
    difference DECIMAL(15, 2),
    total_sales_cash DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_sales_card DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_sales_digital DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_sales_credit DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_withdrawals DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_expenses DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total_other_income DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    transactions_count INTEGER NOT NULL DEFAULT 0,
    status session_status_enum NOT NULL DEFAULT 'OPEN',
    opening_notes TEXT,
    closing_notes TEXT,
    supervisor_approval_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_active ON cash_register_sessions (cash_register_id, status);

-- -----------------------------------------------------------------------------
-- 18. TABLA CASH_MOVEMENTS (Movimientos de Efectivo en Turno)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cash_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES cash_register_sessions(id) ON DELETE CASCADE,
    type cash_movement_type_enum NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100),
    reference_type VARCHAR(50),          -- 'sale', 'expense_voucher', 'credit_receipt'
    reference_id UUID,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cash_movements_session ON cash_movements (session_id, type);

-- -----------------------------------------------------------------------------
-- 19. TABLA CASH_DENOMINATIONS (Desglose de Billetes y Monedas en Arqueo)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cash_denominations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES cash_register_sessions(id) ON DELETE CASCADE,
    denomination_value DECIMAL(12, 2) NOT NULL, -- ej: 50000, 20000, 10000, 500, 200...
    quantity INTEGER NOT NULL DEFAULT 0,
    subtotal DECIMAL(15, 2) NOT NULL,
    type denomination_type_enum NOT NULL DEFAULT 'BILL',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 20. TABLA SALES (Ventas POS / Facturas de Venta)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    cash_register_id UUID NOT NULL REFERENCES cash_registers(id) ON DELETE RESTRICT,
    session_id UUID REFERENCES cash_register_sessions(id) ON DELETE SET NULL,
    cashier_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    sale_number VARCHAR(30) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    status sale_status_enum NOT NULL DEFAULT 'COMPLETED',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_sales_number_business UNIQUE (business_id, sale_number)
);

CREATE INDEX IF NOT EXISTS idx_sales_business_branch ON sales (business_id, branch_id, created_at);

-- -----------------------------------------------------------------------------
-- 21. TABLA SALE_ITEMS (Líneas de Detalle de Venta)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    product_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 3) NOT NULL DEFAULT 1.000,
    unit_price DECIMAL(12, 2) NOT NULL,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 19.00,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12, 2) NOT NULL,
    total DECIMAL(12, 2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items (sale_id);

-- -----------------------------------------------------------------------------
-- 22. TABLA SALE_PAYMENTS (Formas de Pago Aplicadas - Soporte Pago Mixto)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sale_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    session_id UUID REFERENCES cash_register_sessions(id) ON DELETE SET NULL,
    payment_method payment_method_enum NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    reference VARCHAR(100),              -- Voucher, número de transacción o autorización
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sale_payments_sale ON sale_payments (sale_id);

-- -----------------------------------------------------------------------------
-- 23. TABLA CUSTOMER_CREDIT_PROFILES (Perfiles de Crédito de Clientes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_credit_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE UNIQUE,
    credit_limit DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    current_debt DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    payment_term_days INTEGER NOT NULL DEFAULT 30,
    is_credit_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    block_reason VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 24. TABLA ACCOUNTS_RECEIVABLE (Cuentas por Cobrar / Cartera)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS accounts_receivable (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    total_amount DECIMAL(14, 2) NOT NULL,
    paid_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    balance_due DECIMAL(14, 2) NOT NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    status credit_account_status_enum NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ar_customer_status ON accounts_receivable (customer_id, status);

-- -----------------------------------------------------------------------------
-- 25. TABLA CUSTOMER_PAYMENT_RECEIPTS (Recibos de Caja / Abonos)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_payment_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    session_id UUID REFERENCES cash_register_sessions(id) ON DELETE SET NULL,
    receipt_number VARCHAR(30) NOT NULL,
    amount_paid DECIMAL(14, 2) NOT NULL,
    payment_method payment_method_enum NOT NULL DEFAULT 'CASH',
    reference VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_receipt_number_business UNIQUE (business_id, receipt_number)
);

-- -----------------------------------------------------------------------------
-- 26. TABLA CUSTOMER_PAYMENT_RECEIPT_ITEMS (Detalle de Aplicación de Abono)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_payment_receipt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receipt_id UUID NOT NULL REFERENCES customer_payment_receipts(id) ON DELETE CASCADE,
    account_receivable_id UUID NOT NULL REFERENCES accounts_receivable(id) ON DELETE RESTRICT,
    amount_applied DECIMAL(14, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FASE 3: LOGÍSTICA, INVENTARIO, LOTES, COMPRAS Y FACTURACIÓN ELECTRÓNICA DIAN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 27. TABLA PRODUCT_VARIANTS (Variantes de Producto: Tallas, Colores, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku VARCHAR(50) NOT NULL,
    barcode VARCHAR(50),
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb, -- ej: {"color": "Rojo", "talla": "M"}
    price_adjustment DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    cost_adjustment DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    image_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_variant_sku_business UNIQUE (business_id, sku)
);

CREATE INDEX IF NOT EXISTS idx_product_variants_product ON product_variants (product_id);

-- -----------------------------------------------------------------------------
-- 28. TABLA INVENTORY_STOCK (Existencias por Sucursal y Variante)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    quantity DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    reserved DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    available DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    min_stock DECIMAL(12, 3) NOT NULL DEFAULT 5.000,
    max_stock DECIMAL(12, 3) NOT NULL DEFAULT 100.000,
    reorder_point DECIMAL(12, 3) NOT NULL DEFAULT 10.000,
    version INTEGER NOT NULL DEFAULT 1,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stock_branch_product ON inventory_stock (branch_id, product_id, variant_id);

-- -----------------------------------------------------------------------------
-- 29. TABLA INVENTORY_MOVEMENTS (Kardex Valorizado Inmutable)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    type inventory_movement_type_enum NOT NULL,
    quantity DECIMAL(12, 3) NOT NULL, -- Positivo para entradas, negativo para salidas
    unit_cost DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    previous_stock DECIMAL(12, 3) NOT NULL,
    new_stock DECIMAL(12, 3) NOT NULL,
    reference_type VARCHAR(50) NOT NULL, -- 'sale', 'purchase_order', 'transfer', 'physical_count', 'adjustment'
    reference_id UUID,
    reason VARCHAR(255),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_inv_movements_product ON inventory_movements (product_id, branch_id, created_at);

-- -----------------------------------------------------------------------------
-- 30. TABLA INVENTORY_TRANSFERS (Traslados entre Sucursales)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_transfers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    transfer_number VARCHAR(30) NOT NULL,
    from_branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    to_branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    status transfer_status_enum NOT NULL DEFAULT 'PENDING',
    priority transfer_priority_enum NOT NULL DEFAULT 'NORMAL',
    notes TEXT,
    requested_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    received_by UUID REFERENCES users(id) ON DELETE SET NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    received_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_transfer_number_business UNIQUE (business_id, transfer_number)
);

-- -----------------------------------------------------------------------------
-- 31. TABLA INVENTORY_TRANSFER_ITEMS (Detalle de Traslados)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS inventory_transfer_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transfer_id UUID NOT NULL REFERENCES inventory_transfers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    quantity_requested DECIMAL(12, 3) NOT NULL,
    quantity_sent DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    quantity_received DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 32. TABLA PHYSICAL_COUNTS (Sesiones de Conteo Físico / Auditoría de Bodega)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS physical_counts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    count_number VARCHAR(30) NOT NULL,
    status physical_count_status_enum NOT NULL DEFAULT 'OPEN',
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_count_number_business UNIQUE (business_id, count_number)
);

-- -----------------------------------------------------------------------------
-- 33. TABLA PHYSICAL_COUNT_ITEMS (Líneas Escaneadas en Conteo Físico)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS physical_count_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    count_id UUID NOT NULL REFERENCES physical_counts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    system_quantity DECIMAL(12, 3) NOT NULL,
    counted_quantity DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    difference DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    adjusted BOOLEAN NOT NULL DEFAULT FALSE,
    notes VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 34. TABLA PRODUCT_LOTS (Gestión de Lotes y Vencimientos - FEFO)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_lots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    lot_number VARCHAR(50) NOT NULL,
    manufacture_date DATE,
    expiration_date DATE NOT NULL,
    initial_quantity DECIMAL(12, 3) NOT NULL,
    current_quantity DECIMAL(12, 3) NOT NULL,
    unit_cost DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    status lot_status_enum NOT NULL DEFAULT 'ACTIVE',
    sanitary_registry_invima VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_lot_number_product UNIQUE (business_id, product_id, lot_number)
);

CREATE INDEX IF NOT EXISTS idx_lots_fefo ON product_lots (product_id, branch_id, expiration_date ASC);

-- -----------------------------------------------------------------------------
-- 35. TABLA SUPPLIERS (Proveedores Comerciales)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    supplier_code VARCHAR(20) NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255) NOT NULL,
    tax_id VARCHAR(50) NOT NULL,
    contact_name VARCHAR(255),
    phone VARCHAR(30),
    email VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    payment_terms INTEGER NOT NULL DEFAULT 30, -- Días de crédito
    rating DECIMAL(3, 2) DEFAULT 5.00,
    total_purchases DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    status supplier_status_enum NOT NULL DEFAULT 'ACTIVE',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_supplier_code_business UNIQUE (business_id, supplier_code),
    CONSTRAINT uq_supplier_tax_id_business UNIQUE (business_id, tax_id)
);

-- -----------------------------------------------------------------------------
-- 36. TABLA PURCHASE_ORDERS (Órdenes de Compra)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    order_number VARCHAR(30) NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_date DATE,
    subtotal DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    status purchase_order_status_enum NOT NULL DEFAULT 'DRAFT',
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_order_number_business UNIQUE (business_id, order_number)
);

-- -----------------------------------------------------------------------------
-- 37. TABLA PURCHASE_ORDER_ITEMS (Líneas de Detalle de Orden de Compra)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    quantity_ordered DECIMAL(12, 3) NOT NULL,
    quantity_received DECIMAL(12, 3) NOT NULL DEFAULT 0.000,
    unit_cost DECIMAL(12, 2) NOT NULL,
    tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 19.00,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12, 2) NOT NULL,
    total DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 38. TABLA GOODS_RECEIPTS (Recepción Física de Mercancía en Muelle/Bodega)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS goods_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    receipt_number VARCHAR(30) NOT NULL,
    received_date DATE NOT NULL DEFAULT CURRENT_DATE,
    supplier_invoice_number VARCHAR(50),
    total_received_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    status goods_receipt_status_enum NOT NULL DEFAULT 'COMPLETED',
    received_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_goods_receipt_number_business UNIQUE (business_id, receipt_number)
);

-- -----------------------------------------------------------------------------
-- 39. TABLA GOODS_RECEIPT_ITEMS (Detalle de Mercancía Recibida)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS goods_receipt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    goods_receipt_id UUID NOT NULL REFERENCES goods_receipts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES product_variants(id) ON DELETE SET NULL,
    lot_id UUID REFERENCES product_lots(id) ON DELETE SET NULL,
    quantity_received DECIMAL(12, 3) NOT NULL,
    unit_cost DECIMAL(12, 2) NOT NULL,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 40. TABLA ACCOUNTS_PAYABLE (Cuentas por Pagar a Proveedores)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS accounts_payable (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    purchase_order_id UUID REFERENCES purchase_orders(id) ON DELETE SET NULL,
    goods_receipt_id UUID REFERENCES goods_receipts(id) ON DELETE SET NULL,
    bill_number VARCHAR(50) NOT NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    balance_due DECIMAL(15, 2) NOT NULL,
    status account_payable_status_enum NOT NULL DEFAULT 'PENDING',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 41. TABLA SUPPLIER_PAYMENTS (Pagos Efectuados a Proveedores)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS supplier_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    account_payable_id UUID NOT NULL REFERENCES accounts_payable(id) ON DELETE RESTRICT,
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    payment_number VARCHAR(30) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount DECIMAL(15, 2) NOT NULL,
    payment_method payment_method_enum NOT NULL DEFAULT 'TRANSFER',
    reference VARCHAR(100),
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_supplier_payment_number_business UNIQUE (business_id, payment_number)
);

-- -----------------------------------------------------------------------------
-- 42. TABLA DIAN_RESOLUTIONS (Resoluciones de Facturación DIAN)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dian_resolutions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    resolution_number VARCHAR(50) NOT NULL,
    prefix VARCHAR(10) NOT NULL,
    from_number BIGINT NOT NULL,
    to_number BIGINT NOT NULL,
    current_number BIGINT NOT NULL,
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    technical_key VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_dian_res_prefix_business UNIQUE (business_id, prefix)
);

-- -----------------------------------------------------------------------------
-- 43. TABLA INVOICES (Facturas Electrónicas DIAN)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    resolution_id UUID REFERENCES dian_resolutions(id) ON DELETE RESTRICT,
    type invoice_type_enum NOT NULL DEFAULT 'ELECTRONIC_INVOICE',
    invoice_number VARCHAR(50) NOT NULL,
    cufe VARCHAR(120),
    customer_nit VARCHAR(20) NOT NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255),
    customer_address TEXT,
    subtotal DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    qr_code TEXT,
    dian_status dian_status_enum NOT NULL DEFAULT 'PENDING',
    dian_response JSONB,
    dian_validated_at TIMESTAMP WITH TIME ZONE,
    email_sent_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_invoice_number_business UNIQUE (business_id, invoice_number)
);

-- -----------------------------------------------------------------------------
-- 44. TABLA INVOICE_ITEMS (Líneas de Detalle de Factura Electrónica)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE RESTRICT,
    product_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(12, 3) NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 19.00,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12, 2) NOT NULL,
    total DECIMAL(12, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 45. TABLA CREDIT_DEBIT_NOTES (Notas Crédito y Débito Electrónicas)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS credit_debit_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    original_invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
    note_number VARCHAR(50) NOT NULL,
    type invoice_type_enum NOT NULL DEFAULT 'CREDIT_NOTE',
    cude VARCHAR(120),
    reason TEXT NOT NULL,
    subtotal DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    dian_status dian_status_enum NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_note_number_business UNIQUE (business_id, note_number)
);

-- =============================================================================
-- FASE 4: ESPECIALIZACIÓN DE NICHO (RESTAURANTES, MESAS, COMANDAS & KDS COCINA)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 46. TABLA RESTAURANT_ZONES (Zonas del Restaurante: Salón, Terraza, Barra, VIP)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS restaurant_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name VARCHAR(60) NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_zone_name_branch UNIQUE (branch_id, name)
);

-- -----------------------------------------------------------------------------
-- 47. TABLA RESTAURANT_TABLES (Mesas Físicas con Coordenadas para Plano Visual)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS restaurant_tables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    zone_id UUID NOT NULL REFERENCES restaurant_zones(id) ON DELETE CASCADE,
    table_number VARCHAR(20) NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 4,
    pos_x INTEGER NOT NULL DEFAULT 0,
    pos_y INTEGER NOT NULL DEFAULT 0,
    shape table_shape_enum NOT NULL DEFAULT 'SQUARE',
    current_status table_status_enum NOT NULL DEFAULT 'FREE',
    current_order_id UUID,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_table_number_branch UNIQUE (branch_id, table_number)
);

CREATE INDEX IF NOT EXISTS idx_tables_zone ON restaurant_tables (zone_id, current_status);

-- -----------------------------------------------------------------------------
-- 48. TABLA RESTAURANT_TABLE_ORDERS (Comandas de Mesa en Salón)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS restaurant_table_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    table_id UUID NOT NULL REFERENCES restaurant_tables(id) ON DELETE RESTRICT,
    waiter_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    covers_count INTEGER NOT NULL DEFAULT 1,
    subtotal DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    tip_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    status table_order_status_enum NOT NULL DEFAULT 'OPEN',
    notes TEXT,
    opened_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    printed_bill_at TIMESTAMP WITH TIME ZONE,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 49. TABLA RESTAURANT_ORDER_ITEMS (Platos, Bebidas & Modificadores de Comanda)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS restaurant_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES restaurant_table_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    station kitchen_station_enum NOT NULL DEFAULT 'KITCHEN_HOT',
    quantity DECIMAL(12, 3) NOT NULL DEFAULT 1.000,
    unit_price DECIMAL(12, 2) NOT NULL,
    tax_rate DECIMAL(5, 2) NOT NULL DEFAULT 8.00,
    tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12, 2) NOT NULL,
    total DECIMAL(12, 2) NOT NULL,
    modifiers JSONB NOT NULL DEFAULT '{}'::jsonb,
    preparation_status kitchen_item_status_enum NOT NULL DEFAULT 'PENDING',
    sent_to_kitchen_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ready_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    notes VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_kds_station_status ON restaurant_order_items (station, preparation_status, sent_to_kitchen_at ASC);

-- -----------------------------------------------------------------------------
-- 50. TABLA RESTAURANT_SPLIT_BILLS (División de Cuentas por Mesa / Split Bill)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS restaurant_split_bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES restaurant_table_orders(id) ON DELETE CASCADE,
    split_number INTEGER NOT NULL,
    subtotal DECIMAL(14, 2) NOT NULL,
    tax_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    tip_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(14, 2) NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FASE 5: EXPANSIÓN OMNICANAL Y FIDELIZACIÓN (CRM, LEALTAD, PROMOS, DELIVERY)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 51. TABLA CUSTOMER_CRM_PROFILES (Perfiles RFM y Segmentación de Clientes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_crm_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    segment crm_segment_enum NOT NULL DEFAULT 'FREQUENT',
    rfm_recency_days INTEGER NOT NULL DEFAULT 0,
    rfm_frequency_count INTEGER NOT NULL DEFAULT 0,
    rfm_monetary_total DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    rfm_score INTEGER NOT NULL DEFAULT 100,
    churn_risk_score DECIMAL(5, 2) NOT NULL DEFAULT 10.00,
    predicted_ltv DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    last_purchase_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_crm_customer UNIQUE (customer_id)
);

-- -----------------------------------------------------------------------------
-- 52. TABLA CRM_CAMPAIGNS (Campañas de Marketing Omnicanal y Fidelización)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS crm_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    channel campaign_channel_enum NOT NULL DEFAULT 'EMAIL',
    target_segment crm_segment_enum,
    title VARCHAR(200) NOT NULL,
    message_content TEXT NOT NULL,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    total_recipients INTEGER NOT NULL DEFAULT 0,
    total_delivered INTEGER NOT NULL DEFAULT 0,
    status campaign_status_enum NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 52B. TABLA CRM_TRIGGERS (Automatizaciones y Workflows de Fidelización)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS crm_triggers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    trigger_type crm_trigger_type_enum NOT NULL,
    channel campaign_channel_enum NOT NULL DEFAULT 'EMAIL',
    message_template TEXT NOT NULL,
    discount_coupon_code VARCHAR(50),
    days_threshold INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 52C. TABLA CRM_TRIGGER_EXECUTIONS (Historial de Disparadores Ejecutados)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS crm_trigger_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trigger_id UUID NOT NULL REFERENCES crm_triggers(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    sent_to VARCHAR(150) NOT NULL,
    content_sent TEXT NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_trigger_exec_customer ON crm_trigger_executions (customer_id);
CREATE INDEX IF NOT EXISTS idx_crm_trigger_exec_trigger ON crm_trigger_executions (trigger_id);


-- -----------------------------------------------------------------------------
-- 53. TABLA CUSTOMER_LOYALTY_ACCOUNTS (Billetera de Puntos & Nivel / Tier)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customer_loyalty_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    current_points INTEGER NOT NULL DEFAULT 0,
    lifetime_points INTEGER NOT NULL DEFAULT 0,
    tier loyalty_tier_enum NOT NULL DEFAULT 'BRONZE',
    tier_upgraded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    points_expire_at TIMESTAMP WITH TIME ZONE,
    is_blocked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_loyalty_customer UNIQUE (customer_id)
);

-- -----------------------------------------------------------------------------
-- 54. TABLA LOYALTY_POINTS_LEDGER (Libro Mayor de Puntos Inmutable)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS loyalty_points_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES customer_loyalty_accounts(id) ON DELETE CASCADE,
    transaction_type loyalty_transaction_type_enum NOT NULL,
    points_amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    reference_sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
    description VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_loyalty_ledger_account ON loyalty_points_ledger (account_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- 55. TABLA PROMOTIONS (Motor de Promociones & Descuentos Inteligentes)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    code VARCHAR(50) NOT NULL,
    promotion_type promotion_type_enum NOT NULL DEFAULT 'PERCENTAGE_DISCOUNT',
    discount_value DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    min_order_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    happy_hour_start TIME,
    happy_hour_end TIME,
    max_uses_global INTEGER DEFAULT 1000,
    current_uses_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_promo_code_business UNIQUE (business_id, code)
);

-- -----------------------------------------------------------------------------
-- 56. TABLA PROMOTION_COUPONS (Cupones Promocionales Individuales)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS promotion_coupons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    coupon_code VARCHAR(60) NOT NULL UNIQUE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    max_uses INTEGER NOT NULL DEFAULT 1,
    used_count INTEGER NOT NULL DEFAULT 0,
    valid_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 57. TABLA PROMOTION_USAGES (Auditoría de Redención de Promociones)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS promotion_usages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE RESTRICT,
    coupon_id UUID REFERENCES promotion_coupons(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
    discount_applied DECIMAL(14, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 58. TABLA ONLINE_ORDERS (Pedidos de E-Commerce, Delivery & Pickup)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS online_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    order_number VARCHAR(50) NOT NULL,
    channel online_order_channel_enum NOT NULL DEFAULT 'WEB_STORE',
    delivery_type delivery_type_enum NOT NULL DEFAULT 'DELIVERY',
    delivery_address TEXT,
    contact_phone VARCHAR(50),
    subtotal DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    delivery_fee DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
    status online_order_status_enum NOT NULL DEFAULT 'ORDER_PLACED',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_online_order_number UNIQUE (business_id, order_number)
);

-- -----------------------------------------------------------------------------
-- 59. TABLA ONLINE_ORDER_ITEMS (Detalle de Productos en Pedido Online)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS online_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    online_order_id UUID NOT NULL REFERENCES online_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity DECIMAL(12, 3) NOT NULL DEFAULT 1.000,
    unit_price DECIMAL(12, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL,
    notes VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 60. TABLA DELIVERY_TRACKINGS (Tracking de Repartidores & Despacho)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS delivery_trackings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    online_order_id UUID NOT NULL REFERENCES online_orders(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    driver_name VARCHAR(100),
    driver_phone VARCHAR(50),
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    estimated_delivery_minutes INTEGER DEFAULT 30,
    started_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 61. TABLA NOTIFICATION_LOGS (Auditoría de Notificaciones Omnicanal)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    recipient VARCHAR(150) NOT NULL,
    channel campaign_channel_enum NOT NULL DEFAULT 'EMAIL',
    subject VARCHAR(200),
    body TEXT NOT NULL,
    status notification_status_enum NOT NULL DEFAULT 'QUEUED',
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FASE 6: INTELIGENCIA, ANALÍTICA, IA E INTEGRACIONES (FASE FINAL)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 62. TABLA API_KEYS (Gestión de Llaves Públicas para Integraciones API)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    key_prefix VARCHAR(16) NOT NULL,
    hashed_secret VARCHAR(128) NOT NULL,
    scopes TEXT[] NOT NULL DEFAULT ARRAY['sales:read']::TEXT[],
    rate_limit_per_minute INTEGER NOT NULL DEFAULT 120,
    status api_key_status_enum NOT NULL DEFAULT 'ACTIVE',
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_api_keys_prefix ON api_keys (key_prefix, status);

-- -----------------------------------------------------------------------------
-- 63. TABLA WEBHOOK_SUBSCRIPTIONS (Suscripciones a Eventos de Terceros)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhook_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    target_url TEXT NOT NULL,
    secret_token VARCHAR(128) NOT NULL,
    events TEXT[] NOT NULL DEFAULT ARRAY['SALE_COMPLETED']::TEXT[],
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 64. TABLA WEBHOOK_DELIVERIES (Historial y Reintentos de Envíos Webhook)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES webhook_subscriptions(id) ON DELETE CASCADE,
    event webhook_event_enum NOT NULL,
    payload JSONB NOT NULL,
    response_status_code INTEGER,
    status webhook_delivery_status_enum NOT NULL DEFAULT 'SUCCESS',
    attempts_count INTEGER NOT NULL DEFAULT 1,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_webhook_deliv_sub ON webhook_deliveries (subscription_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- 65. TABLA AI_INVENTORY_FORECASTS (Predicciones de Demanda de Inventario por IA)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_inventory_forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    predicted_demand_units DECIMAL(12, 3) NOT NULL,
    confidence_score DECIMAL(5, 2) NOT NULL DEFAULT 85.00,
    suggested_reorder_qty DECIMAL(12, 3) NOT NULL,
    forecast_period_days INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 66. TABLA AI_ANOMALY_LOGS (Detección de Fraude & Anomalías Transaccionales)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_anomaly_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    severity anomaly_severity_enum NOT NULL DEFAULT 'MEDIUM',
    anomaly_type VARCHAR(60) NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- SEEDS INICIALES
-- =============================================================================

-- Empresa Principal Demo
INSERT INTO businesses (id, name, legal_name, tax_id, email, phone, address, city, state, country, status) VALUES
('10000000-0000-0000-0000-000000000001', 'POS Core Retail S.A.S.', 'POS Core Retail S.A.S.', '901.456.789-0', 'contacto@poscore.co', '3001234567', 'Calle 100 # 15-20', 'Bogotá', 'Cundinamarca', 'Colombia', 'ACTIVE')
ON CONFLICT (tax_id) DO NOTHING;

-- Roles
INSERT INTO roles (id, business_id, name, slug, description, is_system, estado) VALUES
('11111111-1111-1111-1111-111111111111', NULL, 'Super Administrador', 'SUPER_ADMIN', 'Acceso total omnipotente', TRUE, TRUE),
('22222222-2222-2222-2222-222222222222', '10000000-0000-0000-0000-000000000001', 'Administrador de Empresa', 'ADMIN', 'Administrador general', FALSE, TRUE),
('33333333-3333-3333-3333-333333333333', '10000000-0000-0000-0000-000000000001', 'Gerente de Sucursal', 'MANAGER', 'Gestión de sucursal', FALSE, TRUE),
('44444444-4444-4444-4444-444444444444', '10000000-0000-0000-0000-000000000001', 'Cajero POS', 'CASHIER', 'Operación TPV', FALSE, TRUE)
ON CONFLICT (business_id, slug) DO NOTHING;

-- Permisos (Fase 1 y Fase 2)
INSERT INTO permissions (id, module, action, slug, description) VALUES
('a1111111-0000-0000-0000-000000000001', 'USERS', 'CREATE', 'users:create', 'Crear empleados'),
('a1111111-0000-0000-0000-000000000002', 'USERS', 'READ', 'users:read', 'Consultar empleados'),
('a3333333-0000-0000-0000-000000000001', 'BRANCHES', 'CREATE', 'branches:create', 'Crear sucursales'),
('a3333333-0000-0000-0000-000000000002', 'BRANCHES', 'READ', 'branches:read', 'Consultar sucursales'),
('a4444444-0000-0000-0000-000000000001', 'PARAMETERS', 'READ', 'parameters:read', 'Consultar parámetros'),
('a6666666-0000-0000-0000-000000000001', 'POS', 'SALES_CREATE', 'pos:sales:create', 'Emitir ventas en TPV'),
('a6666666-0000-0000-0000-000000000002', 'POS', 'SALES_CANCEL', 'pos:sales:cancel', 'Anular ventas en TPV'),
('a7777777-0000-0000-0000-000000000001', 'CASH_REGISTER', 'SESSION_OPEN', 'cash:session:open', 'Apertura de turno de caja'),
('a7777777-0000-0000-0000-000000000002', 'CASH_REGISTER', 'SESSION_CLOSE', 'cash:session:close', 'Cierre y arqueo de caja'),
('a8888888-0000-0000-0000-000000000001', 'CREDIT', 'RECEIPTS_CREATE', 'credit:receipts:create', 'Registrar abonos de cartera')
ON CONFLICT (slug) DO NOTHING;

-- Asignación de Permisos al ADMIN
INSERT INTO role_permissions (role_id, permission_id)
SELECT '22222222-2222-2222-2222-222222222222', id FROM permissions
ON CONFLICT DO NOTHING;

-- Asignación de Permisos al CASHIER
INSERT INTO role_permissions (role_id, permission_id) VALUES
('44444444-4444-4444-4444-444444444444', 'a6666666-0000-0000-0000-000000000001'),
('44444444-4444-4444-4444-444444444444', 'a7777777-0000-0000-0000-000000000001'),
('44444444-4444-4444-4444-444444444444', 'a7777777-0000-0000-0000-000000000002'),
('44444444-4444-4444-4444-444444444444', 'a8888888-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- Parametrías Iniciales (Métodos de Pago, Tipos de Documento, Denominaciones)
INSERT INTO parametros (id, business_id, modulo, clave, valor, etiqueta, tipo_dato, orden, estado) VALUES
('ba000001-0000-0000-0000-000000000001', NULL, 'DOCUMENTOS', 'TIPO_DOCUMENTO', 'CC', 'Cédula de Ciudadanía', 'STRING', 1, TRUE),
('ba000001-0000-0000-0000-000000000002', NULL, 'DOCUMENTOS', 'TIPO_DOCUMENTO', 'NIT', 'NIT Tributario', 'STRING', 2, TRUE),
('ba000004-0000-0000-0000-000000000001', NULL, 'PAGOS', 'METODO_PAGO', 'CASH', 'Efectivo', 'STRING', 1, TRUE),
('ba000004-0000-0000-0000-000000000002', NULL, 'PAGOS', 'METODO_PAGO', 'CARD', 'Tarjeta Débito / Crédito', 'STRING', 2, TRUE),
('ba000004-0000-0000-0000-000000000003', NULL, 'PAGOS', 'METODO_PAGO', 'NEQUI', 'Nequi / Daviplata', 'STRING', 3, TRUE),
('ba000004-0000-0000-0000-000000000004', NULL, 'PAGOS', 'METODO_PAGO', 'CREDIT', 'Crédito / Fiado', 'STRING', 4, TRUE),
('ba000005-0000-0000-0000-000000000001', NULL, 'CAJA', 'DENOMINACION', '50000', 'Billete $50.000', 'NUMBER', 1, TRUE),
('ba000005-0000-0000-0000-000000000002', NULL, 'CAJA', 'DENOMINACION', '20000', 'Billete $20.000', 'NUMBER', 2, TRUE),
('ba000005-0000-0000-0000-000000000003', NULL, 'CAJA', 'DENOMINACION', '10000', 'Billete $10.000', 'NUMBER', 3, TRUE),
('ba000005-0000-0000-0000-000000000004', NULL, 'CAJA', 'DENOMINACION', '5000', 'Billete $5.000', 'NUMBER', 4, TRUE),
('ba000005-0000-0000-0000-000000000005', NULL, 'CAJA', 'DENOMINACION', '2000', 'Billete $2.000', 'NUMBER', 5, TRUE),
('ba000005-0000-0000-0000-000000000006', NULL, 'CAJA', 'DENOMINACION', '1000', 'Moneda $1.000', 'NUMBER', 6, TRUE),
('ba000005-0000-0000-0000-000000000007', NULL, 'CAJA', 'DENOMINACION', '500', 'Moneda $500', 'NUMBER', 7, TRUE)
ON CONFLICT (business_id, modulo, clave, valor) DO NOTHING;

-- Usuarios
INSERT INTO users (
    id, business_id, name, email, phone, document_type, document_number,
    password_hash, pin_hash, role_id, status, failed_login_attempts
) VALUES
('99999999-9999-9999-9999-999999999999', NULL, 'Super Admin POSCore', 'superadmin@poscore.co', '3009999999', 'CC', '1000000000', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', '11111111-1111-1111-1111-111111111111', 'ACTIVE', 0),
('88888888-8888-8888-8888-888888888888', '10000000-0000-0000-0000-000000000001', 'Carlos Administrador', 'admin@empresa.com', '3008888888', 'CC', '1020304050', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', '22222222-2222-2222-2222-222222222222', 'ACTIVE', 0),
('77777777-7777-7777-7777-777777777777', '10000000-0000-0000-0000-000000000001', 'María Rodríguez (Cajera)', 'cajero@empresa.com', '3012458790', 'CC', '1030405060', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', '44444444-4444-4444-4444-444444444444', 'ACTIVE', 0)
ON CONFLICT (business_id, email) DO NOTHING;

-- Sucursales
INSERT INTO branches (
    id, business_id, name, code, type, address, city, state, phone, email, is_active
) VALUES
('b1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Sucursal Centro Principal', 'SUC-01', 'STORE', 'Carrera 7 # 32-15', 'Bogotá', 'Cundinamarca', '6012345678', 'centro@empresa.com', TRUE)
ON CONFLICT (business_id, code) DO NOTHING;

-- Caja Física
INSERT INTO cash_registers (id, business_id, branch_id, name, code, is_active) VALUES
('c1000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Caja Principal 01', 'CAJA-01', TRUE)
ON CONFLICT (branch_id, code) DO NOTHING;

-- Categoría Demo
INSERT INTO categories (id, business_id, name, code, color, orden, is_active) VALUES
('ca000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Bebidas & Cafetería', 'BEB', '#6366F1', 1, TRUE)
ON CONFLICT (business_id, name) DO NOTHING;

-- Productos Demo
INSERT INTO products (
    id, business_id, category_id, sku, barcode, name, description, price, cost, tax_rate, unit_type, status
) VALUES
('f0000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'ca000001-0000-0000-0000-000000000001', 'BEB-001', '7701234567890', 'Café Americano 8oz', 'Café espresso recién tostado', 4500.00, 1200.00, 19.00, 'UNIT', 'ACTIVE'),
('f0000002-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'ca000001-0000-0000-0000-000000000001', 'BEB-002', '7701234567891', 'Capuchino Vainilla 12oz', 'Café espresso con leche vaporizada y vainilla', 6500.00, 1800.00, 19.00, 'UNIT', 'ACTIVE')
ON CONFLICT (business_id, sku) DO NOTHING;

-- Cliente Demo con Crédito
INSERT INTO customers (
    id, business_id, customer_number, name, phone, email, document_type, document_number, city, is_active
) VALUES
('c0000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'CLI-0001', 'Inversiones El Diamante S.A.S.', '3159988776', 'compras@eldiamante.co', 'NIT', '900.842.119-1', 'Bogotá', TRUE)
ON CONFLICT (business_id, customer_number) DO NOTHING;

-- Perfil de Crédito
INSERT INTO customer_credit_profiles (
    id, business_id, customer_id, credit_limit, current_debt, payment_term_days, is_credit_blocked
) VALUES
('cf000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 5000000.00, 0.00, 30, FALSE)
ON CONFLICT (customer_id) DO NOTHING;

-- Seeds Fase 3: Stock Inicial
INSERT INTO inventory_stock (
    id, business_id, branch_id, product_id, quantity, reserved, available, min_stock, max_stock, reorder_point
) VALUES
('d1000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 150.000, 0.000, 150.000, 20.000, 500.000, 30.000),
('d1000002-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'f0000002-0000-0000-0000-000000000002', 80.000, 0.000, 80.000, 15.000, 300.000, 25.000)
ON CONFLICT DO NOTHING;

-- Seeds Fase 3: Lote Perecedero Demo (FEFO)
INSERT INTO product_lots (
    id, business_id, product_id, branch_id, lot_number, manufacture_date, expiration_date, initial_quantity, current_quantity, unit_cost, status, sanitary_registry_invima
) VALUES
('d2000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'LOT-2026-COFFEE-01', '2026-08-01', '2026-12-31', 150.000, 150.000, 1200.00, 'ACTIVE', 'RSAA-12I98765')
ON CONFLICT (business_id, product_id, lot_number) DO NOTHING;

-- Seeds Fase 3: Proveedor Demo
INSERT INTO suppliers (
    id, business_id, supplier_code, business_name, legal_name, tax_id, contact_name, phone, email, address, city, payment_terms, rating, status
) VALUES
('d3000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'PRV-001', 'Café Especial de Colombia S.A.S.', 'Café Especial de Colombia S.A.S.', '900.555.444-3', 'Jorge Barista', '3105556677', 'ventas@cafeespecial.co', 'Km 5 Vía Armenia', 'Armenia', 30, 4.9, 'ACTIVE')
ON CONFLICT (business_id, supplier_code) DO NOTHING;

-- Seeds Fase 3: Resolución DIAN Demo
INSERT INTO dian_resolutions (
    id, business_id, resolution_number, prefix, from_number, to_number, current_number, valid_from, valid_until, technical_key, is_active
) VALUES
('da000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '18764000001', 'SETP', 1, 50000, 1, '2026-01-01', '2027-12-31', 'fc8eac422eba16e122d5aa92a06a8', TRUE)
ON CONFLICT (business_id, prefix) DO NOTHING;

-- Seeds Fase 4: Zonas de Restaurante
INSERT INTO restaurant_zones (id, business_id, branch_id, name, display_order, is_active) VALUES
('e1000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Salón Principal', 1, TRUE),
('e1000002-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Terraza Exterior', 2, TRUE),
('e1000003-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Barra Licores', 3, TRUE)
ON CONFLICT (branch_id, name) DO NOTHING;

-- Seeds Fase 4: Mesas Físicas y Posición Canvas
INSERT INTO restaurant_tables (id, business_id, branch_id, zone_id, table_number, capacity, pos_x, pos_y, shape, current_status) VALUES
('e2000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000001', 'M-01', 4, 100, 100, 'SQUARE', 'FREE'),
('e2000002-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'e1000001-0000-0000-0000-000000000001', 'M-02', 2, 250, 100, 'ROUND', 'FREE'),
('e2000003-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'e1000002-0000-0000-0000-000000000002', 'T-01', 6, 100, 100, 'RECTANGLE', 'FREE')
ON CONFLICT (branch_id, table_number) DO NOTHING;

-- Seeds Fase 5: Perfil CRM Cliente Demo
INSERT INTO customer_crm_profiles (id, business_id, customer_id, segment, rfm_recency_days, rfm_frequency_count, rfm_monetary_total, rfm_score, churn_risk_score, predicted_ltv, last_purchase_at, notes) VALUES
('e3000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'CHAMPION', 5, 12, 1250000.00, 95, 2.50, 2200000.00, CURRENT_TIMESTAMP, 'Cliente corporativo de alta recurrencia')
ON CONFLICT (customer_id) DO NOTHING;

-- Seeds Fase 5: Disparador / Automatización CRM Demo
INSERT INTO crm_triggers (id, business_id, name, trigger_type, channel, message_template, discount_coupon_code, days_threshold, is_active) VALUES
('ea000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Campaña Reactivación Clientes Inactivos', 'INACTIVITY_REACTIVATION', 'EMAIL', '¡Hola {nombre}! Te extrañamos en POSCore. Disfruta un 15% OFF con tu cupón {cupon}.', 'BIENVENIDO15-VIP', 30, TRUE)
ON CONFLICT DO NOTHING;


-- Seeds Fase 5: Cuenta de Puntos y Fidelización
INSERT INTO customer_loyalty_accounts (id, business_id, customer_id, current_points, lifetime_points, tier, points_expire_at, is_blocked) VALUES
('e4000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 500, 1200, 'GOLD', CURRENT_TIMESTAMP + INTERVAL '365 days', FALSE)
ON CONFLICT (customer_id) DO NOTHING;

-- Seeds Fase 5: Promoción y Cupón Demo
INSERT INTO promotions (id, business_id, name, code, promotion_type, discount_value, min_order_amount, start_date, end_date, is_active) VALUES
('e5000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Descuento Bienvenida 15%', 'BIENVENIDO15', 'PERCENTAGE_DISCOUNT', 15.00, 20000.00, '2026-01-01', '2027-12-31', TRUE)
ON CONFLICT (business_id, code) DO NOTHING;

INSERT INTO promotion_coupons (id, promotion_id, coupon_code, customer_id, max_uses, used_count, valid_until, is_active) VALUES
('e6000001-0000-0000-0000-000000000001', 'e5000001-0000-0000-0000-000000000001', 'BIENVENIDO15-VIP', 'c0000001-0000-0000-0000-000000000001', 1, 0, '2027-12-31', TRUE)
ON CONFLICT (coupon_code) DO NOTHING;

-- Seeds Fase 6: API Key Pública Demo
INSERT INTO api_keys (id, business_id, name, key_prefix, hashed_secret, scopes, rate_limit_per_minute, status) VALUES
('e7000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Integración ERP ContaCoreOS', 'pos_live_cc', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', ARRAY['sales:read', 'inventory:read', 'invoices:read']::TEXT[], 120, 'ACTIVE')
ON CONFLICT DO NOTHING;

-- Seeds Fase 6: Webhook Subscription Demo
INSERT INTO webhook_subscriptions (id, business_id, target_url, secret_token, events, is_active) VALUES
('e8000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'https://api.contacore.co/webhooks/pos-events', 'whsec_poscore_super_secret_token_2026', ARRAY['SALE_COMPLETED', 'ONLINE_ORDER_DELIVERED']::TEXT[], TRUE)
ON CONFLICT DO NOTHING;

-- Seeds Fase 6: Predicción de Demanda IA Demo
INSERT INTO ai_inventory_forecasts (id, business_id, product_id, predicted_demand_units, confidence_score, suggested_reorder_qty, forecast_period_days) VALUES
('e9000001-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 320.000, 92.50, 200.000, 30)
ON CONFLICT DO NOTHING;


-- =============================================================================
-- 38. ÍNDICES DE ALTO RENDIMIENTO, COMPUESTOS Y PARCIALES (PRIORIDAD 4 - PERFORMANCE & CONCURRENCY)
-- =============================================================================

-- 1. Control de Lotes FEFO (Optimización de búsqueda del lote más próximo a vencer activo)
CREATE INDEX IF NOT EXISTS idx_lots_fefo_active ON product_lots (business_id, product_id, branch_id, expiration_date ASC) 
WHERE status = 'ACTIVE' AND current_quantity > 0;

-- 2. Transaccionalidad POS y Ventas (Consultas por sucursal, estado y rango de fechas)
CREATE INDEX IF NOT EXISTS idx_sales_perf_lookup ON sales (business_id, branch_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_completed_recent ON sales (business_id, created_at DESC) 
WHERE status = 'COMPLETED';
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items (product_id, sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_payments_method ON sale_payments (payment_method, created_at DESC);

-- 3. Existencias y Kardex de Inventario
CREATE INDEX IF NOT EXISTS idx_stock_tenant_lookup ON inventory_stock (business_id, branch_id, product_id, variant_id);
CREATE INDEX IF NOT EXISTS idx_stock_low_alert ON inventory_stock (business_id, branch_id, available) 
WHERE available <= min_stock;
CREATE INDEX IF NOT EXISTS idx_inv_movements_history ON inventory_movements (business_id, branch_id, product_id, created_at DESC);

-- 4. Cuentas por Cobrar y Cartera (Filtro acelerado para cobros y facturas pendientes)
CREATE INDEX IF NOT EXISTS idx_ar_pending_due ON accounts_receivable (business_id, customer_id, due_date ASC) 
WHERE status = 'PENDING' AND balance_due > 0;

-- 5. Facturación Electrónica DIAN
CREATE INDEX IF NOT EXISTS idx_invoices_business_status ON invoices (business_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_cufe_lookup ON invoices (cufe) 
WHERE cufe IS NOT NULL;

-- 6. Cocina KDS y Restaurante (Cola activa de preparación)
CREATE INDEX IF NOT EXISTS idx_kds_active_queue ON restaurant_order_items (station, sent_to_kitchen_at ASC) 
WHERE preparation_status IN ('PENDING', 'PREPARING');
CREATE INDEX IF NOT EXISTS idx_tables_business_status ON restaurant_tables (business_id, current_status);

-- 7. Pedidos Online y Delivery en Curso
CREATE INDEX IF NOT EXISTS idx_delivery_active_orders ON delivery_orders (business_id, status, created_at DESC) 
WHERE status IN ('CONFIRMED', 'PREPARING', 'IN_TRANSIT');

-- 8. Cajas y Control de Turnos
CREATE INDEX IF NOT EXISTS idx_sessions_open_shift ON cash_register_sessions (business_id, branch_id, cash_register_id) 
WHERE status = 'OPEN';

-- 9. Auditoría Forense y Trazabilidad de Seguridad
CREATE INDEX IF NOT EXISTS idx_audit_logs_forensic ON audit_logs (business_id, entity_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_history ON audit_logs (user_id, created_at DESC);

-- 10. CRM, Fidelización y Promociones Activas
CREATE INDEX IF NOT EXISTS idx_loyalty_active_accounts ON customer_loyalty_accounts (business_id, current_points DESC) 
WHERE is_blocked = FALSE;
CREATE INDEX IF NOT EXISTS idx_promotions_active_period ON promotions (business_id, is_active, start_date, end_date);





