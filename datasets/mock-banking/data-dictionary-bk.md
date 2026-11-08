# DATA DICTIONARY & DATA CONTRACT

## Banking Data Platform – Core Banking, CRM, Internet Banking & Mobile Banking

DATA DICTIONARY & DATA CONTRACT
Banking Data Platform – Core Banking, CRM, Internet Banking & Mobile Banking
Banking Data Specification

Technical documentation · Markdown · Version 1.0 · Draft


### Phạm vi dữ liệu
Core Banking: Accounts, Branches, Customers, Employees, Transactions
CRM: Campaigns, Contacts, Interactions
Internet Banking: Beneficiaries, Sessions, Transfers, Users
Mobile Banking: Devices, Push Notifications, QR Payments, Sessions

## 1\. Mục tiêu và phạm vi tài liệu

Tài liệu này định nghĩa tiêu chuẩn dữ liệu cho 15 file CSV của hệ thống ngân hàng, phục vụ các mục tiêu:

1. Chuẩn hóa cấu trúc dữ liệu giữa các hệ thống nguồn.
2. Thống nhất ý nghĩa nghiệp vụ của từng trường dữ liệu.
3. Xác định kiểu dữ liệu và quy tắc kiểm tra dữ liệu.
4. Kiểm soát tính toàn vẹn dữ liệu và quan hệ giữa các bảng.
5. Làm cơ sở xây dựng ETL/ELT, Data Warehouse, Data Lakehouse và Data Quality.
6. Hạn chế lỗi khi các hệ thống nguồn thay đổi schema.

**Quy ước quan trọng:** Do hiện tại chỉ có tên file và tên column, chưa có sample records, schema vật lý hoặc tài liệu nghiệp vụ từ hệ thống nguồn, tất cả kiểu dữ liệu và quy tắc dưới đây là thiết kế đề xuất. Không nên coi đây là các constraint đã được hệ thống nguồn xác nhận.

### 1.1. Quy ước kiểu dữ liệu

| Kiểu dữ liệu | Ý nghĩa | Ví dụ |
| --- | --- | --- |
| STRING | Chuỗi ký tự | `ACC001` |
| INTEGER | Số nguyên | `12` |
| BIGINT | Số nguyên lớn | `1234567890` |
| DECIMAL(p,s) | Số thập phân chính xác | `1000000.50` |
| BOOLEAN | Giá trị đúng/sai | `true` |
| DATE | Ngày tháng | `2026-01-31` |
| TIMESTAMP | Ngày giờ | `2026-01-31T10:30:00+07:00` |
| JSON | Dữ liệu dạng JSON | `{"key":"value"}` |
| TEXT | Văn bản dài | Nội dung ghi chú |

**Quy ước NULL:**

- `NOT NULL`: Trường bắt buộc phải có giá trị.
- `NULLABLE`: Cho phép không có giá trị.
- Không tự động thay NULL bằng chuỗi rỗng, 0 hoặc giá trị mặc định nếu chưa có quy tắc nghiệp vụ.

### 1.2. Quy ước constraint

| Constraint | Mô tả |
| --- | --- |
| PK | Primary Key – khóa chính |
| FK | Foreign Key – khóa ngoại |
| UK | Unique Key – giá trị duy nhất |
| NN | Not Null – không được NULL |
| CK | Check Constraint – điều kiện kiểm tra |
| IDX | Index – đề xuất đánh index |
| DQ | Data Quality Rule – quy tắc chất lượng dữ liệu |

---

# PHẦN I – DATA DICTIONARY

## 2\. CORE BANKING DOMAIN

### 2.1. `core_accounts.csv` – Account Information

**Mô tả:** Lưu trữ thông tin tài khoản ngân hàng của khách hàng, bao gồm loại tài khoản, số dư, tiền tệ, lãi suất và trạng thái hoạt động.

**Grain:** Một record đại diện cho một tài khoản ngân hàng.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| account\_id | STRING | No | PK | Mã định danh duy nhất của tài khoản |
| customer\_id | STRING | No | FK | Mã khách hàng sở hữu tài khoản |
| account\_number | STRING | No | UK | Số tài khoản ngân hàng |
| account\_type | STRING | No | - | Loại tài khoản: thanh toán, tiết kiệm, tiền gửi có kỳ hạn... |
| currency | STRING(3) | No | - | Mã tiền tệ theo ISO 4217 |
| balance | DECIMAL(20,4) | No | - | Số dư hiện tại của tài khoản |
| available\_balance | DECIMAL(20,4) | No | - | Số dư khả dụng để thực hiện giao dịch |
| interest\_rate | DECIMAL(9,6) | Yes | - | Lãi suất áp dụng cho tài khoản |
| branch\_id | STRING | Yes | FK | Chi nhánh quản lý tài khoản |
| open\_date | DATE | No | - | Ngày mở tài khoản |
| close\_date | DATE | Yes | - | Ngày đóng tài khoản |
| status | STRING | No | - | Trạng thái tài khoản |
| is\_primary | BOOLEAN | No | - | Đánh dấu tài khoản chính của khách hàng |
| term\_months | INTEGER | Yes | - | Kỳ hạn gửi tiền tính theo tháng |
| maturity\_date | DATE | Yes | - | Ngày đáo hạn |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo record |

**Giá trị nghiệp vụ đề xuất:**

- `account_type`: `CURRENT`, `SAVINGS`, `TERM_DEPOSIT`, `LOAN`.
- `status`: `ACTIVE`, `INACTIVE`, `BLOCKED`, `CLOSED`.
- `currency`: `VND`, `USD`, `EUR` hoặc mã ISO 4217 hợp lệ.

**Data Quality Rules:**

- `account_id` phải duy nhất.
- `customer_id` phải tồn tại trong `core_customers`.
- `account_number` phải duy nhất trong phạm vi hệ thống hoặc phạm vi ngân hàng theo quy định.
- `balance` và `available_balance` phải là số hợp lệ.
- `open_date` không được lớn hơn ngày hiện tại, trừ trường hợp dữ liệu kế hoạch.
- Nếu `status = CLOSED`, cần kiểm tra `close_date` có giá trị.
- `maturity_date` phải lớn hơn hoặc bằng `open_date` khi áp dụng kỳ hạn.
- Không mặc định `available_balance <= balance`, vì tài khoản thấu chi có thể có số dư khả dụng lớn hơn số dư kế toán.

### 2.2. `core_branches.csv` – Branch Information

**Mô tả:** Lưu thông tin ngân hàng, chi nhánh và các thông tin nhận diện phục vụ hoạt động giao dịch.

**Grain:** Một record đại diện cho một chi nhánh hoặc đơn vị ngân hàng.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| branch\_id | STRING | No | PK | Mã định danh chi nhánh |
| bank\_code | STRING | No | - | Mã định danh ngân hàng |
| bank\_name | STRING | No | - | Tên ngân hàng |
| branch\_type | STRING | No | - | Loại hình chi nhánh |
| branch\_name | STRING | No | - | Tên chi nhánh |
| province | STRING | No | - | Tỉnh/thành phố nơi chi nhánh hoạt động |
| address | STRING | Yes | - | Địa chỉ chi nhánh |
| phone | STRING | Yes | - | Số điện thoại liên hệ |
| swift\_code | STRING | Yes | - | Mã SWIFT/BIC của ngân hàng hoặc chi nhánh |
| napas\_bin | STRING | Yes | - | Mã BIN ngân hàng dùng trong mạng lưới NAPAS |
| opened\_date | DATE | Yes | - | Ngày khai trương chi nhánh |
| status | STRING | No | - | Trạng thái hoạt động của chi nhánh |

**Data Quality Rules:**

- `branch_id` phải duy nhất.
- `bank_code` không được rỗng.
- `napas_bin` phải đúng định dạng mã BIN theo danh mục được phê duyệt.
- `swift_code` phải tuân theo định dạng BIC nếu có.
- `opened_date` không được lớn hơn ngày hiện tại, trừ trường hợp chi nhánh tương lai.
- `status` chỉ được nhận giá trị thuộc danh mục trạng thái đã thống nhất.

### 2.3. `core_customers.csv` – Customer Master

**Mô tả:** Lưu thông tin định danh, liên hệ, phân loại, KYC và mức độ rủi ro của khách hàng ngân hàng.

