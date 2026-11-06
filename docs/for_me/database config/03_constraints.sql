-- PRODUCTS
ALTER TABLE core.products
ADD CONSTRAINT chk_products_unit_price
CHECK (unit_price >= 0);

-- ORDERS
ALTER TABLE sales.orders
ADD CONSTRAINT chk_orders_total_amount
CHECK (total_amount >= 0);

-- ORDER ITEMS
ALTER TABLE sales.order_items
ADD CONSTRAINT chk_order_items_quantity
CHECK (quantity > 0);

ALTER TABLE sales.order_items
ADD CONSTRAINT chk_order_items_unit_price
CHECK (unit_price >= 0);

ALTER TABLE sales.order_items
ADD CONSTRAINT chk_order_items_discount
CHECK (
    discount_amount >= 0
    AND discount_amount <= quantity * unit_price
);

-- PAYMENTS
ALTER TABLE sales.payments
ADD CONSTRAINT chk_payments_amount
CHECK (amount > 0);

-- REFUNDS
ALTER TABLE sales.refunds
ADD CONSTRAINT chk_refunds_amount
CHECK (amount > 0);

-- STOCK
ALTER TABLE inventory.stock
ADD CONSTRAINT chk_stock_quantities
CHECK (
    quantity_on_hand >= 0
    AND quantity_reserved >= 0
    AND quantity_reserved <= quantity_on_hand
);

-- CAMPAIGNS
ALTER TABLE marketing.campaigns
ADD CONSTRAINT chk_campaign_budget
CHECK (budget >= 0);

ALTER TABLE marketing.campaigns
ADD CONSTRAINT chk_campaign_dates
CHECK (end_date >= start_date);



-------UNIQUE
ALTER TABLE core.products
ALTER COLUMN product_name SET NOT NULL;

ALTER TABLE core.products
ALTER COLUMN unit_price SET NOT NULL;

ALTER TABLE sales.orders
ALTER COLUMN order_date SET NOT NULL;

ALTER TABLE sales.orders
ALTER COLUMN total_amount SET NOT NULL;

ALTER TABLE sales.order_items
ALTER COLUMN quantity SET NOT NULL;

ALTER TABLE sales.order_items
ALTER COLUMN unit_price SET NOT NULL;

ALTER TABLE sales.payments
ALTER COLUMN amount SET NOT NULL;


-------INDECSI
CREATE UNIQUE INDEX uq_customer_default_address
ON core.customer_addresses (customer_id, address_type)
WHERE is_default = TRUE; -- un client nu are 2 adrese implicite sau un refund nu ar trbeui sa depaseasca suma platita


---triggerȘ
                         CREATE OR REPLACE FUNCTION core.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

