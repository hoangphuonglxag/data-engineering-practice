-- ==============================================================================
-- Module: Analytics & Time Series Aggregation
-- File: 03_daily_transaction_metrics.sql
-- Topic: Báo cáo số lượng & giá trị giao dịch theo ngày (Daily Metrics & Channel Breakdown)
-- Dataset: core_transactions
-- Target Engine: PostgreSQL / DuckDB
-- ==============================================================================

-- Bối cảnh Nghiệp vụ (Business Context):
-- Ban Giám đốc Khối Vận hành (Operations) cần theo dõi nhịp độ giao dịch mỗi ngày:
--   - Tổng số giao dịch phát sinh và tổng số tiền luân chuyển.
--   - Tỷ lệ giao dịch thành công (Success Rate %).
--   - Phân bổ giao dịch theo các kênh trọng điểm (Mobile Banking vs NAPAS vs ATM vs Khác).

SELECT 
    CAST(transaction_date AS DATE) AS transaction_date,
    
    -- 1. Tổng quan Volume & Value
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) AS successful_transactions,
    ROUND(
        COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 
        2
    ) AS success_rate_pct,
    
    SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) AS total_successful_value_vnd,
    ROUND(AVG(CASE WHEN status = 'SUCCESS' THEN amount END), 2) AS avg_ticket_size_vnd,
    
    -- 2. Phân rã theo Kênh giao dịch bằng CASE WHEN
    COUNT(CASE WHEN channel = 'MOBILE_BANKING' THEN 1 END) AS mobile_banking_txns,
    COUNT(CASE WHEN channel = 'NAPAS' THEN 1 END) AS napas_txns,
    COUNT(CASE WHEN channel = 'ATM' THEN 1 END) AS atm_txns,
    COUNT(CASE WHEN channel NOT IN ('MOBILE_BANKING', 'NAPAS', 'ATM') THEN 1 END) AS other_channel_txns,
    
    -- 3. Tổng phí thu được từ giao dịch thành công
    SUM(CASE WHEN status = 'SUCCESS' THEN COALESCE(fee_amount, 0) ELSE 0 END) AS total_fee_revenue_vnd

FROM core_transactions
WHERE transaction_date >= '2025-12-01'
GROUP BY CAST(transaction_date AS DATE)
ORDER BY transaction_date DESC
LIMIT 15;
