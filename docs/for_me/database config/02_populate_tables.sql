
BEGIN;

-- =====================================================
-- 1. CORE.CUSTOMERS
-- =====================================================

INSERT INTO core.customers
(first_name, last_name, email, phone, country, city,
 date_of_birth, customer_status)
VALUES
('Andrei', 'Popescu', 'andrei.popescu@email.com', '+40721000001', 'Romania', 'Bucharest', '1995-04-12', 'active'),
('Maria', 'Ionescu', 'maria.ionescu@email.com', '+40721000002', 'Romania', 'Cluj-Napoca', '1998-07-23', 'active'),
('Alexandru', 'Dumitrescu', 'alex.dumitrescu@email.com', '+40721000003', 'Romania', 'Timisoara', '1990-11-05', 'active'),
('Elena', 'Stan', 'elena.stan@email.com', '+40721000004', 'Romania', 'Iasi', '1997-02-18', 'inactive'),
('David', 'Marinescu', 'david.marinescu@email.com', '+40721000005', 'Romania', 'Brasov', '1993-09-30', 'active');


-- =====================================================
-- 2. CORE.CUSTOMER_ADDRESSES
-- =====================================================

INSERT INTO core.customer_addresses
(customer_id, address_type, street_address, city,
 state, postal_code, country, is_default)
SELECT
    c.customer_id,
    v.address_type,
    v.street_address,
    v.city,
    v.state,
    v.postal_code,
    'Romania',
    TRUE
FROM (
    VALUES
    ('andrei.popescu@email.com', 'shipping', 'Strada Victoriei 10', 'Bucharest', 'Bucharest', '010001'),
    ('maria.ionescu@email.com', 'shipping', 'Strada Memorandumului 20', 'Cluj-Napoca', 'Cluj', '400001'),
    ('alex.dumitrescu@email.com', 'shipping', 'Bulevardul Revolutiei 15', 'Timisoara', 'Timis', '300001'),
    ('elena.stan@email.com', 'shipping', 'Strada Palat 8', 'Iasi', 'Iasi', '700001'),
    ('david.marinescu@email.com', 'shipping', 'Strada Republicii 12', 'Brasov', 'Brasov', '500001')
) AS v(email, address_type, street_address, city, state, postal_code)
JOIN core.customers c ON c.email = v.email;


-- =====================================================
-- 3. CORE.SELLERS
-- =====================================================

INSERT INTO core.sellers
(seller_name, email, country, city, seller_status)
VALUES
('TechStore Romania', 'contact@techstore.ro', 'Romania', 'Bucharest', 'active'),
('FashionHub', 'contact@fashionhub.ro', 'Romania', 'Cluj-Napoca', 'active'),
('HomeDesign', 'contact@homedesign.ro', 'Romania', 'Timisoara', 'active');


-- =====================================================
-- 4. CORE.CATEGORIES
-- =====================================================

-- Parent categories

INSERT INTO core.categories
(category_name, description)
VALUES
('Electronics', 'Electronic devices and accessories'),
('Fashion', 'Clothing and fashion products'),
('Home', 'Home and living products');

-- Child categories

INSERT INTO core.categories
(category_name, parent_category_id, description)
SELECT
    v.category_name,
    c.category_id,
    v.description
FROM (
    VALUES
    ('Smartphones', 'Electronics', 'Mobile phones and accessories'),
    ('Laptops', 'Electronics', 'Portable computers'),
    ('Clothing', 'Fashion', 'Clothing and apparel')
) AS v(category_name, parent_name, description)
JOIN core.categories c
    ON c.category_name = v.parent_name
   AND c.parent_category_id IS NULL;


-- =====================================================
-- 5. CORE.PRODUCTS
-- =====================================================

INSERT INTO core.products
(seller_id, category_id, sku, product_name,
 description, unit_price, currency, product_attributes)
SELECT
    s.seller_id,
    c.category_id,
    v.sku,
    v.product_name,
    v.description,
    v.unit_price,
    'EUR',
    v.product_attributes::JSONB
