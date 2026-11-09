# Báo cáo Deliverables Tuần 2: SQL Thực chiến & Truy vấn Phân tích (Analytics)

> **Mốc thời gian:** 08/11 – 14/11 (Thực hiện ngày: 09/11/2026)  
> **Dataset mục tiêu:** Hệ thống Ngân hàng giả lập (Core Banking 750,000 transactions, 125,000 accounts, 50,000 customers).  
> **Môi trường thực thi:** DuckDB In-Process Vectorized Engine qua công cụ `run_sql.py`.

---

## 📂 Danh mục Deliverables trong `sql/analytics/`

Thư mục này chứa các truy vấn SQL phân tích nghiệp vụ chuyên sâu, phục vụ các bài toán thực tế của khối Vận hành (Operations), Quản trị rủi ro (Risk) và Khách hàng ưu tiên (Private Banking):

| File | Tên bài toán | Kỹ thuật cốt lõi DE |
| :--- | :--- | :--- |
| **`01_duplicate_detection.sql`** | Phát hiện giao dịch trùng & Lọc Deduplication | `ROW_NUMBER() OVER(PARTITION BY ...)`, `GROUP BY HAVING`, xử lý `NULL` an toàn. |
| **`02_cumulative_balance.sql`** | Tính tổng giá trị giao dịch lũy kế theo tài khoản | Window function `SUM() OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`, `LAG()`. |
| **`03_daily_transaction_metrics.sql`**| Báo cáo số lượng & giá trị giao dịch theo ngày | Phân rã theo kênh bằng `CASE WHEN`, ép kiểu ngày (`CAST AS DATE`), tính tỷ lệ thành công `%`. |
| **`04_top_customers_ranking.sql`** | Phân tích Top khách hàng theo giá trị & tần suất | Multi-table JOIN, CTE Pre-aggregation tránh Fan-out, phân hạng đa chiều bằng `DENSE_RANK()`. |

---

## 📊 Kết quả Kiểm thử & Phân tích Dữ liệu Thực tế

### 1. `01_duplicate_detection.sql` – Kỹ thuật Deduplication trong Data Pipeline
* **Vấn đề thực tế:** Khi ứng dụng gặp sự cố mạng hoặc người dùng double-click, các giao dịch giống hệt nhau về số tiền, tài khoản và thời điểm có thể xuất hiện.
* **Giải pháp DE:** Sử dụng `ROW_NUMBER()` đánh số thứ tự trong nhóm:
  * Bản ghi có `duplicate_rank = 1` $\rightarrow$ Giữ lại trong Data Warehouse (`KEEP_RECORD`).
  * Bản ghi có `duplicate_rank > 1` $\rightarrow$ Đẩy vào Dead Letter Queue hoặc loại bỏ (`DUPLICATE_REMOVE`).

---

### 2. `02_cumulative_balance.sql` – Dòng tiền lũy kế (Running Balance)
* **Ý nghĩa:** Cho phép theo dõi số tiền chi ra tăng dần theo từng mốc thời gian của từng tài khoản mà không làm co cụm dòng dữ liệu.
* **Trích đoạn kết quả thực tế:**
  ```text
   account_number transaction_id    transaction_date          channel  txn_amount  cumulative_spent  prev_txn_amount  txn_sequence
   97040300411584  TXN0000626929 2025-11-02 20:09:49 INTERNET_BANKING       22000           22000.0             <NA>             1
   97040300411584  TXN0000354421 2025-11-03 16:00:33 INTERNET_BANKING    17859000        17881000.0            22000             2
   97040300411584  TXN0000288532 2025-12-04 13:47:52   MOBILE_BANKING     1000000        18881000.0         17859000             3
  ```
  *(Tài khoản `97040300411584` phát sinh 3 giao dịch: 22k $\rightarrow$ 17.85M $\rightarrow$ 1M; cột `cumulative_spent` cộng dồn chính xác từ 22k lên 17.88M rồi đạt 18.88M).*

---

### 3. `03_daily_transaction_metrics.sql` – Báo cáo nhịp độ giao dịch theo ngày
* **Ý nghĩa:** Giám sát sức khỏe hệ thống thanh toán hàng ngày (Daily Volume, Value, Ticket Size, Tỷ lệ giao dịch thành công).
* **Trích đoạn kết quả thực tế:**
  ```text
  transaction_date  total_transactions  successful_transactions  success_rate_pct  total_successful_value_vnd  mobile_banking_txns  napas_txns
        2025-12-28                1603                     1481             92.39                44.56 Tỷ VND                  547         251
        2025-12-27                1541                     1416             91.89                44.51 Tỷ VND                  527         247
        2025-12-26                1599                     1460             91.31                45.80 Tỷ VND                  551         259
  ```
  * **Insight:** Tỷ lệ thành công trung bình đạt **91% – 93%**. Mobile Banking là kênh chiếm ưu thế lớn nhất (chiếm trên 35% tổng lưu lượng).

---

### 4. `04_top_customers_ranking.sql` – Xếp hạng Khách hàng Đa chiều
* **Ý nghĩa:** Giúp phân khúc khách hàng VIP dựa trên dòng tiền giao dịch thực tế kết hợp với số dư hiện có.
* **Trích đoạn kết quả Top chi tiêu:**
  ```text
  customer_id         full_name        province   segment   current_balance   total_txns   total_spending_vnd  spending_rank  tier
  CUS00033039    Trương Gia Đạt       Khánh Hòa      MASS       821,447,300           48      2,603,698,000             1  DIAMOND_SPENDER
  CUS00012163       Hà Linh Nga       Hải Phòng   PRIVATE       733,347,000           37      2,462,657,000             2  DIAMOND_SPENDER
  CUS00029870   Lương Thanh Tài       Thái Bình      MASS     1,080,792,000           62      2,263,799,500             3  DIAMOND_SPENDER
  ```

---

## 🛠 Hướng dẫn chạy kiểm thử lại trên máy

Bạn có thể chạy kiểm thử bất kỳ file nào bất cứ lúc nào qua script `run_sql.py`:
```powershell
# Chạy phát hiện giao dịch trùng
python E:\PJ\11_12\data-engineering-practice\sql\run_sql.py sql/analytics/01_duplicate_detection.sql

# Chạy tính tổng lũy kế
python E:\PJ\11_12\data-engineering-practice\sql\run_sql.py sql/analytics/02_cumulative_balance.sql

# Chạy báo cáo ngày
python E:\PJ\11_12\data-engineering-practice\sql\run_sql.py sql/analytics/03_daily_transaction_metrics.sql

# Chạy xếp hạng khách hàng
python E:\PJ\11_12\data-engineering-practice\sql\run_sql.py sql/analytics/04_top_customers_ranking.sql
```
