# VSD-AI-Toolkit: Hướng Dẫn Điều Phối Hệ Thống Agent

Dự án **VSD-AI-Toolkit** vận hành hệ thống đa tác tử (Multi-Agent Architecture) nhằm chuyên biệt hóa nhiệm vụ giữa Backend Go API và Frontend Angular Client:
- **[Agent vsd-api](#agent-vsd-api)**: Chuyên trách Backend Go RESTful API (7 Micro-tasks, 7 Cổng an ninh).
- **[Agent vsd-angular](#agent-vsd-angular)**: Chuyên trách Frontend Angular Client (7 Micro-tasks, 6 Cổng an ninh).

---

## Agent vsd-api

Khi tạo mới, cập nhật hoặc kiểm thử API, AI Assistant đóng vai trò là Agent **`vsd-api`** và tuân thủ nghiêm ngặt 5 Trụ Cột Kỹ Thuật:

### 1. 5 Trụ Cột Kỹ Thuật Cốt Lõi
1. **Spec-Driven Development (SDD)**: Không viết code (`internal/`) trước khi hoàn tất tài liệu đặc tả (`docs/{subsystem}/PLAN-*.md`, `docs/{subsystem}/{group}/{component}_specs.md`, `{component}_tasks.md`, `sql/{subsystem}_{group}_{component}.sql`). Mẫu chuẩn tại [templates/docs](./skills/vsd-api/resources/templates/docs/).
2. **Ephemeral Test-First (TDD Red-Green-DoD)**:
   - Tạo file test tạm `internal/{subsystem}/{group}/{component}/service/service_test.go` từ [service_test.go.template](./skills/vsd-api/resources/templates/service/service_test.go.template).
   - **RED**: Chạy `go test` kiểm thử mã rỗng, tên rỗng, trùng lặp, phòng thủ `tx == nil`.
   - **GREEN**: Hiện thực `service.go` pass 100% test cases.
   - **DoD Cleanup**: Bắt buộc **XÓA BỎ** `service_test.go` sau khi hoàn thành Task 7 và vượt qua Cổng An Ninh.
3. **Self-Healing Loop**: Tự động phân tích `stderr`, sửa lỗi lặp lại (tối đa 3 lần) cho compile, nil check `tx *gorm.DB`, con trỏ, SQL/GORM tags.
4. **Anthropic Cybersecurity Gate (7 Cổng Tuyệt Đối)** ([chi tiết](./skills/vsd-api/references/api-architecture.md)):
   - **RLS**: SQL & Router có `CALL apply_rls_for_tables(...)`; Handler chạy transaction `SET LOCAL app.current_tenant = ?`.
   - **SQLi**: Cấm nối chuỗi `+` hoặc `fmt.Sprintf` trong GORM; bắt buộc 100% dùng tham số hóa `?`.
   - **IDOR**: Handler ghi đè `input.TenantID = tenantID` từ JWT; Service xóa `tenant_id`, `id`, `created_at` khỏi map update. Cấm nhận `tenant_id` từ client.
   - **Secrets & JWT**: Cấm hardcode bí mật, mật khẩu, khóa ký. Đọc từ biến môi trường (`os.LookupEnv`) hoặc Vault.
   - **MenuAuth RBAC**: Tích hợp middleware kiểm tra quyền hạn menu và action.
   - **OpenAPI Godoc**: Đủ 8 tags Swagger chuẩn cho cả 6 endpoints (`GetAll`, `Paginate`, `GetByID`, `Create`, `Update`, `Delete`).
   - **OWASP Top 10**: Cưỡng chế phòng chống BOLA, Broken Auth, Mass Assignment, Injection.
5. **Continuous Auto-Advance (7 Micro-Tasks Tuần Tự)**:
   - **Task 1 (Docs & Specs)**: Sinh `PLAN-*.md`, `{component}_specs.md`, `{component}_tasks.md`.
   - **Task 2 (SQL & RLS)**: Sinh migration SQL với UUID PK, `tenant_id`, RLS procedure.
   - **Task 3 (Model)**: Sinh `model/model.go` (Entity, soft delete `removed_at`, `ValidationError`).
   - **Task 4 (Query)**: Sinh `query/query.go` (8 hàm query, phòng thủ `tx == nil`, tham số hóa `?`).
   - **Task 5 (Service TDD)**: Sinh `service_test.go` (RED) -> Sinh `interface.go` & `service.go` (GREEN).
   - **Task 6 (Handler)**: Sinh `handler/handler.go` (RLS transaction, IDOR override, data masking, Swagger Godoc).
   - **Task 7 (Router & Gate)**: Sinh `router{{ComponentPascal}}.go`, mount 6 endpoints, quét 7 cổng an ninh, xóa `service_test.go`.

### 2. Kích Hoạt & Trích Xuất Tham Số
Trích xuất: `SUBSYSTEM`, `GROUP`, `COMPONENT`, `EntityName`, `ComponentPascal`, `ComponentCamel`, `ComponentVN`, `TABLE_NAME`, `MODULE_ROOT` -> Tự động chạy tuần tự qua 7 micro-tasks không ngắt quãng.

---

## Agent vsd-angular

Khi phát triển giao diện Client, AI Assistant đóng vai trò là Agent **`vsd-angular`** và tuân thủ nghiêm ngặt 5 Trụ Cột Kỹ Thuật Frontend:

### 1. 5 Trụ Cột Kỹ Thuật Cốt Lõi Frontend
1. **Spec-Driven Development (SDD)**: Khởi tạo đầy đủ `docs/{subsystem}/{group}/{component}_ui_specs.md` và `{component}_ui_tasks.md` trước khi code `src/app/modules/`.
2. **Ephemeral Test-First (Cô Lập Đa Component)**:
   - File test tạm: `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`.
   - **RED**: Giả lập `HttpTestingController`, kiểm tra gọi GET `/paginate` và phát tín hiệu Subject `refresh*s$`.
   - **GREEN**: Hiện thực `{group}.service.ts` pass 100% test cases.
   - **DoD Cleanup**: Chỉ xóa file `{component}_service_test.spec.ts` của chính component sau khi hoàn tất Task 7.
3. **Self-Healing Loop**: Tự động bắt và khắc phục lỗi TypeScript, HTML template, thiếu import standalone, lỗi decorator `@FormField` (tối đa 3 lần).
4. **Anthropic Cybersecurity Gate (6 Cổng Frontend)** ([chi tiết](./skills/vsd-angular/references/angular-architecture.md)):
   - **MenuAuth RBAC**: Nút Thêm/Sửa/Xóa bọc `*ngIf="permissionService.hasPermission('ADD' | 'EDIT' | 'DELETE')"`; route có `canActivate: [NavigationPermissionGuard]`.
   - **Chống XSS**: Sử dụng Angular template binding an toàn. Cấm dùng `bypassSecurityTrustHtml` chưa qua kiểm duyệt.
   - **No Secrets**: Cấm hardcode API Key/Token; Base URL gọi qua `BackEndConfig.API_URL`.
   - **Làm Sạch Form**: Kích hoạt `enforceTextTransform(this.form, configFields, this._destroyRef)` (`uppercase`, `noAccent`, `noSpecialChar`).
   - **OWASP Top 10**: Phòng chống Broken Access Control, rò rỉ dữ liệu nhạy cảm, lỗi toàn vẹn form.
   - **DoD Cleanup**: Tự động xóa file test tạm `{component}_service_test.spec.ts`.
5. **Continuous Auto-Advance (7 Micro-Tasks Frontend)**:
   - **Task 1 (UI Docs)**: Sinh `{component}_ui_specs.md`, `{component}_ui_tasks.md`.
   - **Task 2 (Entity & Form Decorator)**: Cập nhật `{subsystem}.type.ts` (`BaseEntity`, `@FormField`).
   - **Task 3 (Ephemeral Test)**: Sinh `{component}_service_test.spec.ts` (RED).
   - **Task 4 (Service & Refresh Bus)**: Cập nhật `{group}.service.ts` (6 RESTful methods, bóc tách `.data`, đồng bộ Subject `_data$`).
   - **Task 5 (Master Table View)**: Sinh `{subsystem}-{component}.component.ts/html/scss` (MatTable, debounced search, confirmation dialog, RBAC buttons).
   - **Task 6 (Modal Form Dialog)**: Sinh `modal-{component}.component.ts/html/scss` (Reactive Form, `buildFormFromClass`, `enforceTextTransform`, server error handling).
   - **Task 7 (Routing & Gate Audit)**: Cập nhật `{subsystem}-routing.module.ts`, gắn Guard, audit 6 cổng an ninh, xóa `{component}_service_test.spec.ts`.

### 2. Kích Hoạt & Trích Xuất Tham Số
Trích xuất: `subsystem`, `group`, `component`, `SubsystemPascal`, `GroupPascal`, `ComponentPascal`, `EntityName`, `ComponentVN`, `TableSelector`, `ModalSelector` -> Tự động chạy tuần tự qua 7 micro-tasks Frontend.

---

## Quy Chuẩn PowerShell & Dữ Liệu UTF-8 (Bắt Buộc)

Mọi AI Assistant khi thực thi shell/script trên Windows PowerShell bắt buộc tuân thủ:
1. **Không dùng tiện ích Unix không khả dụng (`awk`, `sed`, `grep`, `cut`)**: Thay bằng PowerShell thuần (`ForEach-Object`, `Select-String`, `-split`) hoặc Python một dòng: `python -X utf8 -c "..."`.
2. **Luôn chỉ định `-Encoding UTF8`**: Tránh lỗi mojibake tiếng Việt. Dùng `Get-Content -Encoding UTF8`, `Set-Content -Encoding UTF8`, hoặc cấu hình đầu phiên:
   `$OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8`.
3. **Cú pháp gán biến trong PowerShell**: Phép gán `=` là Statement, không phải Expression.
   - Cấm gán trong điều kiện: tách `$x = ...; if ($x) { ... }`.
   - Cấm gán nhận từ pipeline: dùng `$var = ... | ...`.
   - Trong `powershell -Command`: Dùng nháy đơn `'...'` hoặc escape `` `$var `` để shell cha không expand rỗng.
4. **Chống truncate dữ liệu console**: Khi xuất bảng dữ liệu terminal, bắt buộc mở rộng độ rộng:
   `$FormatEnumerationLimit = -1; ... | Format-Table -Wrap | Out-String -Width 4096` hoặc dùng `Format-List *`. Trong Markdown, không để một ô bảng vượt quá 100 ký tự liền mạch.
