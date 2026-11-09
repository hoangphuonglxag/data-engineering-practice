-- ==============================================================================
-- Module: Analytics & Customer Intelligence
-- File: 04_top_customers_ranking.sql
-- Topic: Phân tích Top Khách hàng theo Giá trị & Tần suất giao dịch (Customer Wealth & Velocity)
-- Dataset: core_customers, core_accounts, core_transactions, crm_contacts
-- Target Engine: PostgreSQL / DuckDB
-- ==============================================================================

-- Bối cảnh Nghiệp vụ (Business Context):
-- Khối Khách hàng Cá nhân (Retail Banking & VIP Wealth) muốn xác định:
--   - Top 20 khách hàng chi tiêu/chuyển tiền nhiều nhất hệ thống.
--   - Phân khúc khách hàng (Segment) và số dư hiện hữu.
--   - Xếp hạng khách hàng độc lập theo 2 tiêu chí: Tổng giá trị (Value) và Tần suất (Volume).

WITH customer_txn_summary AS (
    -- Bước 1: Tổng hợp giao dịch chi ra ở mức account
    SELECT 
        from_account AS account_number,
        COUNT(transaction_id) AS total_outflow_txns,
        SUM(amount) AS total_outflow_amount
    FROM core_transactions
    WHERE status = 'SUCCESS'
      AND from_account IS NOT NULL
    GROUP BY from_account
),
customer_wealth AS (
    -- Bước 2: Ghép với tài khoản để rollup lên mức customer_id (Pre-aggregation)
    SELECT 
        a.customer_id,
        SUM(a.balance) AS current_account_balance,
        SUM(COALESCE(t.total_outflow_txns, 0)) AS total_transactions,
        SUM(COALESCE(t.total_outflow_amount, 0)) AS total_spending_vnd
    FROM core_accounts a
    LEFT JOIN customer_txn_summary t 
        ON a.account_number = t.account_number
    WHERE a.status = 'ACTIVE'
    GROUP BY a.customer_id
)
SELECT 
    c.customer_id,
    c.full_name,
    c.province,
    COALESCE(crm.segment, 'MASS') AS customer_segment,
    w.current_account_balance,
    w.total_transactions,
    w.total_spending_vnd,
    
    -- Xếp hạng theo Tổng chi tiêu (Wealth Outflow)
    DENSE_RANK() OVER(ORDER BY w.total_spending_vnd DESC) AS spending_rank,
    
    -- Xếp hạng theo Tần suất giao dịch (Activity Velocity)
    DENSE_RANK() OVER(ORDER BY w.total_transactions DESC) AS transaction_count_rank,
    
    -- Phân loại Tier khách hàng dựa trên chi tiêu thực tế
    CASE 
        WHEN w.total_spending_vnd >= 500000000 THEN 'DIAMOND_SPENDER'
        WHEN w.total_spending_vnd >= 100000000 THEN 'GOLD_SPENDER'
        WHEN w.total_spending_vnd >= 20000000  THEN 'SILVER_SPENDER'
        ELSE 'STANDARD'
    END AS spending_tier

FROM customer_wealth w
JOIN core_customers c ON w.customer_id = c.customer_id
LEFT JOIN crm_contacts crm ON c.customer_id = crm.customer_id
ORDER BY spending_rank ASC
LIMIT 20;
