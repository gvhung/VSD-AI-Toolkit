---
name: vsd-api
description: >-
  Công cụ Agent chuyên trách phát triển Go Backend API tại VSD Solution.
  Thực thi Spec-Driven Development (SDD), Ephemeral Test-First (TDD), Vòng lặp tự phục hồi (Self-Healing Loop),
  Kiểm định 7 cổng an ninh Anthropic Cybersecurity Gate và Quy trình tự động tuần tự Continuous Auto-Advance Pipeline.
  Sử dụng khi tạo mới, dựng khung (scaffold), cập nhật, kiểm thử hoặc kiểm định (audit) bất kỳ component Go API nào của VSD.
---

# vsd-api Agent Tool

Công cụ Agent chuyên trách phát triển Go Backend API tại VSD Solution, tuân thủ nghiêm ngặt [api-architecture.md](./references/api-architecture.md). Toàn bộ mẫu mã nguồn và script kiểm tra an ninh được đóng gói khép kín (Self-Contained) ngay bên trong thư mục của Skill (`resources/templates/` và `scripts/`).

---

## 1. 5 Trụ Cột Kỹ Thuật

Khi được kích hoạt, Agent tự động triển khai quy trình dựa trên 5 trụ cột:
1. **Spec-Driven Development (SDD)**: Khởi tạo toàn bộ tài liệu tại `docs/` trước khi viết code.
2. **Ephemeral Test-First**: Viết test biên dữ liệu (`service_test.go`) đạt trạng thái RED -> Triển khai Service đạt GREEN -> Tự động xóa file test khi hoàn thành nghiệm thu (DoD).
3. **Self-Healing Loop**: Tự động bắt lỗi biên dịch hoặc test failure và lặp lại sửa lỗi (tối đa 3 lần) trước khi báo cáo.
4. **Anthropic Cybersecurity Gate**: Kiểm tra nghiêm ngặt 7 chốt an ninh: RLS, chống SQLi, chống IDOR, Secrets, RBAC, Swagger Godoc, và OWASP API Security Top 10. Xem chi tiết tại [vsd-cybersecurity-gates.md](./references/vsd-cybersecurity-gates.md).
5. **Continuous Auto-Advance Pipeline**: Thực thi tuần tự 7 micro-tasks, tự động cập nhật checklist `[x]` trong `{component}_tasks.md`. Xem chi tiết tại [api-micro-tasks.md](./references/api-micro-tasks.md).

---

## 2. Quy Trình Thực Thi Tự Động (Continuous Auto-Advance)

Khi nhận được yêu cầu phát triển một component từ người dùng, hãy thực hiện theo đúng các bước sau:

### Bước 1: Trích xuất thông số thành phần
Xác định 7 tham số cốt lõi:
- `SUBSYSTEM`: Tên phân hệ (vd: `tdtt`, `hrm`, `crm`, `core`).
- `GROUP`: Tên nhóm chức năng (vd: `danhmuc`, `nghiepvu`, `baocao`).
- `COMPONENT`: Tên thành phần viết thường (vd: `chucvu`, `donvi`).
- `ComponentPascal`: Tên dạng PascalCase (vd: `ChucVu`, `DonVi`).
- `ComponentCamel`: Tên dạng camelCase (vd: `chucVu`, `donVi`).
- `ComponentVN`: Tên tiếng Việt có dấu (vd: `Chức vụ`, `Đơn vị`).
- `TABLE_NAME`: Tên bảng CSDL vật lý (vd: `tdtt_danhmuc_chucvu`).
- `MODULE_ROOT`: Đường dẫn module Go (đọc từ `go.mod` hoặc mặc định `vsd-core`).

