# Anthropic Cybersecurity Gate: Quy Chuẩn 6 Cổng An Ninh VSD

Tài liệu này xác định chi tiết tiêu chí kiểm tra, quy tắc vi phạm và cách khắc phục cho cổng an ninh theo [API-ARCHITECTURE.md](./api-architecture.md).

---

## Cổng 1: Row-Level Security (RLS) & Phân Lập Đa Khách Thuê

- **Mục tiêu**: Đảm bảo dữ liệu của khách thuê này không bao giờ bị truy cập hoặc rò rỉ sang khách thuê khác ở mức cơ sở dữ liệu PostgreSQL.
- **Ràng buộc bắt buộc**:
  1. Trong file DDL `.sql`: Bắt buộc có cột `tenant_id UUID NOT NULL` và gọi thủ tục:
     ```sql
     CALL apply_rls_for_tables(ARRAY['<table_name>']);
     ```
  2. Trong file `router.go`: Ngay sau `AutoMigrate`, bắt buộc gọi thực thi thủ tục RLS trên `gormDB`:
     ```go
     if rlsErr := gormDB.Exec("CALL apply_rls_for_tables(ARRAY['<table_name>'])").Error; rlsErr != nil {
         log.Printf("⚠️ Áp dụng RLS thất bại: %v\n", rlsErr)
     }
     ```
  3. Trong file `handler.go`: Mọi thao tác truy vấn CSDL phải nằm trong `executeWithTenant` và thiết lập biến phiên PostgreSQL có tham số hóa:
     ```go
     tx.Exec("SET LOCAL app.current_tenant = ?", tenantID)
     ```
- **Dấu hiệu vi phạm**:
  - Dùng kiểu `VARCHAR(50)` cho `tenant_id` thay vì `UUID`.
  - Thiếu lệnh `CALL apply_rls_for_tables`.
  - Thực hiện câu lệnh SQL mà không thiết lập `SET LOCAL app.current_tenant`.

---

## Cổng 2: Phòng Chống Tấn Công SQL Injection (SQLi)

- **Mục tiêu**: Triệt tiêu hoàn toàn nguy cơ khai thác SQL Injection.
- **Ràng buộc bắt buộc**:
  1. Trong `query/query.go` và toàn bộ mã nguồn: Tuyệt đối **CẤM** sử dụng toán tử nối chuỗi `+` hoặc hàm định dạng `fmt.Sprintf` để ghép các biến vào câu truy vấn SQL hoặc mệnh đề `Where`, `Order`, `Exec`.
  2. Bắt buộc 100% sử dụng kỹ thuật tham số hóa với ký tự hỏi chấm `?`:
     ```go
     // HỢP LỆ:
     query.Where("code ILIKE ? OR name ILIKE ?", key, key)
     query.Where("id = ?", id)
     
     // VI PHẠM (CẤM):
     query.Where("code = '" + code + "'")
     query.Where(fmt.Sprintf("id = '%s'", id))
     ```
- **Dấu hiệu vi phạm**: Xuất hiện phép cộng chuỗi hoặc `fmt.Sprintf` bên trong các tham số của GORM.

---

## Cổng 3: Phòng Chống Tấn Công IDOR (Insecure Direct Object Reference)

- **Mục tiêu**: Ngăn chặn người dùng thay đổi `tenant_id` hoặc đánh cắp/chỉnh sửa bản ghi của tenant khác bằng cách gửi tham số tùy ý trong body/params.
- **Ràng buộc bắt buộc**:
  1. Trong `handler/handler.go`: Định danh khách thuê luôn được trích xuất từ JWT token đã xác thực (`c.GetString("tenant_id")`).
  2. Trước khi gọi service tạo mới hoặc cập nhật, Server luôn tự động ghi đè:
     ```go
     tenantID := h.getTenantID(c)
     input.TenantID = tenantID
     ```
  3. Trong `service/service.go`: Khi cập nhật (`Update`), trước khi gửi qua `q.Update`, bắt buộc loại bỏ các trường nhạy cảm ra khỏi map:
     ```go
     delete(updateMap, "id")
     delete(updateMap, "created_at")
     delete(updateMap, "tenant_id") // Ngăn chặn can thiệp tenant_id
     ```
