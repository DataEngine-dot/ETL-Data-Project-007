\copy address FROM './mock_export/address.csv' WITH (FORMAT csv, HEADER true);
\copy counterparty FROM './mock_export/counterparty.csv' WITH (FORMAT csv, HEADER true);
\copy currency FROM './mock_export/currency.csv' WITH (FORMAT csv, HEADER true);
\copy department FROM './mock_export/department.csv' WITH (FORMAT csv, HEADER true);
\copy design FROM './mock_export/design.csv' WITH (FORMAT csv, HEADER true);
\copy payment_type FROM './mock_export/payment_type.csv' WITH (FORMAT csv, HEADER true);
\copy purchase_order FROM './mock_export/purchase_order.csv' WITH (FORMAT csv, HEADER true);
\copy staff FROM './mock_export/staff.csv' WITH (FORMAT csv, HEADER true);
\copy payment FROM './mock_export/payment.csv' WITH (FORMAT csv, HEADER true);
\copy transaction FROM './mock_export/transaction.csv' WITH (FORMAT csv, HEADER true);
\copy sales_order FROM './mock_export/sales_order.csv' WITH (FORMAT csv, HEADER true);
