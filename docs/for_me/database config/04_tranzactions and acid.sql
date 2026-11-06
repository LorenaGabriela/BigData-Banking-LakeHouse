BEGIN – începe o tranzacție.

COMMIT – confirmă modificările.

ROLLBACK – anulează modificările.

SAVEPOINT – creează un punct intermediar la care putem reveni.

Proprietățile ACID – Atomicity, Consistency, Isolation, Durability.BEGIN;

UPDATE sales.orders
SET total_amount = 1000
WHERE order_number = 'ORD-1001';

SELECT order_number, total_amount
FROM sales.orders
WHERE order_number = 'ORD-1001';

ROLLBACK;

Proprietate	Semnificație
Atomicity	Toate operațiunile se execută sau niciuna.
Consistency	Datele respectă regulile și constrângerile bazei de date.
Isolation	Tranzacțiile concurente nu trebuie să interfereze incorect.
Durability	După COMMIT, modificările sunt persistente.

Exemplu din e-commerce
Imaginează-ți că un client cumpără un laptop.

În cadrul procesării comenzii trebuie să:
1. Creezi comanda.
2. Adaugi produsele în comandă.
3. Înregistrezi plata.
4. Actualizezi stocul.
Dacă înregistrarea plății eșuează, nu vrem să rămânem cu o comandă procesată parțial.

Aici intervine Atomicity: toate operațiunile trebuie confirmate împreună sau anulate împreună.