**Grain:** Một record đại diện cho một khách hàng.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| customer\_id | STRING | No | PK | Mã khách hàng duy nhất |
| customer\_type | STRING | No | - | Loại khách hàng: cá nhân hoặc doanh nghiệp |
| full\_name | STRING | No | - | Họ tên hoặc tên pháp lý khách hàng |
| gender | STRING | Yes | - | Giới tính theo danh mục được phê duyệt |
| dob | DATE | Yes | - | Ngày sinh hoặc ngày thành lập tùy loại khách hàng |
| cccd | STRING | Yes | - | Số căn cước công dân/giấy tờ định danh |
| tax\_code | STRING | Yes | - | Mã số thuế |
| phone | STRING | Yes | - | Số điện thoại liên hệ |
| email | STRING | Yes | - | Địa chỉ email |
| province | STRING | Yes | - | Tỉnh/thành phố cư trú hoặc đăng ký |
| address | STRING | Yes | - | Địa chỉ khách hàng |
| branch\_id | STRING | Yes | FK | Chi nhánh quản lý khách hàng |
| kyc\_status | STRING | No | - | Trạng thái xác minh danh tính |
| risk\_level | STRING | Yes | - | Mức độ rủi ro khách hàng |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo hồ sơ |
| updated\_at | TIMESTAMP | Yes | - | Thời điểm cập nhật hồ sơ gần nhất |
| nationality | STRING | Yes | - | Quốc tịch |
| is\_active | BOOLEAN | No | - | Trạng thái hoạt động của khách hàng |

**Giá trị nghiệp vụ đề xuất:**

- `customer_type`: `INDIVIDUAL`, `CORPORATE`.
- `gender`: `MALE`, `FEMALE`, `OTHER`, `UNKNOWN`.
- `kyc_status`: `PENDING`, `VERIFIED`, `REJECTED`, `EXPIRED`.
- `risk_level`: `LOW`, `MEDIUM`, `HIGH`.
- `is_active`: `true`, `false`.

**Data Quality Rules:**

- `customer_id` phải duy nhất.
- `branch_id` nếu có phải tồn tại trong `core_branches`.
- `email` phải đúng định dạng nếu được cung cấp.
- `phone` phải tuân thủ quy tắc số điện thoại được áp dụng.
- `updated_at` không được nhỏ hơn `created_at`.
- Với khách hàng cá nhân, `dob` phải là ngày hợp lệ và không nằm trong tương lai.
- Với khách hàng doanh nghiệp, ý nghĩa của `dob` cần được thống nhất là ngày thành lập.
- Không yêu cầu `cccd` và `tax_code` đồng thời bắt buộc cho tất cả loại khách hàng.

### 2.4. `core_employees.csv` – Employee Information

**Mô tả:** Lưu trữ thông tin nhân sự ngân hàng và thông tin phân công nhân viên tại chi nhánh.

**Grain:** Một record đại diện cho một nhân viên.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| employee\_id | STRING | No | PK | Mã định danh nhân viên |
| branch\_id | STRING | No | FK | Chi nhánh nhân viên đang làm việc |
| full\_name | STRING | No | - | Họ tên nhân viên |
| gender | STRING | Yes | - | Giới tính |
| dob | DATE | Yes | - | Ngày sinh |
| phone | STRING | Yes | - | Số điện thoại nhân viên |
| email | STRING | Yes | UK? | Email nhân viên |
| role | STRING | No | - | Chức danh hoặc vai trò |
| hire\_date | DATE | No | - | Ngày bắt đầu làm việc |
| employee\_code | STRING | No | UK | Mã nhân viên nghiệp vụ |
| status | STRING | No | - | Trạng thái nhân viên |

**Data Quality Rules:**

- `employee_id` phải duy nhất.
- `employee_code` nên duy nhất trong phạm vi ngân hàng.
- `branch_id` phải tồn tại trong `core_branches`.
- `hire_date` không được lớn hơn ngày hiện tại, trừ dữ liệu nhân sự tương lai.
- Email phải hợp lệ nếu có.
- `status` phải thuộc danh mục nhân sự đã thống nhất.

### 2.5. `core_transactions.csv` – Banking Transactions

**Mô tả:** Lưu thông tin các giao dịch tài chính được ghi nhận trong hệ thống Core Banking.

**Grain:** Một record đại diện cho một giao dịch hoặc một bút toán giao dịch theo định nghĩa nguồn.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| transaction\_id | STRING | No | PK | Mã giao dịch duy nhất |
| reference\_code | STRING | Yes | - | Mã tham chiếu giao dịch |
| from\_account | STRING | Yes | FK | Tài khoản nguồn |
| to\_account | STRING | Yes | FK? | Tài khoản nhận |
| to\_bank\_bin | STRING | Yes | - | Mã BIN ngân hàng thụ hưởng |
| amount | DECIMAL(20,4) | No | - | Giá trị giao dịch |
| currency | STRING(3) | No | - | Mã tiền tệ giao dịch |
| transaction\_type | STRING | No | - | Loại giao dịch |
| channel | STRING | No | - | Kênh thực hiện giao dịch |
| status | STRING | No | - | Trạng thái giao dịch |
| description | TEXT | Yes | - | Nội dung giao dịch |
| fee\_amount | DECIMAL(20,4) | Yes | - | Phí giao dịch |
| transaction\_date | TIMESTAMP | No | - | Thời điểm khởi tạo/thực hiện giao dịch |
| value\_date | DATE | Yes | - | Ngày giá trị hạch toán |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo record |
| batch\_id | STRING | Yes | - | Mã batch xử lý |
| reversal\_txn\_id | STRING | Yes | FK? | Mã giao dịch gốc hoặc giao dịch đảo theo quy ước nguồn |

**Data Quality Rules:**

- `transaction_id` phải duy nhất.
- `amount` phải lớn hơn 0 đối với giao dịch tài chính thông thường.
- `fee_amount` không được âm.
- `from_account` và `to_account` phải tham chiếu tài khoản hợp lệ khi có giá trị.
- `transaction_date` không được nhỏ hơn `created_at` nếu hai trường được xác định theo trình tự này.
- `reversal_txn_id` nếu có phải tham chiếu một giao dịch tồn tại.
- Giao dịch đảo phải có liên kết với giao dịch gốc.
- `currency` phải thuộc danh mục tiền tệ hợp lệ.
- Giao dịch chuyển khoản nội bộ cần xác định rõ tài khoản nguồn và tài khoản đích.

**Lưu ý nghiệp vụ:** Không thể kết luận một record là một giao dịch kinh doanh hay một bút toán kế toán nếu chưa biết cách hệ thống Core Banking ghi nhận giao dịch.

---

## 3\. CRM DOMAIN

### 3.1. `crm_campaigns.csv` – Marketing Campaigns

**Mô tả:** Lưu thông tin các chiến dịch marketing, đối tượng mục tiêu, ngân sách, hiệu quả tiếp cận và doanh thu phát sinh.

**Grain:** Một record đại diện cho một chiến dịch marketing.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| campaign\_id | STRING | No | PK | Mã định danh chiến dịch |
| campaign\_name | STRING | No | - | Tên chiến dịch |
| campaign\_type | STRING | No | - | Loại chiến dịch marketing |
| target\_segment | STRING | Yes | - | Phân khúc khách hàng mục tiêu |
| target\_product | STRING | Yes | - | Sản phẩm ngân hàng được quảng bá |
| start\_date | DATE | No | - | Ngày bắt đầu chiến dịch |
| end\_date | DATE | No | - | Ngày kết thúc chiến dịch |
| budget\_vnd | DECIMAL(20,2) | Yes | - | Ngân sách chiến dịch tính bằng VND |
| cost\_per\_reach | DECIMAL(20,4) | Yes | - | Chi phí trung bình cho một lượt tiếp cận |
| total\_reach | BIGINT | Yes | - | Tổng số lượt hoặc đối tượng được tiếp cận |
| open\_rate | DECIMAL(9,6) | Yes | - | Tỷ lệ mở thông điệp |
| click\_rate | DECIMAL(9,6) | Yes | - | Tỷ lệ nhấp vào nội dung |
| conversion\_rate | DECIMAL(9,6) | Yes | - | Tỷ lệ chuyển đổi |
| total\_converted | BIGINT | Yes | - | Tổng số lượt chuyển đổi |
| revenue\_generated | DECIMAL(20,2) | Yes | - | Doanh thu phát sinh từ chiến dịch |
| roi | DECIMAL(12,6) | Yes | - | Tỷ suất hoàn vốn |
| status | STRING | No | - | Trạng thái chiến dịch |
| created\_by | STRING | Yes | FK? | Mã nhân viên tạo chiến dịch |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo chiến dịch |

**Data Quality Rules:**