FROM (
    VALUES
    ('contact@techstore.ro', 'Smartphones', 'PH001',
     'Samsung Galaxy S24', 'Samsung smartphone',
     799.99, '{"brand":"Samsung","color":"Black","storage":"256GB"}'),

    ('contact@techstore.ro', 'Smartphones', 'PH002',
     'iPhone 15', 'Apple smartphone',
     899.99, '{"brand":"Apple","color":"Blue","storage":"128GB"}'),

    ('contact@techstore.ro', 'Laptops', 'LP001',
     'Lenovo ThinkPad', 'Business laptop',
     1099.99, '{"brand":"Lenovo","ram":"16GB","storage":"512GB"}'),

    ('contact@techstore.ro', 'Laptops', 'LP002',
     'HP Pavilion', 'Personal laptop',
     749.99, '{"brand":"HP","ram":"8GB","storage":"512GB"}'),

    ('contact@fashionhub.ro', 'Clothing', 'CL001',
     'Nike Hoodie', 'Cotton hoodie',
     59.99, '{"brand":"Nike","size":"M","color":"Black"}'),

    ('contact@fashionhub.ro', 'Clothing', 'CL002',
     'Adidas T-Shirt', 'Cotton t-shirt',
     29.99, '{"brand":"Adidas","size":"L","color":"White"}'),

    ('contact@homedesign.ro', 'Home', 'HM001',
     'Office Chair', 'Ergonomic office chair',
     149.99, '{"material":"Mesh","color":"Grey"}'),

    ('contact@homedesign.ro', 'Home', 'HM002',
     'Desk Lamp', 'LED desk lamp',
     39.99, '{"type":"LED","color":"White"}')
) AS v(seller_email, category_name, sku, product_name,
       description, unit_price, product_attributes)
JOIN core.sellers s
    ON s.email = v.seller_email
JOIN core.categories c
    ON c.category_name = v.category_name;


-- =====================================================
-- 6. SALES.ORDERS
-- =====================================================

INSERT INTO sales.orders
(order_number, customer_id, shipping_address_id,
 order_status, order_date, total_amount, currency)
SELECT
    v.order_number,
    c.customer_id,
    a.address_id,
    v.order_status,
    v.order_date::TIMESTAMPTZ,
    v.total_amount,
    'EUR'
FROM (
    VALUES
    ('ORD-1001', 'andrei.popescu@email.com', 'pending', '2026-10-01 10:30:00+03', 129.97),
    ('ORD-1002', 'maria.ionescu@email.com', 'delivered', '2026-10-02 14:15:00+03', 899.99),
    ('ORD-1003', 'alex.dumitrescu@email.com', 'shipped', '2026-10-03 09:45:00+03', 1099.99),
    ('ORD-1004', 'elena.stan@email.com', 'cancelled', '2026-10-04 16:20:00+03', 59.99),
    ('ORD-1005', 'david.marinescu@email.com', 'delivered', '2026-10-05 11:00:00+03', 189.98),
    ('ORD-1006', 'andrei.popescu@email.com', 'processing', '2026-10-06 13:30:00+03', 789.98)
) AS v(order_number, email, order_status, order_date, total_amount)
JOIN core.customers c
    ON c.email = v.email
JOIN core.customer_addresses a
    ON a.customer_id = c.customer_id
   AND a.address_type = 'shipping';


-- =====================================================
-- 7. SALES.ORDER_ITEMS
-- =====================================================

INSERT INTO sales.order_items
(order_id, product_id, quantity, unit_price, discount_amount)
SELECT
    o.order_id,
    p.product_id,
    v.quantity,
    v.unit_price,
    v.discount_amount
