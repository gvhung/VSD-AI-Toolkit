# VSD-AI-Toolkit 🚀

**VSD-AI-Toolkit** là bộ công cụ tích hợp và điều phối Hệ thống Đa Tác tử (Multi-Agent Architecture) dành cho các AI Coding Assistant (Antigravity IDE, Cursor, Windsurf, Copilot), được tối ưu hóa riêng cho chuẩn kiến trúc phần mềm tại **VSD Solution**.

Toolkit chuyên biệt hóa nhiệm vụ phát triển ứng dụng web giữa **Backend Go API** (`vsd-api`) và **Frontend Angular Client** (`vsd-angular`), áp dụng phương pháp **Spec-Driven Development (SDD)**, **Ephemeral Test-First (TDD)**, **Self-Healing Loop**, và **Anthropic Cybersecurity Gate**.

---

## 🌟 Tính Năng Nổi Bật

- 🤖 **Đa Tác Tử Chuyên Biệt (Multi-Agent Architecture)**: Tự động nhận diện ngữ cảnh và kích hoạt quy trình chuẩn hóa cho Backend Go API hoặc Frontend Angular Client.
- 📐 **Spec-Driven Development (SDD)**: Luôn khởi tạo đầy đủ tài liệu kiến trúc, đặc tả API/UI, danh sách công việc và SQL migration trước khi triển khai mã nguồn.
- 🧪 **Ephemeral Test-First (TDD Red-Green-DoD)**: Tự động sinh file test tạm thời để kiểm định nghiêm ngặt (RED), triển khai mã nguồn vượt qua test (GREEN), và dọn dẹp dứt điểm file test tạm sau khi đạt Definition of Done (DoD).
- 🛡️ **Anthropic Cybersecurity Gate**: Tự động kiểm tra và bảo mật dứt điểm (RLS, SQLi, IDOR, MenuAuth RBAC, No Secrets, XSS, Form TextTransform, OWASP Top 10).
- 🔄 **Self-Healing Loop**: Tự động phân tích thông tin biên dịch/chạy test, phát hiện lỗi và tự sửa chữa lặp lại (tối đa 3 lần).
- 🔗 **Cài đặt linh hoạt qua NTFS Directory Junction**: Dễ dàng liên kết bộ kỹ năng (Skills & Rules) tới Antigravity IDE toàn cục hoặc nhúng trực tiếp vào từng workspace dự án.

---

## 🤖 Các Agent Trong Hệ Thống

### 1. Agent `vsd-api` (Go RESTful API)
Chuyên trách phát triển và kiểm định Backend Go RESTful API qua 7 Micro-Tasks tuần tự:
1. **Task 1 (Docs & Specs)**: Sinh `PLAN-*.md`, `{component}_specs.md`, `{component}_tasks.md`.
2. **Task 2 (SQL & RLS)**: Sinh migration SQL với UUID PK, `tenant_id`, RLS procedure.
3. **Task 3 (Model)**: Sinh `model/model.go` (Entity, soft delete `removed_at`, `ValidationError`).
4. **Task 4 (Query)**: Sinh `query/query.go` (8 hàm query chuẩn, phòng thủ `tx == nil`, tham số hóa `?`).
5. **Task 5 (Service TDD)**: Sinh `service_test.go` (RED) ➔ Triển khai `interface.go` & `service.go` (GREEN).
6. **Task 6 (Handler)**: Sinh `handler/handler.go` (RLS transaction, IDOR override, data masking, Swagger Godoc).
7. **Task 7 (Router & Gate Audit)**: Sinh `router{{ComponentPascal}}.go`, mount 6 endpoints, quét 7 Cổng An Ninh, xóa bỏ `service_test.go`.

