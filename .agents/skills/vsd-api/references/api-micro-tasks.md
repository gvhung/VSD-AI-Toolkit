# Hướng Dẫn Thực Thi Micro-Tasks Tuần Tự (Continuous Auto-Advance)

Tài liệu này hướng dẫn chi tiết quy trình thực thi từng bước trong micro-tasks dành cho Agent `vsd-api`.

---

## Task 1: Đặc Tả Nghiệp Vụ & Kế Hoạch Kỹ Thuật (SDD)

1. **Đọc đầu vào từ người dùng**: Xác định `subsystem`, `group`, `component`, `entity`, `vietnamese_name`.
2. **Khởi tạo thư mục tài liệu**:
   - `docs/{subsystem}/`
   - `docs/{subsystem}/{group}/`
3. **Sinh các tệp**:
   - `docs/{subsystem}/PLAN-{subsystem}-{group}.md` (sử dụng template [plan.md.template](../resources/templates/docs/plan.md.template))
   - `docs/{subsystem}/{group}/{component}_specs.md` (sử dụng template [specs.md.template](../resources/templates/docs/specs.md.template))
   - `docs/{subsystem}/{group}/{component}_tasks.md` (sử dụng template [tasks.md.template](../resources/templates/docs/tasks.md.template))
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 1` trong `{component}_tasks.md`.

---

## Task 2: Migration DDL & Row-Level Security (PostgreSQL)

1. **Khởi tạo thư mục**: `docs/{subsystem}/{group}/sql/`
2. **Sinh tệp migration**: `docs/{subsystem}/{group}/sql/{subsystem}_{group}_{component}.sql` (sử dụng template [sql.sql.template](../resources/templates/docs/sql.sql.template)).
3. **Kiểm tra**:
   - Khóa chính UUID (`gen_random_uuid()`).
   - Cột `tenant_id UUID NOT NULL` (không dùng varchar).
   - Lệnh kích hoạt RLS: `CALL apply_rls_for_tables(ARRAY['<table_name>']);`.
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 2` trong `{component}_tasks.md`.

---

## Task 3: Tầng Model & Cấu Trúc ValidationError

1. **Khởi tạo thư mục**: `internal/{subsystem}/{group}/{component}/model/`
2. **Sinh tệp**: `internal/{subsystem}/{group}/{component}/model/model.go` (sử dụng template [model.go.template](../resources/templates/model/model.go.template)).
3. **Kiểm tra**:
   - Struct Entity có đầy đủ các trường audit và soft delete (`removed_at *time.Time`).
   - Cung cấp hàm `TableName() string`.
   - Có cấu trúc `FieldError` và `ValidationError`.
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 3` trong `{component}_tasks.md`.

---

## Task 4: Tầng Query Repository & Defensive Checks

1. **Khởi tạo thư mục**: `internal/{subsystem}/{group}/{component}/query/`
2. **Sinh tệp**: `internal/{subsystem}/{group}/{component}/query/query.go` (sử dụng template [query.go.template](../resources/templates/query/query.go.template)).
3. **Kiểm tra**:
   - Interface `I{ComponentPascal}Query` khai báo đủ 8 hàm.
   - Hàm `getDB` kiểm tra phòng thủ:
     ```go
     if tx == nil {
         return nil, errors.New("database transaction is required and cannot be nil")
     }
     ```
   - Tất cả truy vấn sử dụng tham số hóa `?`, tuyệt đối không cộng chuỗi.
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 4` trong `{component}_tasks.md`.

---

## Task 5: Ephemeral Test-First & Tầng Service (TDD Red-Green)

1. **Khởi tạo thư mục**: `internal/{subsystem}/{group}/{component}/service/`
2. **Sinh tệp test tạm thời**: `service/service_test.go` (sử dụng template [service_test.go.template](../resources/templates/service/service_test.go.template)).
   - Có header `// EPHEMERAL_TEST_FILE: True`.
   - Viết các test case kiểm tra biên: mã rỗng, tên rỗng, mã trùng, `tx == nil`.
3. **Chạy test (RED)**: Chạy `go test ./...` để xác nhận test chạy và phản ánh đúng trạng thái kiểm thử biên.
4. **Sinh tệp interface & service**:
   - `service/interface.go` (từ [interface.go.template](../resources/templates/service/interface.go.template))
   - `service/service.go` (từ [service.go.template](../resources/templates/service/service.go.template))
5. **Chạy test (GREEN)**: Chạy lại `go test` để xác nhận toàn bộ test case chuyển sang màu xanh (GREEN). Nếu có lỗi, kích hoạt **Self-Healing Loop** để sửa chữa.
6. **Cập nhật tiến độ**: Đánh dấu `[x] Task 5` trong `{component}_tasks.md`.

---

## Task 6: Tầng Handler (Gin Controller, RLS, IDOR & Godoc)

1. **Khởi tạo thư mục**: `internal/{subsystem}/{group}/{component}/handler/`
2. **Sinh tệp**: `internal/{subsystem}/{group}/{component}/handler/handler.go` (sử dụng template [handler.go.template](../resources/templates/handler/handler.go.template)).
3. **Kiểm tra**:
   - Hàm `executeWithTenant` thực thi `SET LOCAL app.current_tenant = ?`.
   - Ghi đè bắt buộc `input.TenantID = tenantID`.
   - Đầy đủ Godoc Swagger annotations trên cả 6 handlers.
   - Bọc Data Masking cho response lỗi.
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 6` trong `{component}_tasks.md`.

---

## Task 7: Tầng Router, Cybersecurity Gate Audit & Cleanup Test

1. **Sinh tệp router component**:
   - `internal/{subsystem}/{group}/{component}/router{{ComponentPascal}}.go` (sử dụng template [router.go.template](../resources/templates/router.go.template)).
2. **Tích hợp router cấp group & subsystem** (nếu chưa có):
   - `internal/{subsystem}/{group}/router{{GroupPascal}}.go`
   - `internal/{subsystem}/router{{SubsystemPascal}}.go`
3. **Chạy Anthropic Cybersecurity Gate**:
   - Quét kiểm tra các cổng an ninh qua `.agents/skills/vsd-api/scripts/audit-api-cybersecurity-gate.ps1` (hoặc `./scripts/audit-api-cybersecurity-gate.ps1`).
   - Xác nhận toàn bộ 7 cổng an ninh đạt chuẩn PASS (bao gồm OWASP API Security Top 10).
4. **Thực thi Definition of Done (DoD) - Xóa Ephemeral Test**:
   - Xóa bỏ file `internal/{subsystem}/{group}/{component}/service/service_test.go`.
5. **Cập nhật tiến độ**: Đánh dấu `[x] Task 7` trong `{component}_tasks.md` và hoàn tất pipeline.