FROM (
    VALUES
    ('ORD-1001', 'PH001', 1, 799.99, 0.00),
    ('ORD-1001', 'CL002', 1, 29.99, 0.00),

    ('ORD-1002', 'PH002', 1, 899.99, 0.00),

    ('ORD-1003', 'LP001', 1, 1099.99, 0.00),

    ('ORD-1004', 'CL001', 1, 59.99, 0.00),

    ('ORD-1005', 'HM001', 1, 149.99, 0.00),
    ('ORD-1005', 'HM002', 1, 39.99, 0.00),

    ('ORD-1006', 'LP002', 1, 749.99, 0.00),
    ('ORD-1006', 'CL002', 1, 29.99, 0.00),
    ('ORD-1006', 'HM002', 1, 39.99, 30.00)
) AS v(order_number, sku, quantity, unit_price, discount_amount)
JOIN sales.orders o
    ON o.order_number = v.order_number
JOIN core.products p
    ON p.sku = v.sku;


-- =====================================================
-- 8. SALES.PAYMENTS
-- =====================================================

INSERT INTO sales.payments
(order_id, payment_method, payment_status,
 amount, transaction_reference, payment_date)
SELECT
    o.order_id,
    v.payment_method,
    v.payment_status,
    v.amount,
    v.transaction_reference,
    v.payment_date::TIMESTAMPTZ
FROM (
    VALUES
    ('ORD-1001', 'card', 'pending', 129.97, 'TXN-001', '2026-10-01 10:35:00+03'),
    ('ORD-1002', 'card', 'completed', 899.99, 'TXN-002', '2026-10-02 14:20:00+03'),
    ('ORD-1003', 'bank_transfer', 'completed', 1099.99, 'TXN-003', '2026-10-03 10:00:00+03'),
    ('ORD-1004', 'card', 'cancelled', 59.99, 'TXN-004', '2026-10-04 16:25:00+03'),
    ('ORD-1005', 'cash_on_delivery', 'completed', 189.98, 'TXN-005', '2026-10-07 12:00:00+03'),
    ('ORD-1006', 'card', 'completed', 789.98, 'TXN-006', '2026-10-06 13:35:00+03')
) AS v(order_number, payment_method, payment_status,
       amount, transaction_reference, payment_date)
JOIN sales.orders o
    ON o.order_number = v.order_number;


-- =====================================================
-- 9. SALES.REFUNDS
-- =====================================================

INSERT INTO sales.refunds
(payment_id, refund_amount, refund_status, refund_reason)
SELECT
    p.payment_id,
    50.00,
    'completed',
    'Partial refund for customer request'
FROM sales.payments p
JOIN sales.orders o
    ON o.order_id = p.order_id
WHERE o.order_number = 'ORD-1002';


-- =====================================================
-- 10. INVENTORY.WAREHOUSES
-- =====================================================

INSERT INTO inventory.warehouses
(warehouse_name, country, city, warehouse_address)
VALUES
('Bucharest Main Warehouse', 'Romania', 'Bucharest', 'Industrial Park 1'),
('Cluj Distribution Center', 'Romania', 'Cluj-Napoca', 'Logistics Park 2'),
('Timisoara Warehouse', 'Romania', 'Timisoara', 'Industrial Zone 3');


-- =====================================================
-- 11. INVENTORY.STOCK
-- =====================================================

INSERT INTO inventory.stock
(warehouse_id, product_id, quantity_on_hand, quantity_reserved)
SELECT
    w.warehouse_id,
    p.product_id,
    v.quantity_on_hand,
    v.quantity_reserved
FROM (
    VALUES
    ('Bucharest Main Warehouse', 'PH001', 100, 5),
    ('Bucharest Main Warehouse', 'PH002', 80, 3),
    ('Bucharest Main Warehouse', 'LP001', 40, 2),
    ('Bucharest Main Warehouse', 'LP002', 60, 4),
    ('Cluj Distribution Center', 'CL001', 150, 10),
    ('Cluj Distribution Center', 'CL002', 200, 15),
    ('Cluj Distribution Center', 'HM001', 50, 5),
    ('Timisoara Warehouse', 'HM002', 120, 8)
) AS v(warehouse_name, sku, quantity_on_hand, quantity_reserved)
JOIN inventory.warehouses w
    ON w.warehouse_name = v.warehouse_name