- `campaign_id` phải duy nhất.
- `end_date` phải lớn hơn hoặc bằng `start_date`.
- `budget_vnd` không được âm.
- `total_reach` và `total_converted` không được âm.
- `total_converted` không nên lớn hơn `total_reach` nếu hai trường cùng đo số lượng người duy nhất và cùng phạm vi.
- `open_rate`, `click_rate`, `conversion_rate` phải nằm trong khoảng 0–1 nếu lưu dạng tỷ lệ thập phân.
- `created_by` nếu là mã nhân viên phải tồn tại trong `core_employees`.
- `roi` cần thống nhất công thức tính trước khi kiểm tra.

**Giả định cần xác nhận:** `open_rate = 0.25` được hiểu là 25%, không phải 0.25%.

### 3.2. `crm_contacts.csv` – CRM Customer Contacts

**Mô tả:** Lưu thông tin khách hàng trong CRM, bao gồm phân khúc, giá trị vòng đời, nguy cơ rời bỏ, mức độ tương tác và nhân viên quản lý quan hệ khách hàng.

**Grain:** Một record đại diện cho một hồ sơ contact trong CRM.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| contact\_id | STRING | No | PK | Mã contact trong CRM |
| customer\_id | STRING | No | FK | Mã khách hàng liên kết Core Banking |
| segment | STRING | Yes | - | Phân khúc khách hàng |
| lifetime\_value | DECIMAL(20,2) | Yes | - | Giá trị vòng đời khách hàng |
| churn\_risk | STRING | Yes | - | Nhóm nguy cơ khách hàng rời bỏ |
| churn\_score | DECIMAL(9,6) | Yes | - | Điểm dự báo nguy cơ rời bỏ |
| nps\_score | INTEGER | Yes | - | Điểm Net Promoter Score |
| preferred\_channel | STRING | Yes | - | Kênh liên hệ ưu tiên |
| preferred\_language | STRING | Yes | - | Ngôn ngữ ưu tiên |
| assigned\_rm | STRING | Yes | FK? | Mã Relationship Manager phụ trách |
| total\_products | INTEGER | Yes | - | Tổng số sản phẩm khách hàng sở hữu |
| active\_products | INTEGER | Yes | - | Số sản phẩm đang hoạt động |
| last\_interaction\_at | TIMESTAMP | Yes | - | Thời điểm tương tác gần nhất |
| onboarding\_date | DATE | Yes | - | Ngày khách hàng được tiếp nhận vào CRM |
| is\_vip | BOOLEAN | No | - | Đánh dấu khách hàng VIP |
| acquisition\_channel | STRING | Yes | - | Kênh khách hàng được thu hút |
| tags | JSON / ARRAY | Yes | - | Danh sách nhãn phân loại khách hàng |

**Data Quality Rules:**

- `contact_id` phải duy nhất.
- `customer_id` phải tồn tại trong `core_customers`.
- `churn_score` phải nằm trong khoảng 0–1 nếu dùng thang điểm xác suất.
- `nps_score` phải nằm trong khoảng -100 đến 100 nếu lưu điểm NPS tổng hợp; nếu lưu câu trả lời khảo sát gốc thì sử dụng 0–10.
- `active_products` không được lớn hơn `total_products`.
- `lifetime_value` cần thống nhất đơn vị tiền tệ.
- `assigned_rm` nếu là mã nhân viên phải tồn tại trong `core_employees`.
- `last_interaction_at` không nên lớn hơn thời điểm xử lý dữ liệu.

**Giả định cần xác nhận:**

- Một khách hàng có thể có nhiều contact hay chỉ một contact?
- `tags` lưu dạng JSON, ARRAY hay chuỗi phân tách bằng dấu phẩy?
- `churn_risk` là nhóm phân loại hay giá trị xác suất?

### 3.3. `crm_interactions.csv` – Customer Interactions

**Mô tả:** Lưu lịch sử tương tác giữa ngân hàng và khách hàng thông qua các kênh như điện thoại, email, SMS, ứng dụng hoặc gặp trực tiếp.

**Grain:** Một record đại diện cho một lần tương tác.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| interaction\_id | STRING | No | PK | Mã định danh tương tác |
| contact\_id | STRING | No | FK | Mã contact được tương tác |
| interaction\_type | STRING | No | - | Loại tương tác |
| channel | STRING | No | - | Kênh tương tác |
| direction | STRING | No | - | Chiều tương tác: inbound hoặc outbound |
| outcome | STRING | Yes | - | Kết quả tương tác |
| duration\_seconds | INTEGER | Yes | - | Thời lượng tương tác tính bằng giây |
| agent\_id | STRING | Yes | FK? | Mã nhân viên hoặc agent thực hiện |
| subject | STRING | Yes | - | Chủ đề tương tác |
| notes | TEXT | Yes | - | Nội dung ghi chú |
| satisfaction\_score | DECIMAL(5,2) | Yes | - | Điểm đánh giá mức độ hài lòng |
| follow\_up\_required | BOOLEAN | No | - | Có yêu cầu liên hệ lại hay không |
| follow\_up\_date | TIMESTAMP | Yes | - | Thời điểm dự kiến liên hệ lại |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo record |
| updated\_at | TIMESTAMP | Yes | - | Thời điểm cập nhật gần nhất |

**Data Quality Rules:**

- `interaction_id` phải duy nhất.
- `contact_id` phải tồn tại trong `crm_contacts`.
- `duration_seconds` không được âm.
- `satisfaction_score` phải theo thang điểm được xác nhận, ví dụ 1–5 hoặc 0–10.
- Nếu `follow_up_required = true`, cần kiểm tra `follow_up_date` theo quy tắc nghiệp vụ.
- `updated_at` không được nhỏ hơn `created_at`.
- `agent_id` nếu là nhân viên ngân hàng phải tồn tại trong `core_employees`.

---

## 4\. INTERNET BANKING DOMAIN

### 4.1. `ib_beneficiaries.csv` – Registered Beneficiaries

**Mô tả:** Lưu thông tin tài khoản thụ hưởng mà người dùng Internet Banking đã đăng ký để thực hiện chuyển tiền.

**Grain:** Một record đại diện cho một tài khoản thụ hưởng được đăng ký.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| beneficiary\_id | STRING | No | PK | Mã định danh người thụ hưởng |
| ib\_user\_id | STRING | No | FK | Người dùng Internet Banking đăng ký |
| account\_number | STRING | No | - | Số tài khoản thụ hưởng |
| bank\_code | STRING | No | - | Mã ngân hàng thụ hưởng |
| account\_name | STRING | Yes | - | Tên chủ tài khoản thụ hưởng |
| alias | STRING | Yes | - | Tên gợi nhớ do người dùng đặt |
| is\_verified | BOOLEAN | No | - | Đã xác minh thông tin thụ hưởng hay chưa |
| transfer\_count | BIGINT | No | - | Tổng số lần chuyển tiền tới người thụ hưởng |
| last\_transfer\_at | TIMESTAMP | Yes | - | Thời điểm chuyển tiền gần nhất |
| created\_at | TIMESTAMP | No | - | Thời điểm đăng ký |
| status | STRING | No | - | Trạng thái người thụ hưởng |

**Data Quality Rules:**

- `beneficiary_id` phải duy nhất.
- `ib_user_id` phải tồn tại trong `ib_users`.
- `account_number` không được rỗng.
- `bank_code` phải thuộc danh mục ngân hàng được hỗ trợ.
- `transfer_count` không được âm.
- `last_transfer_at` không được nhỏ hơn `created_at` nếu thời điểm đăng ký là thời điểm bắt đầu hiệu lực.
- `is_verified` phải là BOOLEAN hợp lệ.

### 4.2. `ib_sessions.csv` – Internet Banking Sessions

**Mô tả:** Lưu lịch sử phiên đăng nhập của người dùng Internet Banking, phục vụ theo dõi hoạt động và phân tích bảo mật.

**Grain:** Một record đại diện cho một phiên đăng nhập.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| session\_id | STRING | No | PK | Mã phiên đăng nhập |
| ib\_user\_id | STRING | No | FK | Mã người dùng Internet Banking |
| ip\_address | STRING | No | - | Địa chỉ IP đăng nhập |
| user\_agent | TEXT | Yes | - | Thông tin trình duyệt hoặc ứng dụng |
| device\_fingerprint | STRING | Yes | - | Mã nhận diện thiết bị |
| login\_at | TIMESTAMP | No | - | Thời điểm đăng nhập |
| logout\_at | TIMESTAMP | Yes | - | Thời điểm đăng xuất |
| session\_duration\_s | BIGINT | Yes | - | Thời lượng phiên tính bằng giây |
| status | STRING | No | - | Trạng thái phiên |
| actions\_count | BIGINT | No | - | Số thao tác trong phiên |
| is\_suspicious | BOOLEAN | No | - | Đánh dấu phiên có dấu hiệu bất thường |
| country\_code | STRING(2) | Yes | - | Mã quốc gia theo ISO 3166-1 alpha-2 |

