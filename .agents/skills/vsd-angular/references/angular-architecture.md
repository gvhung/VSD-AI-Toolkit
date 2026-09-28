# Tiêu Chuẩn Kiến Trúc Frontend (VSD Solution)

Tài liệu này xác định các nguyên tắc thiết kế, cấu trúc kiến trúc và tiêu chuẩn an ninh giao diện bắt buộc đối với tất cả các ứng dụng Angular Client trong hệ sinh thái VSD Solution.

---

## 1. Mô Hình Kiến Trúc

Mã nguồn được tổ chức theo từng miền nghiệp vụ:

$$\text{src/app/modules/\{subsystem\}/\{group\}/\{component\}/}$$

```plaintext
src/app/modules/{subsystem}/
├── {subsystem}.module.ts                                       # Module cấp phân hệ (liên kết router & shared modules)
├── {subsystem}-routing.module.ts                               # Định tuyến phân hệ (bảo vệ bởi NavigationPermissionGuard)
├── {subsystem}.type.ts                                         # Entity Model kế thừa BaseEntity kết hợp @FormField()
├── {subsystem}.util.ts                                         # Các hàm tiện ích dùng chung trong phân hệ
├── {group}.service.ts                                          # HTTP Service (RESTful API & Subject refresh signal)
└── {group}/                                                    # Nhóm chức năng (vd: danhmuc, quanly, baocao)
    ├── {component}/                                            # Màn hình danh sách chính (Master Table View)
    │   ├── {subsystem}-{component}.component.ts                # Controller logic (Selector: {subsystem}-{group}-{component})
    │   ├── {subsystem}-{component}.component.html              # Template hiển thị bảng dữ liệu, toolbar & action buttons
    │   └── {subsystem}-{component}.component.scss              # Bảng định kiểu giao diện
    └── modal/                                                  # Hộp thoại Form nghiệp vụ
        └── modal-{component}/                                  # Form thêm mới / cập nhật (Selector: {subsystem}-{group}-modal-{component})
            ├── modal-{component}.component.ts                  # Reactive Form, buildFormFromClass, enforceTextTransform
            ├── modal-{component}.component.html                # Template Form Angular Material
            └── modal-{component}.component.scss                # Bảng định kiểu hộp thoại
```

---

## 2. Chi Tiết Kỹ Thuật

### 2.1 Entity Model & Form Decorator (`{subsystem}.type.ts`)
- Định nghĩa class thực thể kế thừa `BaseEntity` theo cấu trúc `{SubsystemPascal}_{GroupPascal}_{ComponentPascal}`:
  ```typescript
  import { FormField } from 'app/core/form/form-field.decorator';
  import { BaseEntity } from 'app/core/models/base-entity.model';

  export class Tdtt_Danhmuc_Donvi extends BaseEntity {
    @FormField({
      label: 'Mã đơn vị',
      required: true,
      uppercase: true,
      noAccent: true,
      noSpecialChar: true,
      maxLength: 50
    })
    code!: string;

    @FormField({
      label: 'Tên đơn vị',
      required: true,
      maxLength: 255
    })
    name!: string;
  }
  ```

### 2.2 Angular Service & Refresh Bus (`{group}.service.ts`)
- `@Injectable({ providedIn: 'root' })` cung cấp các phương thức tương ứng với RESTful endpoints từ Backend (`/api/{subsystem}/{group}/{component}` sử dụng `BackEndConfig.API_URL`):
  - `get*s()`
  - `get*sPaginated(params)`
  - `get*ById(id)`
  - `create*(payload)`
  - `update*(id, payload)`
  - `delete*(id)`
