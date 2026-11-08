-- ==============================================================================
-- Module: 01-fundamentals
-- File: 01_select.sql
-- Topic: SELECT & Column Projection
-- Dataset: mock-banking (core_customers.csv, core_transactions.csv)
-- Target Engine: PostgreSQL / DuckDB
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Anti-Pattern Demo vs Best Practice
-- ------------------------------------------------------------------------------

-- ❌ Anti-pattern: Đọc toàn bộ bảng (gây chậm, tốn I/O, gãy pipeline khi schema đổi)
-- SELECT * FROM core_customers;

-- ✅ Best Practice: Liệt kê rõ ràng cột cần lấy và chuẩn hóa alias
SELECT 
    customer_id,
    full_name,
    email,
    phone,
    kyc_status,
    risk_level
FROM core_customers
LIMIT 10;


-- ------------------------------------------------------------------------------
-- 2. Expressions, Casting & Data Sanitization
-- ------------------------------------------------------------------------------

SELECT 
    customer_id,
    TRIM(full_name) AS cleaned_name,
    LOWER(email) AS normalized_email,
    COALESCE(tax_code, 'N/A') AS tax_code_safe,
    is_active
FROM core_customers
LIMIT 10;


-- ------------------------------------------------------------------------------
-- 3. Case Study: Compliance Audit Query (Data Masking)
-- Yêu cầu:
--   - Che 6 số đầu CCCD (chỉ hiện 6 số cuối)
--   - Gán giá trị mặc định cho risk_level bị NULL
-- ------------------------------------------------------------------------------

SELECT 
    customer_id AS customer_code,
    TRIM(full_name) AS full_name_clean,
    email,
    CASE 
        WHEN cccd IS NULL OR LENGTH(TRIM(cccd)) < 6 THEN 'NO_CCCD'
        ELSE CONCAT('******', RIGHT(TRIM(cccd), 6))
    END AS masked_cccd,
    dob AS date_of_birth,
    kyc_status,
    COALESCE(risk_level, 'UNKNOWN') AS audit_risk_level
FROM core_customers
LIMIT 20;


-- ------------------------------------------------------------------------------
-- 4. Quick Execution via DuckDB CLI / Python (Nếu không muốn bật Postgres Docker)
-- Bạn có thể chạy trực tiếp câu lệnh này với DuckDB query thẳng file CSV:
--
-- duckdb -c "
--   SELECT customer_id, TRIM(full_name) AS name, email 
--   FROM 'datasets/mock-banking/core_customers.csv' 
--   LIMIT 5;
-- "
-- ------------------------------------------------------------------------------