**Data Quality Rules:**

- `session_id` phải duy nhất.
- `ib_user_id` phải tồn tại trong `ib_users`.
- `ip_address` phải đúng định dạng IPv4 hoặc IPv6.
- `logout_at` phải lớn hơn hoặc bằng `login_at`.
- `session_duration_s` không được âm.
- `actions_count` không được âm.
- Nếu có cả `login_at`, `logout_at` và `session_duration_s`, cần kiểm tra tính nhất quán giữa chúng.
- `country_code` phải hợp lệ theo ISO 3166-1 alpha-2.

### 4.3. `ib_transfers.csv` – Internet Banking Transfers

**Mô tả:** Lưu các giao dịch chuyển tiền được thực hiện thông qua Internet Banking.

**Grain:** Một record đại diện cho một yêu cầu chuyển tiền.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| transfer\_id | STRING | No | PK | Mã giao dịch chuyển tiền Internet Banking |
| reference\_code | STRING | Yes | - | Mã tham chiếu giao dịch |
| ib\_user\_id | STRING | No | FK | Người dùng thực hiện chuyển tiền |
| from\_account | STRING | No | FK | Tài khoản nguồn |
| to\_account | STRING | No | - | Tài khoản thụ hưởng |
| to\_bank\_code | STRING | No | - | Mã ngân hàng thụ hưởng |
| to\_account\_name | STRING | Yes | - | Tên người thụ hưởng |
| amount | DECIMAL(20,4) | No | - | Số tiền chuyển |
| fee | DECIMAL(20,4) | Yes | - | Phí chuyển tiền |
| currency | STRING(3) | No | - | Loại tiền tệ |
| transfer\_type | STRING | No | - | Loại chuyển tiền |
| purpose | TEXT | Yes | - | Nội dung chuyển tiền |
| otp\_verified | BOOLEAN | No | - | OTP đã được xác minh hay chưa |
| otp\_method | STRING | Yes | - | Phương thức xác thực OTP |
| status | STRING | No | - | Trạng thái giao dịch |
| failure\_reason | TEXT | Yes | - | Nguyên nhân giao dịch thất bại |
| scheduled\_date | TIMESTAMP | Yes | - | Thời điểm dự kiến thực hiện |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo yêu cầu |
| processed\_at | TIMESTAMP | Yes | - | Thời điểm xử lý giao dịch |

**Data Quality Rules:**

- `transfer_id` phải duy nhất.
- `ib_user_id` phải tồn tại trong `ib_users`.
- `from_account` phải tồn tại trong `core_accounts`.
- `amount` phải lớn hơn 0.
- `fee` không được âm.
- `currency` phải thuộc danh mục tiền tệ hợp lệ.
- `processed_at` không được nhỏ hơn `created_at` nếu là thời điểm xử lý thực tế.
- Nếu giao dịch thành công, cần có `processed_at` theo định nghĩa trạng thái.
- Nếu giao dịch thất bại, cần kiểm tra `failure_reason`.
- Nếu `otp_verified = true`, cần có bằng chứng xác thực OTP theo hệ thống nguồn.
- Không được giả định rằng mọi giao dịch chuyển tiền đều cần OTP.

### 4.4. `ib_users.csv` – Internet Banking Users

**Mô tả:** Lưu tài khoản đăng nhập Internet Banking của khách hàng, thông tin xác thực và trạng thái bảo mật.

**Grain:** Một record đại diện cho một tài khoản người dùng Internet Banking.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| ib\_user\_id | STRING | No | PK | Mã người dùng Internet Banking |
| customer\_id | STRING | No | FK | Mã khách hàng liên kết |
| username | STRING | No | UK | Tên đăng nhập |
| hashed\_password | STRING | Yes | - | Giá trị mật khẩu đã được băm |
| 2fa\_method | STRING | Yes | - | Phương thức xác thực hai yếu tố |
| 2fa\_enabled | BOOLEAN | No | - | Có bật xác thực hai yếu tố hay không |
| login\_method | STRING | Yes | - | Phương thức đăng nhập |
| status | STRING | No | - | Trạng thái tài khoản Internet Banking |
| last\_login\_at | TIMESTAMP | Yes | - | Thời điểm đăng nhập gần nhất |
| last\_login\_ip | STRING | Yes | - | Địa chỉ IP đăng nhập gần nhất |
| failed\_attempts | INTEGER | No | - | Số lần đăng nhập thất bại |
| password\_changed\_at | TIMESTAMP | Yes | - | Thời điểm thay đổi mật khẩu gần nhất |
| created\_at | TIMESTAMP | No | - | Thời điểm tạo tài khoản |
| registered\_branch | STRING | Yes | FK | Chi nhánh đăng ký dịch vụ |

**Data Quality Rules:**

- `ib_user_id` phải duy nhất.
- `username` phải duy nhất theo phạm vi hệ thống xác thực.
- `customer_id` phải tồn tại trong `core_customers`.
- `registered_branch` nếu có phải tồn tại trong `core_branches`.
- `failed_attempts` không được âm.
- `last_login_at` không được nhỏ hơn `created_at`.
- Nếu `2fa_enabled = true`, cần có phương thức 2FA hợp lệ.
- `hashed_password` nếu được lưu phải tuân theo chính sách bảo mật và định dạng hash được phê duyệt.

\<badge color="danger"\>Sensitive data\</badge\> `hashed_password`, `last_login_ip` và thông tin xác thực phải được kiểm soát quyền truy cập. Không đưa dữ liệu mật khẩu vào báo cáo hoặc data mart phân tích thông thường.

**Giả định cần xác nhận:** Hệ thống có thực sự lưu `hashed_password` trong file CSV hay chỉ có trường này trong schema logic? Khuyến nghị không xuất trường này khỏi hệ thống xác thực.

---

## 5\. MOBILE BANKING DOMAIN

### 5.1. `mb_devices.csv` – Registered Mobile Devices

**Mô tả:** Lưu thông tin thiết bị di động được khách hàng đăng ký sử dụng Mobile Banking.

**Grain:** Một record đại diện cho một thiết bị đã đăng ký.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| device\_id | STRING | No | PK | Mã định danh thiết bị |
| customer\_id | STRING | No | FK | Mã khách hàng sở hữu thiết bị |
| device\_model | STRING | Yes | - | Model thiết bị |
| os\_type | STRING | No | - | Hệ điều hành thiết bị |
| os\_version | STRING | Yes | - | Phiên bản hệ điều hành |
| app\_version | STRING | Yes | - | Phiên bản ứng dụng Mobile Banking |
| fcm\_token | STRING | Yes | - | Token phục vụ Firebase Cloud Messaging |
| device\_name | STRING | Yes | - | Tên thiết bị |
| is\_primary | BOOLEAN | No | - | Đánh dấu thiết bị chính |
| biometric\_enabled | BOOLEAN | No | - | Có bật xác thực sinh trắc học hay không |
| pin\_enabled | BOOLEAN | No | - | Có bật xác thực PIN hay không |
| registered\_at | TIMESTAMP | No | - | Thời điểm đăng ký thiết bị |
| last\_active\_at | TIMESTAMP | Yes | - | Thời điểm hoạt động gần nhất |
| last\_gps\_lat | DECIMAL(10,7) | Yes | - | Vĩ độ GPS gần nhất |
| last\_gps\_lng | DECIMAL(10,7) | Yes | - | Kinh độ GPS gần nhất |
| status | STRING | No | - | Trạng thái thiết bị |
| push\_enabled | BOOLEAN | No | - | Có cho phép nhận push notification hay không |

**Data Quality Rules:**

- `device_id` phải duy nhất.
- `customer_id` phải tồn tại trong `core_customers`.
- `last_gps_lat` nằm trong khoảng -90 đến 90.
- `last_gps_lng` nằm trong khoảng -180 đến 180.
- `last_active_at` không được nhỏ hơn `registered_at` nếu hai trường có cùng ngữ nghĩa thời gian.
- `os_type` phải thuộc danh mục hệ điều hành được hỗ trợ.
- `fcm_token` phải được bảo vệ như một thông tin định danh thiết bị.
- Không giả định mỗi khách hàng chỉ có một thiết bị.

### 5.2. `mb_push_notifications.csv` – Mobile Push Notifications

