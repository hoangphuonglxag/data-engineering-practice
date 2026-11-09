-- ==============================================================================
-- Module: Analytics & Window Functions
-- File: 02_cumulative_balance.sql
-- Topic: Tính tổng giá trị giao dịch lũy kế (Running Balance / Cumulative Total)
-- Dataset: core_transactions, core_accounts
-- Target Engine: PostgreSQL / DuckDB
-- ==============================================================================

-- Bối cảnh Nghiệp vụ (Business Context):
-- Đội quản trị rủi ro và phòng Kế toán cần theo dõi dòng tiền ra vào lũy kế
-- của từng tài khoản theo trục thời gian.
-- Window Function: SUM() OVER(PARTITION BY ... ORDER BY ...) cho phép tính
-- tổng cộng dồn từng dòng mà không làm co cụm (collapse) các dòng như GROUP BY.

-- ------------------------------------------------------------------------------
-- Truy vấn: Tính số tiền chi ra lũy kế & biến động dòng tiền từng tài khoản
-- ------------------------------------------------------------------------------
WITH active_outflow AS (
    SELECT 
        transaction_id,
        from_account AS account_number,
        transaction_date,
        channel,
        amount,
        status
    FROM core_transactions
    WHERE status = 'SUCCESS'
      AND from_account IS NOT NULL
      AND transaction_date >= '2025-11-01'
)
SELECT 
    account_number,
    transaction_id,
    transaction_date,
    channel,
    amount AS txn_amount,
    -- 1. Tổng lũy kế chi ra của tài khoản theo thời gian
    SUM(amount) OVER(
        PARTITION BY account_number 
        ORDER BY transaction_date ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_spent,
    -- 2. Giá trị giao dịch liền trước (LAG) để phát hiện đột biến chi tiêu
    LAG(amount, 1) OVER(
        PARTITION BY account_number 
        ORDER BY transaction_date ASC
    ) AS prev_txn_amount,
    -- 3. Thứ tự giao dịch trong kỳ của tài khoản
    ROW_NUMBER() OVER(
        PARTITION BY account_number 
        ORDER BY transaction_date ASC
    ) AS txn_sequence
FROM active_outflow
ORDER BY account_number, transaction_date
LIMIT 20;
