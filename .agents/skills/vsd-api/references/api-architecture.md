# Tiêu Chuẩn Kiến Trúc Go Backend API (VSD Solution)

Tài liệu này xác định các nguyên tắc thiết kế, cấu trúc kiến trúc, chuẩn mực an ninh và những quy tắc bắt buộc áp dụng cho toàn bộ API tại VSD Solution.

---

## 1. Mô Hình Kiến Trúc

API được cấu trúc nghiêm ngặt theo các tầng nghiệp vụ:

$$\text{internal/\{subsystem\}/\{group\}/\{component\}/}$$

```plaintext
internal/
└── {subsystem}/                                 # Tầng 1: Phân Hệ Lớn (vd: tdtt, hrm, crm, core)
    ├── router{Subsystem}.go                     # Router cấp Subsystem (Mount prefix /api/v1/{subsystem})
    └── {group}/                                 # Tầng 2: Nhóm Chức Năng (vd: danhmuc, nghiepvu, baocao)
        ├── router{Group}.go                     # Router cấp Group (Mount group /{group})
        └── {component}/                         # Tầng 3: Thành Phần Nghiệp Vụ Độc Lập
            ├── model/
            │   └── model.go                     # Entity struct UUID, Soft Delete (removed_at), FieldError, ValidationError
            ├── query/
            │   └── query.go                     # IQuery interface & GORM Repository an toàn (defensive checks tx == nil)
            ├── service/
            │   ├── interface.go                 # IService contract (GetAll, Paginate, GetByID, Create, Update, Delete)
            │   ├── service.go                   # Business validation, TrimSpace, Unique Check, Map Update
            │   └── service_test.go              # Unit test TDD RED-state (tự xóa khi nghiệm thu)
            ├── handler/
            │   └── handler.go                   # Gin Controller, RLS Transaction, IDOR Guard, Swagger Godoc
            └── router{Component}.go             # Đăng ký RESTful endpoints chuẩn
```

### 1.1 Cấu Trúc Tài Liệu (`docs/`)
Tương ứng với kiến trúc mã nguồn, thư mục tài liệu `docs/` được phân cấp chuẩn hóa:
```plaintext
docs/
└── {subsystem}/
    ├── PLAN-{subsystem}-{group}.md              # Kế hoạch triển khai kỹ thuật cấp nhóm (Implementation Plan)
    └── {group}/
        ├── sql/
        │   └── {subsystem}_{group}_{component}.sql # DDL Migration & PostgreSQL RLS
        ├── {component}_specs.md                 # Đặc tả nghiệp vụ, Data Contract, Schema, MenuAuth
        └── {component}_tasks.md                 # Bảng phân rã micro-tasks tuần tự
```

---

## 2. Chi Tiết Kỹ Thuật

### 2.1 Tầng Model (`model/model.go`)
- **Khóa chính**: Kiểu UUID chuỗi (`*string` hoặc `uuid.UUID` với tag `gorm:"column:id;type:uuid;not null;default:gen_random_uuid()"`).
- **Cơ chế Xóa mềm (Soft Delete)**: Sử dụng cột `removed_at *time.Time` (`type:timestamp without time zone`), không dùng xóa vật lý.
- **Audit & Tenant Fields**: Bắt buộc `tenant_id` kiểu UUID (`gorm:"column:tenant_id;type:uuid;not null;index"` json:"tenant_id" - tuyệt đối KHÔNG dùng `varchar(50)` để tương thích hoàn toàn với thủ tục RLS PostgreSQL), `org_id *string` (`type:uuid`), `description *string` (`type:text`), `created_by *string` (`type:varchar(255)`), `updated_by *string` (`type:varchar(255)`), `removed_by *string` (`type:varchar(255)`), `approved_by *string` (`type:varchar(255)`), `created_at`, `updated_at`.
- **Cấu trúc Lỗi Chi Tiết Chuẩn Hóa**:
  ```go
  type FieldError struct {
      Field   string `json:"field"`
      Name    string `json:"name"`
      Message string `json:"message"`
      Rule    string `json:"rule,omitempty"`
  }
  type ValidationError struct {
      Errors []FieldError `json:"errors"`
  }
  ```

### 2.2 Tầng Query (`query/query.go`)
- Khai báo interface độc lập `I{Component}Query` và struct hiện thực:
  - `FindAll(ctx context.Context, tx *gorm.DB) ([]*model.{Entity}, error)` (mặc định filter `removed_at IS NULL`, order `created_at DESC`).
  - `FindByID(ctx context.Context, tx *gorm.DB, id string) (*model.{Entity}, error)`.
  - `FindByCode(ctx context.Context, tx *gorm.DB, code string) (*model.{Entity}, error)`.
  - `CountByCode(ctx context.Context, tx *gorm.DB, code string, excludeID string) (int64, error)`.
  - `Create(ctx context.Context, tx *gorm.DB, item *model.{Entity}) error`.
  - `Update(ctx context.Context, tx *gorm.DB, id string, updateData map[string]interface{}) (int64, error)`.
  - `DeleteSoft(ctx context.Context, tx *gorm.DB, id string) (int64, error)`.
  - `Paginate(ctx context.Context, tx *gorm.DB, pageIndex, pageSize int, searchKey string) ([]*model.{Entity}, int64, error)`.
