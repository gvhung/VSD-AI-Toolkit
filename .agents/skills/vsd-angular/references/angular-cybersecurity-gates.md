# Anthropic Cybersecurity Gate: 6 Cổng An Ninh Frontend (VSD Solution)

Tài liệu này xác định chi tiết tiêu chí kiểm tra, dấu hiệu vi phạm và cách khắc phục cho 6 cổng an ninh giao diện Angular Client theo [ANGULAR-ARCHITECTURE.md](./angular-architecture.md).

---

## Cổng 1: Kiểm Soát Phân Quyền MenuAuth RBAC

- **Mục tiêu**: Đảm bảo người dùng chỉ nhìn thấy và thực hiện các hành động tương ứng với quyền hạn được cấp. Ngăn chặn người dùng truy cập trái phép màn hình qua URL.
- **Ràng buộc bắt buộc**:
  1. Trong template bảng (`{subsystem}-{component}.component.html`):
     - Nút Thêm mới: Bắt buộc bọc `*ngIf="permissionService.hasPermission('ADD')"`.
     - Nút Chỉnh sửa: Bắt buộc bọc `*ngIf="permissionService.hasPermission('EDIT')"`.
     - Nút Xóa: Bắt buộc bọc `*ngIf="permissionService.hasPermission('DELETE')"`.
  2. Trong router phân hệ (`{subsystem}-routing.module.ts`):
     - Mọi route cấp component bắt buộc phải có guard:
       ```typescript
       canActivate: [NavigationPermissionGuard]
       ```
- **Dấu hiệu vi phạm**:
  - Nút bấm hành động không được bọc directive `*ngIf="permissionService.hasPermission(...)"`.
  - Khai báo route mà thiếu `canActivate: [NavigationPermissionGuard]`.

---

## Cổng 2: Phòng Chống Tấn Công XSS (Cross-Site Scripting)

- **Mục tiêu**: Triệt tiêu nguy cơ tiêm mã độc JavaScript vào trình duyệt của người dùng qua dữ liệu hiển thị.
- **Ràng buộc bắt buộc**:
  1. Sử dụng 100% cơ chế template binding an toàn của Angular (`{{}}`, `[property]`).
  2. Tuyệt đối **CẤM** sử dụng `DomSanitizer.bypassSecurityTrustHtml`, `bypassSecurityTrustScript`, `innerHTML` chứa dữ liệu người dùng mà không qua kiểm duyệt an ninh.
- **Dấu hiệu vi phạm**:
  - Xuất hiện `bypassSecurityTrustHtml` trong controller hoặc component.
  - Sử dụng `[innerHTML]` để render trực tiếp chuỗi từ API mà không có sanitizer.

---

## Cổng 3: Chống Rò Rỉ Bí Mật (No Secrets)

- **Mục tiêu**: Đảm bảo không có thông tin bí mật, khóa xác thực hay mật khẩu bị lộ trong bundle mã nguồn Frontend.
- **Ràng buộc bắt buộc**:
  1. Tuyệt đối **CẤM** hardcode API Key, Client Secret, JWT Secret, Token hoặc mật khẩu trong các file TypeScript (`.ts`).
  2. Mọi URL API phải trích xuất từ biến cấu hình tập trung:
     ```typescript
     private readonly baseUrl = `${BackEndConfig.API_URL}api/{subsystem}/{group}/{component}`;
     ```
- **Dấu hiệu vi phạm**:
  - Khai báo literal string chứa chuỗi bí mật, secret, hoặc mật khẩu.
  - Hardcode trực tiếp địa chỉ domain (vd: `http://localhost:8080` hoặc `https://api.vsd.vn`) thay vì dùng `BackEndConfig.API_URL`.

---

## Cổng 4: Chuẩn Hóa & Làm Sạch Dữ Liệu Form (Data Sanitization)

- **Mục tiêu**: Làm sạch dữ liệu và ngăn chặn injection, ký tự lạ ngay tại tầng nhập liệu trước khi gửi lên server.
- **Ràng buộc bắt buộc**:
  1. Trong `modal-{component}.component.ts`: Bắt buộc gọi tiện ích:
     ```typescript
     enforceTextTransform(this.form, configFields, this._destroyRef);
     ```
  2. Trường mã (`code`) bắt buộc cấu hình:
     ```typescript
     { field: 'code', required: true, uppercase: true, noAccent: true, noSpecialChar: true, maxLength: 50 }
     ```
  3. Trong file Entity `type.ts`: Bắt buộc sử dụng `@FormField()` với đầy đủ metadata tương ứng.
- **Dấu hiệu vi phạm**:
  - Không gọi `enforceTextTransform` trong component modal.
  - Trường mã thiếu các ràng buộc `uppercase`, `noAccent`, `noSpecialChar`.

---

## Cổng 5: Tiêu Chuẩn An Ninh OWASP Top 10 Cho Web Client

- **Mục tiêu**: Tuân thủ các nguyên tắc bảo mật ứng dụng web của OWASP:
  1. **A01: Broken Access Control**: Phối hợp giữa MenuAuth RBAC ở giao diện và Route Guard, ngăn chặn truy cập trái phép.
  2. **A02: Cryptographic Failures**: Không lưu trữ token không mã hóa hay dữ liệu nhạy cảm trong localStorage mà không có cơ chế bảo vệ.
  3. **A03: Injection**: Làm sạch dữ liệu form và dùng template binding để triệt tiêu injection.
  4. **A08: Software and Data Integrity Failures**: Kiểm tra lỗi form và đồng bộ validation từ server qua `FormErrorUtil.applyServerErrors`.
- **Dấu hiệu vi phạm**:
  - Bỏ qua kiểm tra quyền truy cập ở phía client.
  - Không xử lý phản hồi lỗi an ninh từ server.

---

## Cổng 6: Dọn Dẹp Kiểm Thử Tự Sinh (DoD Cleanup)

- **Mục tiêu**: Đảm bảo mã nguồn bàn giao sạch sẽ, không để lại file test tạm thời trong sản phẩm.
- **Ràng buộc bắt buộc**:
  - File `{component}_service_test.spec.ts` sinh ra trong chu trình TDD mang header `// EPHEMERAL_TEST_FILE: True`.
  - Ngay sau khi Task 7 hoàn tất và đạt toàn bộ kiểm tra an ninh, **BẮT BUỘC XÓA BỎ** file test tạm thời này.
- **Dấu hiệu vi phạm**:
  - File `{component}_service_test.spec.ts` vẫn còn tồn tại trong thư mục component sau khi hoàn tất pipeline.