JOIN core.products p
    ON p.sku = v.sku;


-- =====================================================
-- 12. LOGISTICS.SHIPMENTS
-- =====================================================

INSERT INTO logistics.shipments
(order_id, carrier, tracking_number, shipment_status,
 shipped_at, estimated_delivery, delivered_at)
SELECT
    o.order_id,
    v.carrier,
    v.tracking_number,
    v.shipment_status,
    v.shipped_at::TIMESTAMPTZ,
    v.estimated_delivery::TIMESTAMPTZ,
    v.delivered_at::TIMESTAMPTZ
FROM (
    VALUES
    ('ORD-1002', 'DHL', 'DHL-10002', 'delivered',
     '2026-10-03 08:00:00+03', '2026-10-05 18:00:00+03', '2026-10-05 15:30:00+03'),

    ('ORD-1003', 'Fan Courier', 'FC-10003', 'in_transit',
     '2026-10-04 09:00:00+03', '2026-10-07 18:00:00+03', NULL),

    ('ORD-1005', 'Cargus', 'CG-10005', 'delivered',
     '2026-10-06 08:00:00+03', '2026-10-08 18:00:00+03', '2026-10-08 14:00:00+03')
) AS v(order_number, carrier, tracking_number, shipment_status,
       shipped_at, estimated_delivery, delivered_at)
JOIN sales.orders o
    ON o.order_number = v.order_number;


-- =====================================================
-- 13. MARKETING.CAMPAIGNS
-- =====================================================

INSERT INTO marketing.campaigns
(campaign_name, campaign_type, start_date, end_date,
 budget, campaign_status)
VALUES
('Black Friday 2026', 'discount', '2026-11-20', '2026-11-30', 15000.00, 'planned'),
('Summer Sale 2026', 'seasonal', '2026-06-01', '2026-06-30', 8000.00, 'completed'),
('Electronics Campaign', 'email', '2026-10-01', '2026-10-31', 5000.00, 'active');


-- =====================================================
-- 14. MARKETING.CUSTOMER_CAMPAIGNS
-- =====================================================

INSERT INTO marketing.customer_campaigns
(campaign_id, customer_id, interaction_type, interaction_date)
SELECT
    c.campaign_id,
    cu.customer_id,
    v.interaction_type,
    v.interaction_date::TIMESTAMPTZ
FROM (
    VALUES
    ('Electronics Campaign', 'andrei.popescu@email.com', 'impression', '2026-10-01 09:00:00+03'),
    ('Electronics Campaign', 'andrei.popescu@email.com', 'click', '2026-10-01 09:05:00+03'),
    ('Electronics Campaign', 'maria.ionescu@email.com', 'impression', '2026-10-02 10:00:00+03'),
    ('Electronics Campaign', 'alex.dumitrescu@email.com', 'conversion', '2026-10-03 11:00:00+03'),
    ('Summer Sale 2026', 'elena.stan@email.com', 'impression', '2026-06-05 12:00:00+03'),
    ('Summer Sale 2026', 'elena.stan@email.com', 'click', '2026-06-05 12:10:00+03'),
    ('Summer Sale 2026', 'david.marinescu@email.com', 'conversion', '2026-06-10 14:00:00+03'),
    ('Black Friday 2026', 'andrei.popescu@email.com', 'impression', '2026-10-20 10:00:00+03'),
    ('Black Friday 2026', 'maria.ionescu@email.com', 'impression', '2026-10-21 11:00:00+03'),
    ('Black Friday 2026', 'david.marinescu@email.com', 'click', '2026-10-22 12:00:00+03')
) AS v(campaign_name, email, interaction_type, interaction_date)
JOIN marketing.campaigns c
    ON c.campaign_name = v.campaign_name
JOIN core.customers cu
    ON cu.email = v.email;


COMMIT;