### 2. Agent `vsd-angular` (Angular Client)
Chuyên trách phát triển và kiểm định Frontend Angular Client qua 7 Micro-Tasks tuần tự:
1. **Task 1 (UI Docs)**: Sinh `{component}_ui_specs.md`, `{component}_ui_tasks.md`.
2. **Task 2 (Entity & Form Decorator)**: Cập nhật `{subsystem}.type.ts` (`BaseEntity`, `@FormField`).
3. **Task 3 (Ephemeral Test)**: Sinh `{component}_service_test.spec.ts` (RED).
4. **Task 4 (Service & Refresh Bus)**: Cập nhật `{group}.service.ts` (6 RESTful methods, đồng bộ Subject `_data$`).
5. **Task 5 (Master Table View)**: Sinh `{subsystem}-{component}.component.ts/html/scss` (MatTable, debounced search, dialog, RBAC buttons).
6. **Task 6 (Modal Form Dialog)**: Sinh `modal-{component}.component.ts/html/scss` (Reactive Form, `buildFormFromClass`, `enforceTextTransform`, server error handling).
7. **Task 7 (Routing & Gate Audit)**: Cập nhật `{subsystem}-routing.module.ts`, gắn Guard, quét 6 Cổng An Ninh Frontend, xóa bỏ `{component}_service_test.spec.ts`.

---

## 📁 Cấu Trúc Thư Mục

```text
VSD-AI-Toolkit/
├── .agents/
│   ├── AGENTS.md                  # Hướng dẫn chi tiết điều phối hệ thống Agent
│   ├── rules/                     # Các quy tắc kỹ thuật chung
│   └── skills/                    # Bộ kỹ năng chi tiết cho tác tử
│       ├── vsd-api/               # Tài nguyên & template cho Go Backend API
│       └── vsd-angular/           # Tài nguyên & template cho Angular Frontend
├── .cursorrules                   # Quy tắc áp dụng cho Cursor / Windsurf / Copilot
├── install-junction.ps1           # Script PowerShell thiết lập liên kết Junction (Windows)
├── install-junction.bat           # File thực thi nhanh cho Windows CMD
└── README.md                      # Tài liệu hướng dẫn sử dụng dự án
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Sử Dụng

### 1. Tích Hợp Toàn Cục (Global Scope - Cho Antigravity IDE)
Liên kết trực tiếp bộ kỹ năng vào thư mục cấu hình toàn cục `~/.gemini/config/skills/`:

**Sử dụng PowerShell:**
```powershell
.\install-junction.ps1 -Global
```

**Sử dụng Command Prompt (CMD):**
```cmd
install-junction.bat global
```

### 2. Tích Hợp Vào Dự Án Bất Kỳ (Workspace Scope)
Liên kết thư mục `.agents` và cấu hình vào một workspace dự án cụ thể:

**Sử dụng PowerShell:**
```powershell
.\install-junction.ps1 -TargetPath "D:\VSD-Solution\Projects\MyNewProject"
```

**Sử dụng Command Prompt (CMD):**
```cmd
install-junction.bat "D:\VSD-Solution\Projects\MyNewProject"
```

### 3. Gỡ Bỏ Liên Kết An Toàn (Uninstall Junction)
Chỉ xóa liên kết NTFS Junction, **không làm ảnh hưởng** đến dữ liệu gốc trong VSD-AI-Toolkit:

```powershell
.\install-junction.ps1 -Global -Uninstall
```

---

## ⚠️ Quy Chuẩn Thực Thi Shell & UTF-8 (PowerShell)

Mọi thao tác thực thi lệnh shell trong môi trường Windows PowerShell tuân thủ:
1. Sử dụng PowerShell thuần (`ForEach-Object`, `Select-String`, `-split`) hoặc Python thay vì các tiện ích Unix (`awk`, `sed`, `grep`).
2. Luôn chỉ định `-Encoding UTF8` khi thao tác file để bảo đảm dữ liệu Tiếng Việt không bị lỗi font (mojibake).
3. Đảm bảo độ rộng hiển thị console không bị tràn hoặc gãy bảng chữ.

---

## 📜 Giấy Phép & Bản Quyền

Nội dung và quy chuẩn thuộc bản quyền của **VSD Solution**.