**Mô tả:** Lưu lịch sử thông báo push được gửi tới thiết bị Mobile Banking, bao gồm trạng thái gửi, nhận và mở thông báo.

**Grain:** Một record đại diện cho một thông báo được gửi tới một thiết bị.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| notification\_id | STRING | No | PK | Mã thông báo |
| device\_id | STRING | No | FK | Thiết bị nhận thông báo |
| notification\_type | STRING | No | - | Loại thông báo |
| title | STRING | Yes | - | Tiêu đề thông báo |
| body | TEXT | Yes | - | Nội dung thông báo |
| data\_payload | JSON | Yes | - | Dữ liệu bổ sung gửi kèm |
| priority | STRING | Yes | - | Mức độ ưu tiên |
| sent\_at | TIMESTAMP | No | - | Thời điểm gửi thông báo |
| delivered\_at | TIMESTAMP | Yes | - | Thời điểm thông báo được xác nhận đã nhận |
| opened\_at | TIMESTAMP | Yes | - | Thời điểm người dùng mở thông báo |
| is\_opened | BOOLEAN | No | - | Đánh dấu thông báo đã được mở |
| channel | STRING | Yes | - | Kênh gửi thông báo |
| status | STRING | No | - | Trạng thái thông báo |

**Data Quality Rules:**

- `notification_id` phải duy nhất.
- `device_id` phải tồn tại trong `mb_devices`.
- `delivered_at` không được nhỏ hơn `sent_at`.
- `opened_at` không được nhỏ hơn `sent_at`.
- Nếu `is_opened = true`, cần có `opened_at`.
- Nếu `status` biểu thị gửi thất bại, cần xác định thông tin nguyên nhân lỗi nếu nguồn có cung cấp.
- `data_payload` phải là JSON hợp lệ.

**Giả định cần xác nhận:** `delivered_at` có thể là thời điểm thiết bị nhận thông báo hay chỉ là thời điểm hệ thống push provider xác nhận giao nhận? Hai định nghĩa này không giống nhau.

### 5.3. `mb_qr_payments.csv` – QR Payments

**Mô tả:** Lưu các giao dịch thanh toán bằng QR Code được thực hiện thông qua Mobile Banking.

**Grain:** Một record đại diện cho một giao dịch thanh toán QR.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| qr\_id | STRING | No | PK | Mã định danh giao dịch QR |
| from\_device\_id | STRING | No | FK | Thiết bị thực hiện thanh toán |
| merchant\_id | STRING | Yes | - | Mã định danh đơn vị chấp nhận thanh toán |
| merchant\_name | STRING | Yes | - | Tên đơn vị chấp nhận thanh toán |
| amount | DECIMAL(20,4) | No | - | Số tiền thanh toán |
| currency | STRING(3) | No | - | Loại tiền tệ |
| qr\_type | STRING | No | - | Loại QR Code |
| qr\_content | TEXT | Yes | - | Nội dung hoặc dữ liệu QR |
| status | STRING | No | - | Trạng thái thanh toán |
| paid\_at | TIMESTAMP | Yes | - | Thời điểm thanh toán thành công |
| vietqr\_trace | STRING | Yes | - | Mã tham chiếu giao dịch VietQR |
| lat | DECIMAL(10,7) | Yes | - | Vĩ độ địa điểm giao dịch |
| lng | DECIMAL(10,7) | Yes | - | Kinh độ địa điểm giao dịch |

**Data Quality Rules:**

- `qr_id` phải duy nhất.
- `from_device_id` phải tồn tại trong `mb_devices`.
- `amount` phải lớn hơn 0.
- `currency` phải thuộc danh mục tiền tệ hợp lệ.
- `lat` nằm trong khoảng -90 đến 90.
- `lng` nằm trong khoảng -180 đến 180.
- `paid_at` phải có giá trị nếu trạng thái là thanh toán thành công.
- `vietqr_trace` nên được kiểm tra tính duy nhất theo phạm vi mà hệ thống thanh toán quy định.
- `qr_content` không được chứa dữ liệu nhạy cảm không cần thiết.

**Giả định cần xác nhận:**

- `qr_type` phân biệt QR tĩnh và QR động hay có những loại khác?
- `paid_at` chỉ ghi nhận thanh toán thành công hay ghi nhận thời điểm xử lý cuối cùng?
- `merchant_id` có bảng merchant master riêng hay không?

### 5.4. `mb_sessions.csv` – Mobile Banking Sessions

**Mô tả:** Lưu lịch sử phiên sử dụng ứng dụng Mobile Banking, bao gồm phương thức đăng nhập, thời lượng, hoạt động trong ứng dụng, thông tin mạng và vị trí.

**Grain:** Một record đại diện cho một phiên sử dụng ứng dụng trên một thiết bị.

| Column | Data Type | Nullable | Key | Business Description |
| --- | --- | --- | --- | --- |
| session\_id | STRING | No | PK | Mã phiên Mobile Banking |
| device\_id | STRING | No | FK | Thiết bị sử dụng phiên |
| login\_method | STRING | Yes | - | Phương thức đăng nhập |
| session\_start | TIMESTAMP | No | - | Thời điểm bắt đầu phiên |
| session\_end | TIMESTAMP | Yes | - | Thời điểm kết thúc phiên |
| duration\_seconds | BIGINT | Yes | - | Thời lượng phiên tính bằng giây |
| screen\_count | INTEGER | Yes | - | Số màn hình được truy cập |
| gps\_lat | DECIMAL(10,7) | Yes | - | Vĩ độ GPS tại thời điểm phiên |
| gps\_lng | DECIMAL(10,7) | Yes | - | Kinh độ GPS tại thời điểm phiên |
| network\_type | STRING | Yes | - | Loại kết nối mạng |
| is\_rooted | BOOLEAN | Yes | - | Thiết bị có dấu hiệu root hay không |
| is\_vpn | BOOLEAN | Yes | - | Phiên sử dụng VPN hay không |
| status | STRING | No | - | Trạng thái phiên |
| app\_version | STRING | Yes | - | Phiên bản ứng dụng tại thời điểm phiên |

**Data Quality Rules:**

- `session_id` phải duy nhất.
- `device_id` phải tồn tại trong `mb_devices`.
- `session_end` phải lớn hơn hoặc bằng `session_start`.
- `duration_seconds` không được âm.
- `screen_count` không được âm.
- `gps_lat` nằm trong khoảng -90 đến 90.
- `gps_lng` nằm trong khoảng -180 đến 180.
- `duration_seconds` cần nhất quán với thời gian bắt đầu và kết thúc nếu cả ba giá trị đều có.
- `is_rooted` và `is_vpn` có thể NULL nếu hệ thống không xác định được trạng thái.

---

# PHẦN II – DATA CONTRACT

## 6\. Contract tổng thể

### 6.1. Dataset inventory

Có một điểm cần đính chính: danh sách đầu vào thực tế có **17 file CSV**, không phải 15 file như mô tả ban đầu.

| Domain | Dataset | Number of tables |
| --- | --- | --- |
| Core Banking | `core_accounts`, `core_branches`, `core_customers`, `core_employees`, `core_transactions` | 5 |
| CRM | `crm_campaigns`, `crm_contacts`, `crm_interactions` | 3 |
| Internet Banking | `ib_beneficiaries`, `ib_sessions`, `ib_transfers`, `ib_users` | 4 |
| Mobile Banking | `mb_devices`, `mb_push_notifications`, `mb_qr_payments`, `mb_sessions` | 4 |
|  | **Total** | **16** |

Cần sửa lại phép đếm: danh sách Internet Banking có 5 bảng, không phải 4. Tổng số chính xác là **17 bảng**.

### 6.2. Contract metadata đề xuất

Mỗi dataset nên có metadata thống nhất:

| Attribute | Value / Definition |
| --- | --- |
| Contract name | Tên contract tương ứng với dataset |
| Contract version | `1.0.0` |
| Data owner | Đơn vị nghiệp vụ sở hữu dữ liệu |
| Data producer | Hệ thống nguồn tạo dữ liệu |
| Data consumer | ETL, DWH, Data Lakehouse, BI |
| Format | CSV |
| Encoding | UTF-8 |
| Delimiter | Comma (`,`) |
| Header | Required |
| Null representation | Cần thống nhất, đề xuất empty field |
| Date format | `YYYY-MM-DD` |
| Timestamp format | ISO 8601 với timezone |
| Decimal separator | `.` |
| Schema evolution | Semantic Versioning |
| Data classification | Theo chính sách phân loại dữ liệu ngân hàng |

### 6.3. Quy tắc versioning

