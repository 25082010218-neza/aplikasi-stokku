USE stokku;

ALTER TABLE invoice_lines
  ADD COLUMN unit_cost BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER quantity;

UPDATE invoice_lines AS line
INNER JOIN products AS product ON product.id = line.product_id
SET line.unit_cost = product.cost
WHERE line.unit_cost = 0;
