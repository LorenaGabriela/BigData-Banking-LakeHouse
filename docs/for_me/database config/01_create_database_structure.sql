
BEGIN;

-- =====================================================
-- 1. SCHEMAS
-- =====================================================

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS logistics;
CREATE SCHEMA IF NOT EXISTS marketing;
CREATE SCHEMA IF NOT EXISTS analytics;


-- =====================================================
-- 2. CORE - CUSTOMERS
-- =====================================================

CREATE TABLE IF NOT EXISTS core.customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    date_of_birth DATE,
    customer_status VARCHAR(20) NOT NULL DEFAULT 'active',
    registration_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT chk_customers_status
        CHECK (customer_status IN ('active', 'inactive', 'blocked'))
);


-- =====================================================
-- 3. CORE - CUSTOMER ADDRESSES
-- =====================================================

CREATE TABLE IF NOT EXISTS core.customer_addresses (
    address_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    address_type VARCHAR(20) NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customer_addresses PRIMARY KEY (address_id),

    CONSTRAINT fk_customer_addresses_customer
        FOREIGN KEY (customer_id)
        REFERENCES core.customers(customer_id),

    CONSTRAINT chk_address_type
        CHECK (address_type IN ('billing', 'shipping'))
);


-- =====================================================
-- 4. CORE - SELLERS
-- =====================================================

CREATE TABLE IF NOT EXISTS core.sellers (
    seller_id BIGINT GENERATED ALWAYS AS IDENTITY,
    seller_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    city VARCHAR(100),
    seller_status VARCHAR(20) NOT NULL DEFAULT 'active',
    registration_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_sellers PRIMARY KEY (seller_id),
    CONSTRAINT uq_sellers_email UNIQUE (email),
    CONSTRAINT chk_sellers_status
        CHECK (seller_status IN ('active', 'inactive', 'suspended'))
);


-- =====================================================
-- 5. CORE - CATEGORIES
-- =====================================================

CREATE TABLE IF NOT EXISTS core.categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR(150) NOT NULL,
    parent_category_id BIGINT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_categories PRIMARY KEY (category_id),

    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES core.categories(category_id),

    CONSTRAINT uq_category_name_parent
        UNIQUE (category_name, parent_category_id)
);


-- =====================================================
-- 6. CORE - PRODUCTS
-- =====================================================

CREATE TABLE IF NOT EXISTS core.products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY,
    seller_id BIGINT NOT NULL,
    category_id BIGINT,
    sku VARCHAR(100) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    unit_price NUMERIC(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    product_attributes JSONB NOT NULL DEFAULT '{}'::JSONB,
    product_status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products PRIMARY KEY (product_id),

    CONSTRAINT uq_products_sku UNIQUE (sku),

    CONSTRAINT fk_products_seller
        FOREIGN KEY (seller_id)
        REFERENCES core.sellers(seller_id),

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES core.categories(category_id),

    CONSTRAINT chk_products_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_products_status
        CHECK (product_status IN ('active', 'inactive', 'discontinued'))
);


-- =====================================================
-- 7. SALES - ORDERS
-- =====================================================

CREATE TABLE IF NOT EXISTS sales.orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_number VARCHAR(50) NOT NULL,
    customer_id BIGINT NOT NULL,
    shipping_address_id BIGINT,
    order_status VARCHAR(30) NOT NULL DEFAULT 'pending',
    order_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_orders PRIMARY KEY (order_id),

    CONSTRAINT uq_orders_number UNIQUE (order_number),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES core.customers(customer_id),

    CONSTRAINT fk_orders_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES core.customer_addresses(address_id),

    CONSTRAINT chk_orders_status
        CHECK (order_status IN (
            'pending', 'confirmed', 'processing',
            'shipped', 'delivered', 'cancelled', 'refunded'
        )),

    CONSTRAINT chk_orders_total
        CHECK (total_amount >= 0)
);


-- =====================================================
-- 8. SALES - ORDER ITEMS
-- =====================================================

CREATE TABLE IF NOT EXISTS sales.order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,

    line_total NUMERIC(14,2)
        GENERATED ALWAYS AS (
            quantity * unit_price - discount_amount
        ) STORED,

    CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES sales.orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES core.products(product_id),

    CONSTRAINT chk_order_items_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_items_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_order_items_discount
        CHECK (
            discount_amount >= 0
            AND discount_amount <= quantity * unit_price
        )
);


-- =====================================================
-- 9. SALES - PAYMENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS sales.payments (
    payment_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    amount NUMERIC(14,2) NOT NULL,
    transaction_reference VARCHAR(150),
    payment_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_payments PRIMARY KEY (payment_id),

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES sales.orders(order_id),

    CONSTRAINT chk_payments_amount
        CHECK (amount > 0),

    CONSTRAINT chk_payments_status
        CHECK (payment_status IN (
            'pending', 'completed', 'failed', 'cancelled'
        ))
);


-- =====================================================
-- 10. SALES - REFUNDS
-- =====================================================

CREATE TABLE IF NOT EXISTS sales.refunds (
    refund_id BIGINT GENERATED ALWAYS AS IDENTITY,
    payment_id BIGINT NOT NULL,
    refund_amount NUMERIC(14,2) NOT NULL,
    refund_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    refund_reason TEXT,
    refund_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_refunds PRIMARY KEY (refund_id),

    CONSTRAINT fk_refunds_payment
        FOREIGN KEY (payment_id)
        REFERENCES sales.payments(payment_id),

    CONSTRAINT chk_refunds_amount
        CHECK (refund_amount > 0),

    CONSTRAINT chk_refunds_status
        CHECK (refund_status IN (
            'pending', 'completed', 'failed'
        ))
);


