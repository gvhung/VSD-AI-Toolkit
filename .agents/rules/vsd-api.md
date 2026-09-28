# VSD Go Backend API Development Rules

Tập luật này áp dụng cho toàn bộ các tác vụ phát triển, tạo mới, chỉnh sửa và kiểm thử Go Backend API trong dự án **VSD-AI-Toolkit**.

## 1. Ràng Buộc Kiến Trúc Tầng (Layered Architecture)
- Mọi thành phần API bắt buộc tuân theo cấu trúc:
  `internal/{subsystem}/{group}/{component}/` (model, query, service, handler, router).
- Tài liệu kỹ thuật bắt buộc lưu tại:
  `docs/{subsystem}/` và `docs/{subsystem}/{group}/`.

## 2. Ràng Buộc An Ninh Mạng (Cybersecurity Gates)
- **RLS**: Phải gọi `CALL apply_rls_for_tables(...)` khi AutoMigrate và thực thi `SET LOCAL app.current_tenant = ?` trong transaction.
- **SQLi**: Tuyệt đối cấm nối chuỗi `+` hoặc `fmt.Sprintf` trong các câu lệnh GORM. 100% sử dụng tham số hóa `?`.
- **IDOR**: Bắt buộc ghi đè `input.TenantID = tenantID` tại Handler; bắt buộc xóa `tenant_id` trong update map tại Service.
- **Secrets**: Không hardcode secret hoặc mật khẩu; đọc từ biến môi trường.
- **Swagger**: Đầy đủ 8 Godoc annotations cho cả 6 endpoints RESTful.

## 3. Quy Trình Ephemeral Test-First (TDD)
- Phải viết `service_test.go` trước (RED state), sau đó hoàn thiện `service.go` (GREEN state).
- File `service_test.go` là tài sản tạm thời (Ephemeral) và **BẮT BUỘC PHẢI BỊ XÓA** khi hoàn thành nghiệm thu (DoD).