### Bước 2: Thực thi Task 1 (Spec-Driven Development)
- Đọc template từ `resources/templates/docs/`.
- Sinh `docs/{subsystem}/PLAN-{subsystem}-{group}.md`.
- Sinh `docs/{subsystem}/{group}/{component}_specs.md`.
- Sinh `docs/{subsystem}/{group}/{component}_tasks.md`.
- Đánh dấu `[x] Task 1` trong `{component}_tasks.md`.

### Bước 3: Thực thi Task 2 (Migration DDL & RLS)
- Sinh `docs/{subsystem}/{group}/sql/{subsystem}_{group}_{component}.sql`.
- Đảm bảo có `UUID PRIMARY KEY`, `tenant_id UUID`, `removed_at`, và `CALL apply_rls_for_tables(...)`.
- Đánh dấu `[x] Task 2` trong `{component}_tasks.md`.

### Bước 4: Thực thi Task 3 (Model Layer)
- Sinh `internal/{subsystem}/{group}/{component}/model/model.go` (từ `resources/templates/model/`).
- Kiểm tra struct có trường audit, `TableName()`, `FieldError`, `ValidationError`.
- Đánh dấu `[x] Task 3` trong `{component}_tasks.md`.

### Bước 5: Thực thi Task 4 (Query Layer)
- Sinh `internal/{subsystem}/{group}/{component}/query/query.go` (từ `resources/templates/query/`).
- Kiểm tra có đủ 8 hàm, có kiểm tra phòng thủ `if tx == nil`, không nối chuỗi SQL.
- Đánh dấu `[x] Task 4` trong `{component}_tasks.md`.

### Bước 6: Thực thi Task 5 (Ephemeral Test-First & Service)
- Sinh `internal/{subsystem}/{group}/{component}/service/service_test.go` (RED-state, từ `resources/templates/service/service_test.go.template`).
- Chạy `go test ./...` kiểm tra trạng thái RED.
- Sinh `internal/{subsystem}/{group}/{component}/service/interface.go`.
- Sinh `internal/{subsystem}/{group}/{component}/service/service.go`.
- Chạy lại test để đạt GREEN-state. Nếu phát sinh lỗi, kích hoạt **Self-Healing Loop** để tự động sửa mã.
- Đánh dấu `[x] Task 5` trong `{component}_tasks.md`.

### Bước 7: Thực thi Task 6 (Handler Layer)
- Sinh `internal/{subsystem}/{group}/{component}/handler/handler.go` (từ `resources/templates/handler/`).
- Kiểm tra `executeWithTenant`, `SET LOCAL app.current_tenant = ?`, ghi đè `input.TenantID`, bọc lỗi Data Masking, đủ 6 Godoc tags.
- Đánh dấu `[x] Task 6` trong `{component}_tasks.md`.

### Bước 8: Thực thi Task 7 (Router & Cybersecurity Gate Audit)
- Sinh `internal/{subsystem}/{group}/{component}/router{{ComponentPascal}}.go` (từ `resources/templates/router.go.template`).
- Cập nhật router group và subsystem nếu cần.
- Chạy script kiểm tra an ninh tự động được đóng gói kèm theo skill:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .agents/skills/vsd-api/scripts/audit-api-cybersecurity-gate.ps1 -ComponentPath "internal/{subsystem}/{group}/{component}" -TableName "{TABLE_NAME}"
  ```
- Nếu có cổng an ninh nào bị FAIL, tự động sửa lỗi ngay lập tức.
- Khi đạt các cổng an ninh PASS: Thực hiện **Definition of Done (DoD)**:
  - **XÓA BỎ** file `internal/{subsystem}/{group}/{component}/service/service_test.go`.
- Đánh dấu `[x] Task 7` trong `{component}_tasks.md`.

### Bước 9: Báo cáo kết quả
- Báo cáo danh sách các tệp tài liệu và mã nguồn đã tạo bằng markdown link có định dạng `file:///`.
- Báo cáo bảng kết quả kiểm tra 7 cổng an ninh.
- Xác nhận file test tạm thời đã được dọn dẹp sạch sẽ.