Áp dụng Semantic Versioning:

| Version change | Ý nghĩa | Ví dụ |
| --- | --- | --- |
| MAJOR | Thay đổi phá vỡ tương thích | Xóa column, đổi kiểu dữ liệu, đổi ý nghĩa field |
| MINOR | Bổ sung tương thích ngược | Thêm nullable column |
| PATCH | Sửa mô tả hoặc quy tắc không ảnh hưởng schema | Sửa wording, bổ sung mô tả |

Ví dụ:

- `1.0.0`: Phiên bản contract ban đầu.
- `1.1.0`: Bổ sung trường `account_category` cho phép NULL.
- `2.0.0`: Đổi `balance` từ DECIMAL sang STRING hoặc thay đổi ngữ nghĩa của trường.

---

## 7\. Contract theo từng domain

### 7.1. Core Banking Contract

| Dataset | Primary Key | Foreign Key | Required Fields | Main Validation |
| --- | --- | --- | --- | --- |
| core\_accounts | account\_id | customer\_id, branch\_id | account\_id, customer\_id, account\_number, currency, balance, status | Unique account, valid currency, valid balance |
| core\_branches | branch\_id | - | branch\_id, bank\_code, bank\_name, branch\_name, status | Unique branch, valid bank identifiers |
| core\_customers | customer\_id | branch\_id | customer\_id, customer\_type, full\_name, kyc\_status, is\_active | Valid customer type, KYC and risk values |
| core\_employees | employee\_id | branch\_id | employee\_id, branch\_id, full\_name, role, hire\_date, employee\_code, status | Unique employee, valid branch |
| core\_transactions | transaction\_id | from\_account, to\_account | transaction\_id, amount, currency, transaction\_type, channel, status, transaction\_date, created\_at | Positive amount, valid accounts, valid transaction status |

**Domain-level rules:**

1. Mọi `customer_id` trong tài khoản phải tham chiếu được khách hàng hợp lệ.
2. Tài khoản phải có thông tin chủ sở hữu.
3. Giao dịch tài chính phải có mã giao dịch duy nhất.
4. Các giao dịch cần kiểm tra tính nhất quán giữa số tiền, tiền tệ và tài khoản.
5. Các giao dịch đảo phải liên kết được với giao dịch gốc.
6. Dữ liệu chi nhánh phải thống nhất giữa khách hàng, nhân viên và tài khoản.

### 7.2. CRM Contract

| Dataset | Primary Key | Foreign Key | Required Fields | Main Validation |
| --- | --- | --- | --- | --- |
| crm\_campaigns | campaign\_id | created\_by? | campaign\_id, campaign\_name, campaign\_type, start\_date, end\_date, status | Valid date range, non-negative metrics |
| crm\_contacts | contact\_id | customer\_id, assigned\_rm? | contact\_id, customer\_id, is\_vip | Valid customer, valid churn score |
| crm\_interactions | interaction\_id | contact\_id, agent\_id? | interaction\_id, contact\_id, interaction\_type, channel, direction, follow\_up\_required, created\_at | Valid contact, duration and score validation |

**Domain-level rules:**

1. Mọi CRM contact phải gắn với một customer hợp lệ.
2. Mỗi interaction phải thuộc một contact.
3. Nhân viên phụ trách phải là nhân viên hợp lệ nếu dùng employee master.
4. Các chỉ số churn phải có định nghĩa thống nhất.
5. NPS và satisfaction score phải được tách biệt về ngữ nghĩa.

### 7.3. Internet Banking Contract

| Dataset | Primary Key | Foreign Key | Required Fields | Main Validation |
| --- | --- | --- | --- | --- |
| ib\_users | ib\_user\_id | customer\_id, registered\_branch? | ib\_user\_id, customer\_id, username, status, created\_at | Unique username, valid customer |
| ib\_beneficiaries | beneficiary\_id | ib\_user\_id | beneficiary\_id, ib\_user\_id, account\_number, bank\_code, is\_verified, status | Valid user, valid bank code |
| ib\_sessions | session\_id | ib\_user\_id | session\_id, ib\_user\_id, ip\_address, login\_at, status | Valid IP, valid session duration |
| ib\_transfers | transfer\_id | ib\_user\_id, from\_account | transfer\_id, ib\_user\_id, from\_account, to\_account, amount, currency, status, created\_at | Positive amount, valid user and account |

**Domain-level rules:**

1. Một customer có thể có một hoặc nhiều tài khoản Internet Banking nếu nghiệp vụ cho phép.
2. Mỗi user có thể có nhiều sessions.
3. Mỗi user có thể đăng ký nhiều beneficiaries.
4. Một user có thể tạo nhiều transfer requests.
5. Mọi transfer cần liên kết với người dùng và tài khoản nguồn hợp lệ.
6. Không mặc định một transfer request tương ứng với một transaction đã hạch toán thành công.

### 7.4. Mobile Banking Contract

| Dataset | Primary Key | Foreign Key | Required Fields | Main Validation |
| --- | --- | --- | --- | --- |
| mb\_devices | device\_id | customer\_id | device\_id, customer\_id, os\_type, is\_primary, status | Valid customer, valid GPS |
| mb\_push\_notifications | notification\_id | device\_id | notification\_id, device\_id, notification\_type, sent\_at, is\_opened, status | Valid device, valid timestamps |
| mb\_qr\_payments | qr\_id | from\_device\_id | qr\_id, from\_device\_id, amount, currency, qr\_type, status | Positive amount, valid device and GPS |
| mb\_sessions | session\_id | device\_id | session\_id, device\_id, session\_start, status | Valid device, valid duration and GPS |

**Domain-level rules:**

1. Một customer có thể đăng ký nhiều thiết bị.
2. Một thiết bị có thể có nhiều phiên sử dụng.
3. Một thiết bị có thể nhận nhiều push notifications.
4. Một thiết bị có thể thực hiện nhiều giao dịch QR.
5. Các thông tin vị trí GPS cần được kiểm tra tính hợp lệ và chính sách quyền riêng tư.
6. Thông tin FCM token cần được kiểm soát truy cập.

---

## 8\. Data Relationship – Mối quan hệ giữa các bảng

Đây là phần quan trọng để thiết kế Data Warehouse và xác định Referential Integrity.

### 8.1. Entity Relationship Overview

\<box border radius="lg" padding={3} gap={2}\> \*\*Core Banking – Customer 360\*\* \<box background="rgba(59,130,246,0.08)" radius="md" padding={2} align=center\> \*\*core\_branches\*\* \<text color="secondary" size="xs"\>PK: branch\_id\</text\> \</box\> \<row justify=center\> \<icon name="arrow-down" color="secondary" size="lg"/\> \</row\> \<grid columns={2} gap={2}\> \<grid-item\> \<box background="rgba(59,130,246,0.08)" radius="md" padding={2} align=center\> \*\*core\_customers\*\* \<text color="secondary" size="xs"\>PK: customer\_id\</text\> \</box\> \</grid-item\> \<grid-item\> \<box background="rgba(59,130,246,0.08)" radius="md" padding={2} align=center\> \*\*core\_employees\*\* \<text color="secondary" size="xs"\>PK: employee\_id\</text\> \</box\> \</grid-item\> \</grid\> \<row justify=center\> \<icon name="arrow-down" color="secondary" size="lg"/\> \</row\> \<box background="rgba(59,130,246,0.08)" radius="md" padding={2} align=center\> \*\*core\_accounts\*\* \<text color="secondary" size="xs"\>PK: account\_id · FK: customer\_id\</text\> \</box\> \<row justify=center\> \<icon name="arrow-down" color="secondary" size="lg"/\> \</row\> \<box background="rgba(59,130,246,0.08)" radius="md" padding={2} align=center\> \*\*core\_transactions\*\* \<text color="secondary" size="xs"\>FK: from\_account, to\_account\</text\> \</box\> \<text color="secondary" size="xs"\>Sơ đồ thể hiện các quan hệ chính, không phải toàn bộ quan hệ giữa các bảng.\</text\> \</box\>

### 8.2. Quan hệ chi tiết

