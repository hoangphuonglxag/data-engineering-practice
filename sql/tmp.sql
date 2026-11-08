-- Bài 5: Transaction Reconciliation
SELECT 
    t.transfer_id,
    t.reference_code,
    t.amount AS ib_amount,
    c.amount AS core_amount,
    CASE 
        WHEN c.transaction_id IS NULL THEN 'NOT_FOUND'
        WHEN t.amount != c.amount THEN 'AMOUNT_MISMATCH'
        WHEN t.status != c.status THEN 'STATUS_MISMATCH'
        ELSE 'MATCHED'
    END AS reconciliation_status
FROM ib_transfers AS t
LEFT JOIN core_transactions AS c 
    ON t.reference_code = c.reference_code
ORDER BY t.transfer_id
LIMIT 15;
