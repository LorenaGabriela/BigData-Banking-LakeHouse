CREATE OR REPLACE VIEW analytics.v_customer_orders AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    o.order_id,
    o.order_number,
    o.order_date,
    o.order_status,
    o.total_amount
FROM core.customers c
JOIN sales.orders o
    ON c.customer_id = o.customer_id;

SELECT *
FROM analytics.v_customer_orders;


---materialized views
Caracteristică	View	Materialized View
Stochează rezultatele	Nu	Da
Reflectă automat modificările	Da	Nu
Necesită refresh	Nu	Da
Util pentru interogări complexe	Da	Da, mai ales când vrem rezultate precalculate

               CREATE MATERIALIZED VIEW analytics.mv_product_revenue AS
SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM core.products p
JOIN sales.order_items oi
    ON p.product_id = oi.product_id
JOIN sales.orders o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'cancelled'
GROUP BY
    p.product_id,
    p.product_name;


. Ce se întâmplă când se modifică datele?
Să presupunem că adăugăm o comandă nouă.

Materialized View-ul nu se actualizează automat.

Trebuie să executăm:
REFRESH MATERIALIZED VIEW analytics.mv_product_revenue;


Acest proces recalculează și înlocuiește rezultatul stocat.
5. Refresh concurent
PostgreSQL permite și:
REFRESH MATERIALIZED VIEW CONCURRENTLY
analytics.mv_product_revenue;


Avantajul este că alte sesiuni pot continua să citească Materialized View-ul în timpul refresh-ului.

Există însă o condiție: trebuie să avem un index UNIQUE adecvat pe Materialized View, folosind coloane care identifică în mod unic fiecare rând.

Pentru exemplul nostru:
CREATE UNIQUE INDEX idx_mv_product_revenue_product
ON analytics.mv_product_revenue (product_id);
Un raport care calculează veniturile fiecărui produs poate deveni costisitor dacă executăm mereu aceleași JOIN-uri și agregări.

Un Materialized View ne permite să pregătim rezultatele în avans.

Acesta este un concept util și pentru viitorul nostru strat analitic, în special pentru rapoartele Power BI.

Un detaliu important: Materialized Views sunt potrivite pentru rapoarte care nu trebuie actualizate în timp real. Pentru date care se schimbă frecvent și trebuie afișate imediat, un View obișnuit sau o altă arhitectură poate fi mai potrivită.