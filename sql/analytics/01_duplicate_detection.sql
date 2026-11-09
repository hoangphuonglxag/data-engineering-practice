-- ==============================================================================
-- Module: Analytics & Data Quality
-- File: 01_duplicate_detection.sql
-- Topic: Phát hiện giao dịch trùng lặp & Xử lý Deduplication trong Data Pipeline
-- Dataset: core_transactions
-- Target Engine: PostgreSQL / DuckDB
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Phương pháp 1: Phát hiện bằng GROUP BY + HAVING trên cửa sổ thời gian
-- Tìm các tài khoản gửi có nhiều hơn 1 giao dịch cùng số tiền trong cùng 1 ngày
-- ------------------------------------------------------------------------------
SELECT 
    from_account,
    to_account,
    amount,
    CAST(transaction_date AS DATE) AS transaction_day,
    COUNT(*) AS frequency,
    COUNT(DISTINCT transaction_id) AS distinct_txns
FROM core_transactions
WHERE from_account IS NOT NULL 
  AND status = 'SUCCESS'
  AND transaction_date >= '2025-12-01'
GROUP BY 
    from_account,
    to_account,
    amount,
    CAST(transaction_date AS DATE)
HAVING COUNT(*) > 1
ORDER BY frequency DESC
LIMIT 10;


-- ------------------------------------------------------------------------------
-- Phương pháp 2: Deduplication chuẩn Data Pipeline bằng ROW_NUMBER()
-- Kỹ thuật phân vùng (Partitioning Window):
--   - Gán row_num = 1 cho bản ghi đến trước (giữ lại trong Data Warehouse)
--   - Gán row_num > 1 cho bản ghi bị trùng (lọc bỏ để tránh double-counting)
-- ------------------------------------------------------------------------------
WITH ranked_transactions AS (
    SELECT 
        transaction_id,
        reference_code,
        from_account,
        to_account,
        amount,
        transaction_date,
        channel,
        status,
        ROW_NUMBER() OVER(
            PARTITION BY 
                from_account, 
                COALESCE(to_account, 0), 
                amount, 
                CAST(transaction_date AS DATE)
            ORDER BY transaction_date ASC, transaction_id ASC
        ) AS duplicate_rank
    FROM core_transactions
    WHERE status = 'SUCCESS'
      AND from_account IS NOT NULL
      AND transaction_date >= '2025-12-01'
)
SELECT 
    transaction_id,
    reference_code,
    from_account,
    to_account,
    amount,
    transaction_date,
    duplicate_rank,
    CASE 
        WHEN duplicate_rank = 1 THEN 'KEEP_RECORD'
        ELSE 'DUPLICATE_REMOVE'
    END AS pipeline_action
FROM ranked_transactions
ORDER BY duplicate_rank DESC, from_account
LIMIT 15;