- **Quy Chuẩn Bóc Tách Dữ Liệu (Data Unwrapping & Stream Integrity)**:
  - Tầng Service đóng vai trò là Adapter chuẩn hóa phản hồi từ Backend trước khi đưa vào luồng dữ liệu của ứng dụng.
  - Bắt buộc sử dụng toán tử RxJS `map` để bóc tách trường `.data` và đồng bộ vào `_data`:
    ```typescript
    map((res) => (res && res.data ? res.data : (Array.isArray(res) ? res : []))),
    tap((data) => this._data.next(data || []))
    ```
  - **Tương thích ngược tuyệt đối**: Hỗ trợ đồng thời cả Response Envelope chuẩn `vsd-api` (`{ success: true, data: [...] }`), mảng phân trang (`{ data: { items, total } }`), lẫn mảng JSON trực tiếp (`[...]`) từ các phân hệ cũ (vd: `bbptchedovanhanhs`).
  - **Bảo vệ toàn vẹn `_data$`**: Tuyệt đối cấm đẩy nguyên Object Envelope `{ success, data }` vào `BehaviorSubject<T[]>`. Luồng `_data$` chỉ phát ra Mảng thực thể thuần túy (`T[]`) để `MatTableDataSource` hiển thị chính xác.
- Quản lý luồng tín hiệu `Subject<void>` (ví dụ: `refresh*s$`) để đồng bộ làm mới dữ liệu giữa Modal và Table.

### 2.3 Màn Hình Danh Sách (`{component}.component.ts`)
- Selector chuẩn: `{{subsystem}}-{{group}}-{{component}}`.
- Quản lý `MatTableDataSource`, `MatPaginator`, `MatSort`.
- Tìm kiếm theo thời gian thực (Real-time Search) với `debounceTime(300)` và `distinctUntilChanged()`.
- Hộp thoại xác nhận xóa qua `FuseConfirmationService`.
- Bảo vệ các nút hành động (Thêm/Sửa/Xóa) qua `PermissionService.hasPermission('ADD' | 'EDIT' | 'DELETE')`.

### 2.4 Hộp Thoại Nhập Liệu (`modal-{component}.component.ts`)
- Selector chuẩn: `{{subsystem}}-{{group}}-modal-{{component}}`.
- Xây dựng Reactive Form tự động từ Class qua `buildFormFromClass` (`app/core/form/form-builder.util`).
- Cưỡng chế quy chuẩn nhập liệu tự động: in hoa (`uppercase`), loại bỏ dấu tiếng Việt (`noAccent`), cấm ký tự đặc biệt (`noSpecialChar`) qua `enforceTextTransform` (`app/core/form/form.util`).
- Xử lý thông báo lỗi form qua `FormErrorUtil.showFormErrors` và `FormErrorUtil.applyServerErrors`.

### 2.5 Định Tuyến (`{subsystem}-routing.module.ts`)
- Gắn `NavigationPermissionGuard` (`app/navigation-permission.guard`) trên toàn bộ các route cấp component để ngăn chặn truy cập trái phép qua URL.

---

## 3. Cổng An Ninh Frontend

1. **Kiểm Soát Phân Quyền MenuAuth RBAC**: Cấm hiển thị nút bấm hoặc truy cập route khi người dùng không có quyền hạn tương ứng.
2. **Chống Tấn Công XSS**: Sử dụng cơ chế template binding an toàn của Angular. Tuyệt đối cấm sử dụng `bypassSecurityTrustHtml` mà không qua kiểm duyệt an ninh.
3. **Chống Rò Rỉ Bí Mật (No Secrets)**: Cấm lưu trữ API Key, Client Secret hoặc JWT Secret trong mã nguồn Frontend `.ts`.
4. **Chuẩn Hóa Dữ Liệu Form**: Ngăn chặn injection và lỗi ký tự lạ bằng cách lọc bỏ ký tự đặc biệt ngay tại tầng nhập liệu trước khi gửi lên server.
5. **Tiêu Chuẩn An Ninh OWASP Top 10**: Tuân thủ nghiêm ngặt các nguyên tắc và thực hành an ninh tốt nhất theo khuyến nghị OWASP Top 10 dành cho Web Client (chống kiểm soát truy cập hỏng, ngăn chặn rò rỉ dữ liệu nhạy cảm, lỗi toàn vẹn dữ liệu và kiểm soát dependency an toàn).
6. **Dọn Dẹp Kiểm Thử Tự Sinh (DoD Cleanup)**: Xóa file `service_test.spec.ts` ngay sau khi nghiệm thu thành công.
