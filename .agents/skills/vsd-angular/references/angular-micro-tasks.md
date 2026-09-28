# Hướng Dẫn Thực Thi Micro-Tasks Frontend (Continuous Auto-Advance)

Tài liệu này hướng dẫn chi tiết quy trình thực thi từng bước trong micro-tasks dành cho Agent `vsd-angular`, đảm bảo khả năng mở rộng khi có nhiều component đồng thời.

---

## Chiến Lược Cô Lập Đa Component (Multi-Component Isolation)

Khi phân hệ hoặc nhóm chức năng có nhiều component (vd: `chucvu`, `donvi`, `nhanvien`):
1. **Thư mục component riêng biệt**:
   `src/app/modules/{subsystem}/{group}/{component}/`
2. **File kiểm thử TDD tạm thời mang định danh component**:
   `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`
3. **Dọn dẹp độc lập**:
   Nghiệm thu component nào chỉ xóa file test tạm thời của component đó:
   `Remove-Item src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`

---

## Chi Tiết Từng Micro-Task

### Task 1: Đặc Tả Giao Diện & Kế Hoạch Kỹ Thuật (SDD)
1. **Đọc yêu cầu người dùng**: Trích xuất `subsystem`, `group`, `component`, `ComponentVN`.
2. **Khởi tạo thư mục tài liệu**: `docs/{subsystem}/{group}/`.
3. **Sinh các tệp**:
   - `docs/{subsystem}/{group}/{component}_ui_specs.md` (từ template `specs.md.template`).
   - `docs/{subsystem}/{group}/{component}_ui_tasks.md` (từ template `tasks.md.template`).
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 1` trong `{component}_ui_tasks.md`.

---

### Task 2: Entity Model & Khai Báo Form Decorator
1. **Mở hoặc tạo tệp**: `src/app/modules/{subsystem}/{subsystem}.type.ts`.
2. **Khai báo class thực thể**:
   - Kế thừa `BaseEntity`.
   - Đặt tên theo chuẩn: `{SubsystemPascal}_{GroupPascal}_{ComponentPascal}`.
   - Gắn decorator `@FormField()` cho từng trường:
     - Trường mã: `required: true, uppercase: true, noAccent: true, noSpecialChar: true, maxLength: 50`.
     - Trường tên: `required: true, maxLength: 255`.
3. **Cập nhật tiến độ**: Đánh dấu `[x] Task 2` trong `{component}_ui_tasks.md`.

---

### Task 3: Ephemeral Test-First Biệt Lập (TDD RED)
1. **Khởi tạo thư mục component**: `src/app/modules/{subsystem}/{group}/{component}/`.
2. **Sinh file test tạm thời**:
   `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`
   (sử dụng template [service_test.spec.ts.template](../resources/templates/service/service_test.spec.ts.template)).
3. **Bắt buộc có header**:
   ```typescript
   // EPHEMERAL_TEST_FILE: True
   // LIFECYCLE: This file is generated strictly for the Frontend TDD Red-Green cycle.
   // As mandated by VSD-AI-Toolkit DoD rules, this file MUST BE DELETED upon 100% micro-task completion.
   ```
4. **Chạy test**: Xác nhận test thất bại (RED-state) vì service chưa hiện thực các phương thức.
5. **Cập nhật tiến độ**: Đánh dấu `[x] Task 3` trong `{component}_ui_tasks.md`.

---

### Task 4: Angular Service & Refresh Signal Bus (TDD GREEN)
1. **Mở hoặc tạo tệp**: `src/app/modules/{subsystem}/{group}.service.ts`.
2. **Bổ sung các phương thức RESTful**:
   - `getAll{ComponentPascal}s()`
   - `get{ComponentPascal}sPaginated(params)`
   - `get{ComponentPascal}ById(id)`
   - `create{ComponentPascal}(payload)`
   - `update{ComponentPascal}(id, payload)`
   - `delete{ComponentPascal}(id)`
3. **Bắt buộc bóc tách dữ liệu `.data` (Data Unwrapping)**:
   - Sử dụng toán tử RxJS `map` và `tap` để chuyển đổi Response Envelope thành mảng/thực thể thuần túy:
     ```typescript
     map((res) => (res && res.data ? res.data : (Array.isArray(res) ? res : []))),
     tap((data) => this._data.next(data || []))
     ```
   - Tuyệt đối không đẩy cả Envelope `{ success, data }` vào `_data$`.
4. **Bổ sung tín hiệu refresh**:
   ```typescript
   private _refresh{{ComponentPascal}}s = new Subject<void>();
   readonly refresh{{ComponentPascal}}s$: Observable<void> = this._refresh{{ComponentPascal}}s.asObservable();

   triggerRefresh{{ComponentPascal}}s(): void {
     this._refresh{{ComponentPascal}}s.next();
   }
   ```
5. **Chạy lại test**: Xác nhận test chuyển sang GREEN (pass 100%). Nếu có lỗi, kích hoạt **Self-Healing Loop**.
6. **Cập nhật tiến độ**: Đánh dấu `[x] Task 4` trong `{component}_ui_tasks.md`.

---

### Task 5: Master Table View Component
1. **Sinh các tệp trong thư mục component**:
   - `{subsystem}-{component}.component.ts` (Selector: `{{subsystem}}-{{group}}-{{component}}`).
   - `{subsystem}-{component}.component.html`.
   - `{subsystem}-{component}.component.scss`.
2. **Kiểm tra**:
   - Đăng ký luồng `_service.data$` gán an toàn: `this.dataSource.data = Array.isArray(data) ? data : []`.
   - Tìm kiếm thời gian thực với `debounceTime(300)` và `distinctUntilChanged()`.
   - Nút bấm Thêm/Sửa/Xóa bọc `permissionService.hasPermission()`.
   - Đăng ký nhận luồng tín hiệu `_service.refresh{ComponentPascal}s$`.
   - Hộp thoại xác nhận xóa qua `FuseConfirmationService`.
3. **Cập nhật tiến độ**: Đánh dấu `[x] Task 5` trong `{component}_ui_tasks.md`.

---

### Task 6: Modal Form Dialog Component
1. **Khởi tạo thư mục modal**: `src/app/modules/{subsystem}/{group}/modal/modal-{component}/`.
2. **Sinh các tệp modal**:
   - `modal-{component}.component.ts` (Selector: `{{subsystem}}-{{group}}-modal-{{component}}`).
   - `modal-{component}.component.html`.
   - `modal-{component}.component.scss`.
3. **Kiểm tra**:
   - Tự động sinh form qua `buildFormFromClass(this._fb, {EntityName} as any)`.
   - Gọi `enforceTextTransform(this.form, configFields, this._destroyRef)`.
   - Bắt lỗi server qua `FormErrorUtil.applyServerErrors`.
   - Sau khi lưu thành công, kích hoạt `_service.triggerRefresh{ComponentPascal}s()`.
4. **Cập nhật tiến độ**: Đánh dấu `[x] Task 6` trong `{component}_ui_tasks.md`.

---

### Task 7: Routing Guard, Cybersecurity Gate Audit & Cleanup Ephemeral Test
1. **Cập nhật routing**: Thêm route vào `src/app/modules/{subsystem}/{subsystem}-routing.module.ts`:
   ```typescript
   {
     path: '{{group}}/{{component}}',
     component: {{SubsystemPascal}}{{ComponentPascal}}Component,
     canActivate: [NavigationPermissionGuard]
   }
   ```
2. **Chạy Cybersecurity Gate Auditor**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .agents/skills/vsd-angular/scripts/audit-angular-cybersecurity-gate.ps1 -ComponentPath "src/app/modules/{subsystem}/{group}/{component}"
   ```
3. **Tự sửa lỗi (Self-Healing)**: Nếu phát hiện vi phạm an ninh, tự động khắc phục ngay lập tức.
4. **Thực hiện Definition of Done (DoD) - Xóa Ephemeral Test**:
   - **XÓA BỎ DUY NHẤT**: `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`.
5. **Cập nhật tiến độ**: Đánh dấu `[x] Task 7` trong `{component}_ui_tasks.md` và hoàn tất pipeline.