-- =====================================================
-- 11. INVENTORY - WAREHOUSES
-- =====================================================

CREATE TABLE IF NOT EXISTS inventory.warehouses (
    warehouse_id BIGINT GENERATED ALWAYS AS IDENTITY,
    warehouse_name VARCHAR(150) NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    warehouse_address VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_warehouses PRIMARY KEY (warehouse_id)
);


-- =====================================================
-- 12. INVENTORY - STOCK
-- =====================================================

CREATE TABLE IF NOT EXISTS inventory.stock (
    warehouse_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_stock
        PRIMARY KEY (warehouse_id, product_id),

    CONSTRAINT fk_stock_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES inventory.warehouses(warehouse_id),

    CONSTRAINT fk_stock_product
        FOREIGN KEY (product_id)
        REFERENCES core.products(product_id),

    CONSTRAINT chk_stock_quantities
        CHECK (
            quantity_on_hand >= 0
            AND quantity_reserved >= 0
            AND quantity_reserved <= quantity_on_hand
        )
);


-- =====================================================
-- 13. LOGISTICS - SHIPMENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS logistics.shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY,
    order_id BIGINT NOT NULL,
    carrier VARCHAR(100),
    tracking_number VARCHAR(150),
    shipment_status VARCHAR(30) NOT NULL DEFAULT 'preparing',
    shipped_at TIMESTAMPTZ,
    estimated_delivery TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),

    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES sales.orders(order_id),

    CONSTRAINT uq_tracking_number UNIQUE (tracking_number),

    CONSTRAINT chk_shipment_status
        CHECK (shipment_status IN (
            'preparing', 'shipped', 'in_transit',
            'delivered', 'returned', 'cancelled'
        ))
);


-- =====================================================
-- 14. MARKETING - CAMPAIGNS
-- =====================================================

CREATE TABLE IF NOT EXISTS marketing.campaigns (
    campaign_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_name VARCHAR(200) NOT NULL,
    campaign_type VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE,
    budget NUMERIC(14,2),
    campaign_status VARCHAR(20) NOT NULL DEFAULT 'planned',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_campaigns PRIMARY KEY (campaign_id),

    CONSTRAINT chk_campaign_dates
        CHECK (end_date IS NULL OR end_date >= start_date),

    CONSTRAINT chk_campaign_budget
        CHECK (budget IS NULL OR budget >= 0),

    CONSTRAINT chk_campaign_status
        CHECK (campaign_status IN (
            'planned', 'active', 'completed', 'cancelled'
        ))
);


-- =====================================================
-- 15. MARKETING - CUSTOMER CAMPAIGN INTERACTIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS marketing.customer_campaigns (
    interaction_id BIGINT GENERATED ALWAYS AS IDENTITY,
    campaign_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    interaction_type VARCHAR(30) NOT NULL,
    interaction_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customer_campaigns
        PRIMARY KEY (interaction_id),

    CONSTRAINT fk_customer_campaigns_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES marketing.campaigns(campaign_id),

    CONSTRAINT fk_customer_campaigns_customer
        FOREIGN KEY (customer_id)
        REFERENCES core.customers(customer_id),

    CONSTRAINT chk_interaction_type
        CHECK (interaction_type IN (
            'impression', 'click', 'conversion', 'unsubscribe'
        ))
);


-- =====================================================
-- 16. INDEXES
-- =====================================================

-- Customers
CREATE INDEX IF NOT EXISTS idx_customers_registration
ON core.customers(registration_date);

CREATE INDEX IF NOT EXISTS idx_customers_status
ON core.customers(customer_status);

CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer
ON core.customer_addresses(customer_id);

-- Products
CREATE INDEX IF NOT EXISTS idx_products_seller
ON core.products(seller_id);

CREATE INDEX IF NOT EXISTS idx_products_category
ON core.products(category_id);

CREATE INDEX IF NOT EXISTS idx_products_attributes
ON core.products USING GIN(product_attributes);

-- Categories
CREATE INDEX IF NOT EXISTS idx_categories_parent
ON core.categories(parent_category_id);

-- Orders
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
ON sales.orders(customer_id, order_date DESC);

CREATE INDEX IF NOT EXISTS idx_orders_status
ON sales.orders(order_status);

CREATE INDEX IF NOT EXISTS idx_orders_date
ON sales.orders(order_date);

CREATE INDEX IF NOT EXISTS idx_orders_address
ON sales.orders(shipping_address_id);

-- Order items
CREATE INDEX IF NOT EXISTS idx_order_items_product
ON sales.order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order
ON sales.order_items(order_id);

-- Payments and refunds
CREATE INDEX IF NOT EXISTS idx_payments_order
ON sales.payments(order_id);

CREATE INDEX IF NOT EXISTS idx_refunds_payment
ON sales.refunds(payment_id);

-- Inventory
CREATE INDEX IF NOT EXISTS idx_stock_product
ON inventory.stock(product_id);

-- Logistics
CREATE INDEX IF NOT EXISTS idx_shipments_order
ON logistics.shipments(order_id);

-- Marketing
CREATE INDEX IF NOT EXISTS idx_customer_campaigns_customer
ON marketing.customer_campaigns(customer_id);

CREATE INDEX IF NOT EXISTS idx_customer_campaigns_campaign
ON marketing.customer_campaigns(campaign_id);

CREATE INDEX IF NOT EXISTS idx_campaigns_dates
ON marketing.campaigns(start_date, end_date);


COMMIT;
