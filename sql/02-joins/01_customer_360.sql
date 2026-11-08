-- ==============================================================================
-- Module: 02 - JOINS
-- File: 01_customer_360.sql
-- Bài 1: Customer 360 – Tổng hợp hồ sơ khách hàng
-- Business: Customer Analytics Basic
-- ==============================================================================
-- Bối cảnh Business:
--   Bộ phận Customer Experience muốn xây dựng báo cáo Customer 360 để biết:
--   - Khách hàng thuộc phân khúc nào.
--   - Đang sở hữu bao nhiêu tài khoản, bao nhiêu tài khoản ACTIVE.
--   - Tổng số dư hiện tại là bao nhiêu.

-- Yêu cầu SQL:
--   - JOIN 3 bảng: core_customers, crm_contacts, core_accounts.
--   - Lấy toàn bộ khách hàng (kể cả khách chưa có tài khoản hoặc chưa có CRM contact).

-- Lưu ý DE (Tránh lỗi Duplicate / Fan-out):
--   - Một khách hàng có thể có nhiều tài khoản. Cần group và aggregate tài khoản 
--     ở mức customer_id trước khi join hoặc group by cẩn thận theo grain của khách hàng.
-- ==============================================================================

WITH acc_summary AS (
    SELECT 
        customer_id,
        COUNT(account_id) AS total_accounts,
        COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) AS active_accounts,
        COALESCE(SUM(balance), 0) AS total_balance
    FROM core_accounts
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.full_name,
    crm.segment,
    COALESCE(a.total_accounts, 0) AS total_accounts,
    COALESCE(a.active_accounts, 0) AS active_accounts,
    COALESCE(a.total_balance, 0) AS total_balance
FROM core_customers c
LEFT JOIN crm_contacts crm ON c.customer_id = crm.customer_id
LEFT JOIN acc_summary a ON c.customer_id = a.customer_id
ORDER BY total_balance DESC
LIMIT 20;
