# VSD Angular Frontend Client Development Rules

Tập luật này áp dụng cho toàn bộ các tác vụ phát triển, tạo mới, chỉnh sửa và kiểm thử giao diện Angular Client trong dự án **VSD-AI-Toolkit**.

## 1. Ràng Buộc Kiến Trúc Tầng Frontend
- Cấu trúc module và component bắt buộc tuân theo:
  `src/app/modules/{subsystem}/{group}/{component}/` (table) và `.../{group}/modal/modal-{component}/` (modal).
- Entity class bắt buộc đặt tại `{subsystem}.type.ts` và kế thừa `BaseEntity`.
- **Bóc tách dữ liệu & Toàn vẹn Stream**: Mọi phương thức trong service bắt buộc sử dụng toán tử RxJS `map` để bóc tách `.data` (`map(res => res && res.data ? res.data : (Array.isArray(res) ? res : []))`) và `tap(data => this._data.next(data || []))`. Tuyệt đối cấm đẩy nguyên Envelope Object `{ success, data }` vào `_data$`.
- Tài liệu kỹ thuật giao diện bắt buộc lưu tại:
  `docs/{subsystem}/{group}/{component}_ui_specs.md` và `{component}_ui_tasks.md`.

## 2. Ràng Buộc An Ninh Giao Diện (Frontend Cybersecurity Gates)
- **MenuAuth RBAC**: Nút Thêm/Sửa/Xóa phải được bọc `*ngIf="permissionService.hasPermission('ADD' | 'EDIT' | 'DELETE')"`. Route phải có guard `canActivate: [NavigationPermissionGuard]`.
- **Chống XSS**: Sử dụng 100% template binding an toàn của Angular. Cấm tuyệt đối `bypassSecurityTrustHtml`.
- **Chống rò rỉ Secrets**: Cấm hardcode API keys, secrets, mật khẩu. URL API phải gọi qua `BackEndConfig.API_URL`.
- **Làm sạch Form**: Bắt buộc kích hoạt `enforceTextTransform` với `uppercase`, `noAccent`, `noSpecialChar`.
- **OWASP Top 10**: Tuân thủ các thực hành tốt nhất cho Web Client (phòng chống Broken Access Control, rò rỉ dữ liệu nhạy cảm, injection).

## 3. Chiến Lược Cô Lập Đa Component & Ephemeral Test-First (TDD)
- File test tạm thời luôn đặt biệt lập theo component:
  `src/app/modules/{subsystem}/{group}/{component}/{component}_service_test.spec.ts`.
- File test này là tài sản tạm thời và **BẮT BUỘC PHẢI BỊ XÓA** khi hoàn thành Task 7 theo tiêu chí DoD.