- **Lập trình phòng thủ**: Hàm trợ giúp kiểm tra `if tx == nil { return nil, errors.New("database transaction is required") }`.

### 2.3 Tầng Service (`service/interface.go` & `service/service.go`)
- Interface `I{Component}Service` nhận `(ctx context.Context, tx *gorm.DB, ...)`.
- Kiểm tra hợp lệ dữ liệu (Validation Engine):
  - Chuẩn hóa chuỗi bằng `strings.TrimSpace`.
  - Kiểm tra các trường bắt buộc (`required`).
  - Kiểm tra tính duy nhất qua `Query.CountByCode` (`unique`).
- Cập nhật an toàn (Safe Map Update): Chuyển struct qua map để cập nhật chính xác các giá trị rỗng/mặc định mà GORM thường bỏ qua.

### 2.4 Tầng Handler (`handler/handler.go`)
- Trích xuất định danh khách thuê từ context đã xác thực token:
  ```go
  tenantID := c.GetString("tenant_id")
  ```
- Mọi thao tác truy vấn và biến đổi dữ liệu được thực thi an toàn trong Transaction CSDL:
  ```go
  database.DBTenant.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
      if err := tx.Exec("SET LOCAL app.current_tenant = ?", tenantID).Error; err != nil {
          return err
      }
      // Gọi service tương ứng với tx
  })
  ```
- **Chống tấn công IDOR**: Server luôn tự động gán `item.TenantID = tenantID` trước khi ghi, cấm tiếp nhận `tenant_id` từ body của người dùng.
- **Che giấu lỗi hệ thống (Data Masking)**: Chỉ trả về mã lỗi và mô tả thân thiện, tuyệt đối không trả raw SQL stack trace ra ngoài.
- **Swagger Documentation**: Khai báo đầy đủ các annotations Godoc (`@Summary`, `@Tags`, `@Accept`, `@Produce`, `@Param`, `@Success`, `@Failure`, `@Router`).

### 2.5 Tầng Router (`router.go`)
- **Tự động tạo bảng (Auto-Migration)**: Trước khi mount routes, gọi `gormDB.AutoMigrate(&model.Entity{})` để tự động khởi tạo bảng nếu chưa có.
- **Kích hoạt RLS tự động**: Ngay sau AutoMigrate, kích hoạt phân lập đa khách thuê qua thủ tục:
  ```go
  gormDB.Exec("CALL apply_rls_for_tables(ARRAY['<table_name>'])")
  ```
  kèm logging xác thực ra console.
- **Đăng ký đúng 6 endpoints RESTful chuẩn mực**:
```go
group := rg.Group("/{{component}}")
{
    group.GET("", h.GetAll)
    group.GET("/paginate", h.Paginate)
    group.GET("/:id", h.GetByID)
    group.POST("", h.Create)
    group.PUT("/:id", h.Update)
    group.DELETE("/:id", h.Delete)
}
```

---

## 3. Cổng An Ninh

1. **Row-Level Security (RLS)**: Bắt buộc kích hoạt thủ tục `CALL apply_rls_for_tables(ARRAY['...'])` trên toàn bộ bảng dữ liệu nghiệp vụ và cưỡng chế `SET LOCAL app.current_tenant = ?` trên mỗi connection transaction PostgreSQL.
2. **Chống SQLi**: Cấm sử dụng toán tử cộng chuỗi `+` hoặc `fmt.Sprintf` trong các câu lệnh GORM. 100% sử dụng tham số hóa `?`.
3. **Chống IDOR**: Luôn ràng buộc bản ghi phải thuộc về `tenant_id` của phiên đăng nhập hợp lệ. Ghi đè `item.TenantID = tenantID` ở Handler.
4. **Bảo vệ Secrets & JWT**: Cấm hardcode bí mật, token, mật khẩu trong mã nguồn. Sử dụng biến môi trường hoặc Vault.
5. **MenuAuth RBAC**: Tích hợp middleware kiểm tra quyền hạn menu và action trước khi chuyển tiếp request vào handler.
6. **Tự động hóa OpenAPI**: Đồng bộ Swagger Godoc qua `swag init -g cmd/api/main.go -o docs --parseDependency --parseInternal --ot go,json`.
7. **Tiêu Chuẩn An Ninh OWASP API Security Top 10**: Tuân thủ nghiêm ngặt các nguyên tắc và thực hành phòng thủ theo khuyến nghị OWASP API Security (ngăn chặn Broken Object Level Authorization - BOLA/IDOR, Broken Authentication, Mass Assignment, SQL Injection và rò rỉ dữ liệu nhạy cảm).