- **Dấu hiệu vi phạm**: Tiếp nhận `tenant_id` từ request body mà không ghi đè, hoặc cho phép cập nhật `tenant_id` trong câu lệnh `UPDATE`.

---

## Cổng 4: Bảo Vệ Secrets & JWT

- **Mục tiêu**: Không để lộ các thông tin xác thực nhạy cảm, khóa bí mật hoặc thông tin kết nối CSDL.
- **Ràng buộc bắt buộc**:
  1. Tuyệt đối **CẤM** hardcode chuỗi bí mật, token, private key hoặc mật khẩu trong mã nguồn Go.
  2. Sử dụng biến môi trường qua `os.LookupEnv` hoặc dịch vụ quản lý bí mật (Vault):
     ```go
     secret, ok := os.LookupEnv("JWT_SECRET")
     ```
- **Dấu hiệu vi phạm**: Khai báo chuỗi bí mật dạng const hoặc literal string trong code.

---

## Cổng 5: Kiểm Soát Phân Quyền MenuAuth RBAC

- **Mục tiêu**: Đảm bảo người dùng chỉ được phép truy cập vào các tính năng và dữ liệu tương ứng với quyền hạn được cấp.
- **Ràng buộc bắt buộc**:
  1. Trong `routerSubsystem.go` hoặc router group: Bắt buộc cấu hình middleware kiểm tra tenant và menu auth:
     ```go
     api.Use(tenantMiddleware)
     // api.Use(middleware.MenuAuthMiddleware(db))
     ```
  2. Trong `_specs.md`: Liệt kê rõ các mã quyền tương ứng với từng hành động (`VIEW`, `CREATE`, `UPDATE`, `DELETE`).

---

## Cổng 6: Chuẩn Hóa OpenAPI & Swagger Godoc

- **Mục tiêu**: Cung cấp tài liệu API tự động, đồng bộ và đầy đủ cho đội ngũ frontend và tích hợp hệ thống.
- **Ràng buộc bắt buộc**:
  1. Cả 6 endpoints chuẩn RESTful (`GetAll`, `Paginate`, `GetByID`, `Create`, `Update`, `Delete`) trong `handler/handler.go` bắt buộc phải có đầy đủ các thẻ Swagger Godoc:
     - `@Summary`: Tóm tắt chức năng
     - `@Description`: Mô tả chi tiết
     - `@Tags`: Tên thực thể
     - `@Accept` / `@Produce`: Kiểu dữ liệu (json)
     - `@Param`: Tham số truyền vào (nếu có)
     - `@Success`: Mã thành công (200, 201)
     - `@Failure`: Mã lỗi (400, 404, 500)
     - `@Router`: Đường dẫn và phương thức HTTP
  2. Che giấu lỗi hệ thống (Data Masking): Trả về JSON lỗi thân thiện (`success: false, message: "..."`), cấm trả raw SQL stack trace.

---

## Cổng 7: Tiêu Chuẩn An Ninh OWASP API Security Top 10

- **Mục tiêu**: Đảm bảo toàn bộ kiến trúc và triển khai API tuân thủ các nguyên tắc phòng thủ tốt nhất của OWASP API Security.
- **Ràng buộc bắt buộc**:
  1. **API1: BOLA (Broken Object Level Authorization)**: Phải phân lập triệt để ở tầng CSDL qua RLS và cưỡng chế kiểm tra quyền truy cập bản ghi.
  2. **API2: Broken Authentication**: Token JWT phải hợp lệ, không hardcode khóa ký hoặc credentials.
  3. **API3: Broken Object Property Level Authorization (Mass Assignment)**: Tuyệt đối không cho phép client cập nhật trực tiếp các trường nhạy cảm (`tenant_id`, `id`, `created_at`, quyền hạn). Bắt buộc loại bỏ khỏi update map.
  4. **API4: Unrestricted Resource Consumption**: Endpoint `Paginate` bắt buộc có giới hạn `pageSize` mặc định (default 20, max limit) và phân trang rõ ràng.
  5. **API8: Security Misconfiguration**: Luôn cấu hình CORS, headers an toàn và ẩn toàn bộ thông tin chi tiết lỗi hạ tầng/CSDL (Data Masking).