| Parent Table | Parent Key | Child Table | Foreign Key | Relationship |
| --- | --- | --- | --- | --- |
| core\_branches | branch\_id | core\_customers | branch\_id | 1:N |
| core\_branches | branch\_id | core\_accounts | branch\_id | 1:N |
| core\_branches | branch\_id | core\_employees | branch\_id | 1:N |
| core\_customers | customer\_id | core\_accounts | customer\_id | 1:N |
| core\_customers | customer\_id | crm\_contacts | customer\_id | 1:N\* |
| core\_customers | customer\_id | ib\_users | customer\_id | 1:N\* |
| core\_customers | customer\_id | mb\_devices | customer\_id | 1:N |
| core\_accounts | account\_id | core\_transactions | from\_account | 1:N |
| core\_accounts | account\_id | core\_transactions | to\_account | 1:N\* |
| core\_employees | employee\_id | crm\_campaigns | created\_by | 1:N\* |
| core\_employees | employee\_id | crm\_contacts | assigned\_rm | 1:N\* |
| core\_employees | employee\_id | crm\_interactions | agent\_id | 1:N\* |
| crm\_contacts | contact\_id | crm\_interactions | contact\_id | 1:N |
| ib\_users | ib\_user\_id | ib\_beneficiaries | ib\_user\_id | 1:N |
| ib\_users | ib\_user\_id | ib\_sessions | ib\_user\_id | 1:N |
| ib\_users | ib\_user\_id | ib\_transfers | ib\_user\_id | 1:N |
| mb\_devices | device\_id | mb\_push\_notifications | device\_id | 1:N |
| mb\_devices | device\_id | mb\_qr\_payments | from\_device\_id | 1:N |
| mb\_devices | device\_id | mb\_sessions | device\_id | 1:N |

\* Quan hệ cần xác nhận theo nghiệp vụ hoặc cách thiết kế hệ thống nguồn.

### 8.3. Những quan hệ còn thiếu cần bổ sung

Một số quan hệ nghiệp vụ có thể tồn tại nhưng chưa thể biểu diễn trực tiếp bằng các column hiện tại:

| Relationship | Hiện trạng | Đề xuất |
| --- | --- | --- |
| ib\_transfers → core\_transactions | Chưa có FK trực tiếp | Bổ sung `transaction_id` hoặc mapping table |
| mb\_qr\_payments → core\_transactions | Chưa có FK trực tiếp | Bổ sung `transaction_id` |
| ib\_beneficiaries → core\_accounts | Chỉ có account\_number | Có thể tạo mapping với tài khoản nội bộ |
| crm\_campaigns → crm\_contacts | Chưa có bảng campaign membership | Tạo `crm_campaign_members` |
| core\_transactions → reversal transaction | Có `reversal_txn_id` | Xác nhận chiều tham chiếu |
| ib\_sessions → mb\_devices | Chưa có liên kết rõ ràng | Chỉ liên kết nếu có chung device identity đáng tin cậy |

**Lưu ý:** Không nên ép các bảng có cùng tên hoặc cùng kiểu dữ liệu thành quan hệ FK nếu chưa xác nhận cùng định nghĩa nghiệp vụ.

---

# PHẦN III – DATA QUALITY & VALIDATION CONTRACT

## 9\. Quy tắc Data Quality tổng thể

Nên triển khai các quy tắc Data Quality theo 6 nhóm.

| DQ Category | Mô tả | Ví dụ |
| --- | --- | --- |
| Completeness | Kiểm tra dữ liệu đầy đủ | account\_id không NULL |
| Uniqueness | Kiểm tra tính duy nhất | customer\_id không duplicate |
| Validity | Kiểm tra định dạng và giá trị | email đúng định dạng |
| Consistency | Kiểm tra tính nhất quán | updated\_at \>= created\_at |
| Referential Integrity | Kiểm tra quan hệ FK | customer\_id tồn tại |
| Timeliness | Kiểm tra độ trễ dữ liệu | File được cung cấp đúng SLA |

### 9.1. Severity Level

| Severity | Ý nghĩa | Hành động |
| --- | --- | --- |
| CRITICAL | Lỗi ảnh hưởng nghiêm trọng đến tính đúng đắn hoặc an toàn dữ liệu | Reject batch hoặc quarantine |
| HIGH | Lỗi ảnh hưởng đến nghiệp vụ hoặc tính toàn vẹn | Reject record hoặc quarantine |
| MEDIUM | Lỗi chất lượng có thể xử lý sau | Cảnh báo, đưa vào DQ report |
| LOW | Lỗi mô tả hoặc chuẩn hóa | Ghi nhận và theo dõi |

### 9.2. Validation rules đề xuất

| Rule ID | Domain | Validation | Severity |
| --- | --- | --- | --- |
| DQ001 | All | Primary key không được NULL | CRITICAL |
| DQ002 | All | Primary key không được duplicate | CRITICAL |
| DQ003 | All | Schema phải đúng contract | CRITICAL |
| DQ004 | All | Data type phải đúng định nghĩa | HIGH |
| DQ005 | All | Timestamp phải đúng định dạng | HIGH |
| DQ006 | Core | Customer FK phải tồn tại | HIGH |
| DQ007 | Core | Account FK phải tồn tại | HIGH |
| DQ008 | Core | Transaction amount phải hợp lệ | HIGH |
| DQ009 | CRM | Churn score phải nằm trong miền giá trị | MEDIUM |
| DQ010 | CRM | Campaign date phải hợp lệ | MEDIUM |
| DQ011 | IB | IP address phải hợp lệ | MEDIUM |
| DQ012 | IB | Session duration không âm | MEDIUM |
| DQ013 | MB | GPS latitude/longitude hợp lệ | MEDIUM |
| DQ014 | MB | Push notification timestamps hợp lệ | MEDIUM |
| DQ015 | MB | QR payment amount phải lớn hơn 0 | HIGH |

## 10\. File-level Contract

Ngoài việc kiểm tra từng record, cần kiểm tra toàn bộ file CSV trước khi đưa vào pipeline.

| Validation | Rule | Severity |
| --- | --- | --- |
| File existence | File phải tồn tại theo lịch cung cấp | CRITICAL |
| File naming | Đúng tên file quy định | HIGH |
| Header validation | Column name phải khớp schema | CRITICAL |
| Column count | Đúng số lượng column | CRITICAL |
| Encoding | UTF-8 | HIGH |
| Delimiter | Comma | HIGH |
| Duplicate header | Không có column name trùng | HIGH |
| Empty file | Không có file rỗng ngoài quy định | HIGH |
| Row count | Không có biến động bất thường | MEDIUM |
| File freshness | Đúng SLA cung cấp | HIGH |
| File integrity | Kiểm tra checksum nếu có | HIGH |

### 10.1. Schema drift policy

Nếu hệ thống nguồn thay đổi schema:

- Thêm column mới: chỉ chấp nhận khi có thay đổi contract được phê duyệt.
- Xóa column: cần đánh giá breaking change.
- Đổi data type: cần đánh giá breaking change.
- Đổi ý nghĩa nghiệp vụ: bắt buộc cập nhật contract version.
- Thay đổi giá trị enum: cập nhật danh mục dữ liệu và kiểm tra downstream.

Không nên tự động bỏ qua column lạ hoặc tự động ép kiểu để pipeline tiếp tục chạy mà không ghi nhận thay đổi.

---

# PHẦN IV – SECURITY & GOVERNANCE

## 11\. Data Classification

Dữ liệu ngân hàng có nhiều trường thông tin cá nhân và thông tin xác thực. Đề xuất phân loại như sau:

| Classification | Ví dụ columns | Recommended Control |
| --- | --- | --- |
| PUBLIC / INTERNAL | branch\_name, branch\_type | Access theo phạm vi nội bộ |
| CONFIDENTIAL | balance, amount, account\_number | RBAC, masking, audit |
| PERSONAL DATA | full\_name, phone, email, dob, address | Hạn chế truy cập, masking |
| SENSITIVE PERSONAL | cccd, tax\_code, GPS coordinates | Kiểm soát truy cập chặt chẽ |
| SECURITY SENSITIVE | hashed\_password, fcm\_token, IP, device\_fingerprint | Hạn chế tối đa, mã hóa và audit |

### 11.1. Các yêu cầu bảo mật

1. Không lưu password dạng plaintext.
2. Không đưa `hashed_password` vào các bảng phân tích nếu không có nhu cầu nghiệp vụ hợp lệ.
3. Mask `cccd`, account number, phone và email khi hiển thị trên dashboard.
4. Hạn chế quyền truy cập GPS và device fingerprint.
5. Mã hóa dữ liệu nhạy cảm khi lưu trữ và truyền tải.
6. Ghi audit log đối với các hoạt động truy cập dữ liệu quan trọng.
7. Xác định thời hạn lưu trữ và cơ chế xóa dữ liệu theo chính sách ngân hàng và quy định pháp luật áp dụng.
8. Không sử dụng dữ liệu khách hàng thật trong môi trường development hoặc testing nếu chưa có biện pháp bảo vệ phù hợp.

