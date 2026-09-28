---
name: vsd-angular
description: >-
  Công cụ Agent chuyên trách phát triển Frontend Angular Client tại VSD Solution.
  Thực thi Spec-Driven Development (SDD), Ephemeral Test-First (TDD) cô lập đa component, Vòng lặp tự phục hồi (Self-Healing Loop),
  Kiểm định 6 cổng an ninh Anthropic Cybersecurity Gate và Quy trình tự động tuần tự Continuous Auto-Advance Pipeline.
  Sử dụng khi tạo mới, dựng khung (scaffold), cập nhật, kiểm thử hoặc kiểm định (audit) bất kỳ component UI Angular nào của VSD.
---

# vsd-angular Agent Tool

Công cụ Agent chuyên trách phát triển Frontend Angular Client tại VSD Solution, tuân thủ nghiêm ngặt [angular-architecture.md](./references/angular-architecture.md). Toàn bộ hệ thống mẫu và script kiểm tra an ninh Frontend được đóng gói khép kín (Self-Contained) ngay bên trong thư mục của Skill (`resources/templates/` và `scripts/`).

---

## 1. 5 Trụ Cột Kỹ Thuật Frontend

1. **Spec-Driven Development (SDD)**: Khởi tạo toàn bộ tài liệu UI Specs (`_ui_specs.md`) và Tasks (`_ui_tasks.md`) trước khi viết code.
2. **Ephemeral Test-First Biệt Lập (Multi-Component Isolation)**:
   - File test tạm thời luôn mang tên: `{component}_service_test.spec.ts` và nằm ngay trong thư mục component.
   - Chạy kiểm thử RED -> Triển khai Service GREEN -> Tự động xóa file test khi hoàn thành nghiệm thu (DoD).
3. **Self-Healing Loop**: Tự động bắt lỗi TypeScript, template binding, thiếu import và lặp lại sửa lỗi (tối đa 3 lần).
4. **Anthropic Cybersecurity Gate (6 Cổng An Ninh)**:
   - MenuAuth RBAC (Buttons & Route guard).
   - Chống XSS (Template binding an toàn).
   - Không lưu Secrets trong client code.
   - Làm sạch form qua `enforceTextTransform`.
   - Tuân thủ tiêu chuẩn an ninh OWASP Top 10 Web Client.
   - Xóa bỏ test tạm thời sau khi hoàn tất.
   Xem chi tiết tại [angular-cybersecurity-gates.md](./references/angular-cybersecurity-gates.md).
5. **Continuous Auto-Advance Pipeline**: Thực thi tuần tự 7 micro-tasks, tự động cập nhật checklist `[x]` trong `{component}_ui_tasks.md`. Xem chi tiết tại [angular-micro-tasks.md](./references/angular-micro-tasks.md).

---

## 2. Quy Trình Thực Thi Tự Động (Continuous Auto-Advance)

### Bước 1: Trích xuất thông số thành phần
- `subsystem`: Tên phân hệ (vd: `tdtt`, `hrm`, `crm`).
- `group`: Tên nhóm chức năng (vd: `danhmuc`, `nghiepvu`).
- `component`: Tên thành phần viết thường (vd: `chucvu`, `donvi`).
- `SubsystemPascal`: `Tdtt`
- `GroupPascal`: `Danhmuc`
- `ComponentPascal`: `ChucVu`
- `EntityName`: `Tdtt_Danhmuc_ChucVu`
- `ComponentVN`: `Chức vụ`
- `TableSelector`: `tdtt-danhmuc-chucvu`
- `ModalSelector`: `tdtt-danhmuc-modal-chucvu`

### Bước 2: Thực thi Task 1 (UI Specs & Tasks)
- Đọc template từ `resources/templates/docs/`.
- Sinh `docs/{subsystem}/{group}/{component}_ui_specs.md`.
- Sinh `docs/{subsystem}/{group}/{component}_ui_tasks.md`.
- Đánh dấu `[x] Task 1` trong `{component}_ui_tasks.md`.

### Bước 3: Thực thi Task 2 (Entity & @FormField)
- Khai báo class `{{EntityName}}` kế thừa `BaseEntity` trong `src/app/modules/{subsystem}/{subsystem}.type.ts`.
- Gắn decorator `@FormField()` với các cờ `uppercase`, `noAccent`, `noSpecialChar`.
- Đánh dấu `[x] Task 2` trong `{component}_ui_tasks.md`.

### Bước 4: Thực thi Task 3 (Ephemeral Test-First Biệt Lập)
- Sinh file test: `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts` (từ `resources/templates/service/service_test.spec.ts.template`).
- Đảm bảo có header `// EPHEMERAL_TEST_FILE: True`.
- Chạy test xác nhận trạng thái RED.
- Đánh dấu `[x] Task 3` trong `{component}_ui_tasks.md`.

### Bước 5: Thực thi Task 4 (Service & Refresh Signal Bus)
- Bổ sung 6 phương thức RESTful và Subject refresh vào `src/app/modules/{subsystem}/{group}.service.ts`.
- Chạy lại test đạt trạng thái GREEN (pass 100%). Nếu có lỗi, kích hoạt **Self-Healing Loop**.
- Đánh dấu `[x] Task 4` trong `{component}_ui_tasks.md`.

### Bước 6: Thực thi Task 5 (Master Table View Component)
- Sinh 3 file trong `src/app/modules/{subsystem}/{group}/{component}/` (từ `resources/templates/table/`):
  - `{subsystem}-{component}.component.ts`
  - `{subsystem}-{component}.component.html`
  - `{subsystem}-{component}.component.scss`
- Kiểm tra Debounced Search, bảo vệ các nút hành động qua `permissionService.hasPermission()`.
- Đánh dấu `[x] Task 5` trong `{component}_ui_tasks.md`.

### Bước 7: Thực thi Task 6 (Modal Form Dialog Component)
- Sinh 3 file trong `src/app/modules/{subsystem}/{group}/modal/modal-{component}/` (từ `resources/templates/modal/`):
  - `modal-{component}.component.ts`
  - `modal-{component}.component.html`
  - `modal-{component}.component.scss`
- Kiểm tra `buildFormFromClass`, `enforceTextTransform`, và `FormErrorUtil.applyServerErrors`.
- Đánh dấu `[x] Task 6` trong `{component}_ui_tasks.md`.

### Bước 8: Thực thi Task 7 (Routing, Security Gate Audit & DoD Cleanup)
- Bổ sung route kèm `NavigationPermissionGuard` vào `{subsystem}-routing.module.ts`.
- Chạy script kiểm tra an ninh Frontend đóng gói kèm theo skill:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .agents/skills/vsd-angular/scripts/audit-angular-cybersecurity-gate.ps1 -ComponentPath "src/app/modules/{subsystem}/{group}/{component}"
  ```
- Nếu có lỗi an ninh, tự động kích hoạt Self-Healing để sửa ngay.
- Khi đạt 6/6 PASS: Thực hiện **Definition of Done (DoD)**:
  - **XÓA BỎ DUY NHẤT** file `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`.
- Đánh dấu `[x] Task 7` trong `{component}_ui_tasks.md`.

### Bước 9: Báo cáo kết quả
- Báo cáo danh sách các tệp đã tạo kèm link định dạng `file:///`.
- Báo cáo kết quả 6 cổng an ninh Frontend.
- Xác nhận file test tạm thời đã được dọn dẹp sạch sẽ đúng tiêu chí DoD.