---

# PHẦN V – ASSUMPTIONS & OPEN QUESTIONS

## 12\. Danh sách giả định cần xác nhận

Đây là phần rất quan trọng trước khi chuyển tài liệu từ Draft sang Approved.

| ID | Table | Assumption / Question | Priority |
| --- | --- | --- | --- |
| A001 | All | ID sử dụng UUID, mã nghiệp vụ hay mã tự sinh? | HIGH |
| A002 | All | Tất cả timestamp sử dụng timezone nào? | HIGH |
| A003 | All | File CSV được full load hay incremental load? | HIGH |
| A004 | All | NULL được biểu diễn như thế nào? | HIGH |
| A005 | core\_accounts | Balance là số dư cuối ngày hay số dư tại thời điểm trích xuất? | HIGH |
| A006 | core\_accounts | Account number có duy nhất toàn ngân hàng không? | HIGH |
| A007 | core\_customers | `dob` của corporate customer có phải ngày thành lập? | MEDIUM |
| A008 | core\_transactions | Một record là transaction hay accounting entry? | CRITICAL |
| A009 | core\_transactions | `reversal_txn_id` trỏ đến giao dịch gốc hay giao dịch đảo? | HIGH |
| A010 | crm\_campaigns | Các tỷ lệ lưu theo 0–1 hay 0–100? | HIGH |
| A011 | crm\_contacts | Churn score sử dụng thang điểm nào? | HIGH |
| A012 | crm\_contacts | Một customer có thể có nhiều contact không? | MEDIUM |
| A013 | crm\_interactions | Satisfaction score sử dụng thang điểm nào? | MEDIUM |
| A014 | ib\_beneficiaries | Beneficiary có thể là tài khoản nội bộ và liên ngân hàng không? | MEDIUM |
| A015 | ib\_sessions | Session có liên kết với device identity không? | MEDIUM |
| A016 | ib\_transfers | Có mapping trực tiếp với core\_transactions không? | CRITICAL |
| A017 | ib\_users | `hashed_password` có thực sự được export không? | CRITICAL |
| A018 | mb\_devices | Một customer được đăng ký tối đa bao nhiêu thiết bị? | MEDIUM |
| A019 | mb\_push\_notifications | Delivered\_at là thời điểm provider xác nhận hay thiết bị nhận? | MEDIUM |
| A020 | mb\_qr\_payments | QR payment có liên kết với core transaction không? | HIGH |
| A021 | mb\_sessions | GPS được thu thập theo thời điểm nào trong session? | MEDIUM |
| A022 | core\_branches | `napas_bin` là BIN ngân hàng hay mã chi nhánh? | HIGH |

---

# PHẦN VI – KHUYẾN NGHỊ TRIỂN KHAI

## 13\. Kiến trúc Data Pipeline đề xuất

Với 4 domain dữ liệu trên, có thể triển khai kiến trúc Medallion Architecture.

\<box border radius="lg" padding={3} gap={3}\> \<title size="lg"\>Banking Data Platform\</title\> \<box background="rgba(59,130,246,0.09)" radius="md" padding={3} gap={1}\> \*\*Source Layer\*\* \<text color="secondary" size="xs"\>16 CSV files · Core Banking · CRM · IB · MB\</text\> \</box\> \<row justify=center\> \<icon name="arrow-down" color="secondary"/\> \</row\> \<box background="rgba(14,165,233,0.09)" radius="md" padding={3} gap={1}\> \*\*Bronze Layer\*\* \<text color="secondary" size="xs"\>Raw data · Original schema · Ingestion metadata\</text\> \</box\> \<row justify=center\> \<icon name="arrow-down" color="secondary"/\> \</row\> \<box background="rgba(16,185,129,0.09)" radius="md" padding={3} gap={1}\> \*\*Silver Layer\*\* \<text color="secondary" size="xs"\>Data cleansing · Schema validation · Deduplication · Referential integrity\</text\> \</box\> \<row justify=center\> \<icon name="arrow-down" color="secondary"/\> \</row\> \<box background="rgba(139,92,246,0.09)" radius="md" padding={3} gap={1}\> \*\*Gold Layer\*\* \<text color="secondary" size="xs"\>Customer 360 · Account Analytics · Transaction Analytics · CRM Analytics · Digital Banking Analytics\</text\> \</box\> \<row justify=center\> \<icon name="arrow-down" color="secondary"/\> \</row\> \<box background="rgba(245,158,11,0.09)" radius="md" padding={3} gap={1}\> \*\*Consumption Layer\*\* \<text color="secondary" size="xs"\>Power BI · Reporting · Risk Analytics · Customer Segmentation · Management Dashboard\</text\> \</box\> \</box\>

### 13.1. Vai trò của Data Contract trong pipeline

| Pipeline Stage | Data Contract Responsibility |
| --- | --- |
| Source → Bronze | Kiểm tra file format, schema, column names |
| Bronze → Silver | Kiểm tra data type, NULL, duplicate, FK |
| Silver → Gold | Kiểm tra business rules, relationship, aggregation |
| Gold → BI | Đảm bảo metric và business definitions thống nhất |

### 13.2. Metadata nên bổ sung cho mỗi bảng

Ngoài các column nghiệp vụ đã có, nên cân nhắc bổ sung metadata kỹ thuật trong Silver/Gold:

| Column | Data Type | Description |
| --- | --- | --- |
| `_source_system` | STRING | Hệ thống nguồn |
| `_ingestion_timestamp` | TIMESTAMP | Thời điểm ingest |
| `_batch_id` | STRING | Mã batch ingest |
| `_file_name` | STRING | Tên file nguồn |
| `_record_hash` | STRING | Hash phục vụ kiểm tra thay đổi |
| `_load_date` | DATE | Ngày load dữ liệu |
| `_contract_version` | STRING | Phiên bản contract áp dụng |

Các trường này nên được quản lý như metadata của Data Platform, không nhất thiết phải thêm vào file CSV nguồn.

---

## 14\. Checklist nghiệm thu Data Contract

Trước khi đưa dữ liệu vào production, cần hoàn thành:

- [ ]Xác nhận chính xác danh sách 16 bảng CSV.
- [ ]Xác nhận data type thực tế của từng column.
- [ ]Xác nhận Primary Key và Foreign Key.
- [ ]Xác nhận NULLABLE / NOT NULL.
- [ ]Xác nhận danh mục enum của các trường status, type, channel.
- [ ]Xác nhận timezone và format timestamp.
- [ ]Xác nhận logic full load / incremental load.
- [ ]Xác nhận business rules với Data Owner.
- [ ]Xác nhận Data Quality thresholds.
- [ ]Xác nhận Data Classification và quyền truy cập.
- [ ]Xác nhận version và approval của Data Contract.
- [ ]Xây dựng automated schema validation.

---

## 15\. Kết luận và trạng thái tài liệu

\<box border radius="lg" padding={3} gap={3}\> \<row align=center justify=between\> \*\*Document status\*\* \<badge color="warning"\>DRAFT – Pending Approval\</badge\> \</row\> | Hạng mục | Trạng thái | |---|---| | Column inventory | \<badge color="success"\>Completed\</badge\> | | Column descriptions | \<badge color="success"\>Drafted\</badge\> | | Proposed data types | \<badge color="success"\>Drafted\</badge\> | | Primary / Foreign Keys | \<badge color="warning"\>Need confirmation\</badge\> | | Business rules | \<badge color="warning"\>Need confirmation\</badge\> | | Data quality rules | \<badge color="success"\>Proposed\</badge\> | | Security classification | \<badge color="warning"\>Need approval\</badge\> | | Production contract | \<badge color="warning"\>Not approved\</badge\> | \</box\>

**Lưu ý về phạm vi:** Danh sách bạn cung cấp có chính xác **16 file CSV**, gồm Core Banking (5), CRM (3), Internet Banking (4) và Mobile Banking (4). Tài liệu đã bao phủ cả 16 bảng. Kiểu dữ liệu, khóa và business rules hiện là đề xuất thiết kế, chưa được xác nhận bằng dữ liệu mẫu hoặc tài liệu chính thức từ Data Owner.

**Khuyến nghị tiếp theo:** Nên chuyển tài liệu này thành một bộ Excel Data Dictionary gồm 16 sheets tương ứng 16 bảng, một sheet Data Relationships, một sheet Data Quality Rules và một sheet Assumptions. Đây sẽ là tài liệu thuận tiện để BA, Data Engineer, Data Architect và Data Owner cùng review, chỉnh sửa và phê duyệt trước khi triển khai pipeline.