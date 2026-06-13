# TÀI LIỆU ĐẶC TẢ NGHIỆP VỤ & PROMPT HƯỚNG DẪN AI IMPLEMENT PHÂN HỆ AUTH (FLUTTER)

## 1. THƯ MỤC CẤU HÌNH BIẾN MÔI TRƯỜNG (.ENV CLOUD)

Hệ thống kết nối trực tiếp tới máy chủ Production trên Render. AI phải sử dụng thư viện `flutter_dotenv` để nạp cấu hình và tuyệt đối không được viết thô (hardcode) URL vào mã nguồn.

*Vị trí tệp tin:* `.env` tại thư mục gốc dự án:

```text
API_BASE_URL=https://boardverse-server.onrender.com
```

---

## 2. CHUẨN HÓA DATA CONTRACT VÀ GIẢI MÃ CLAIM TOKEN

Dựa trên cấu trúc Response Envelope chuẩn và cấu trúc JWT Decode thực tế từ API, AI cần tuân thủ quy tắc ép kiểu sau:

Cấu trúc Response chung (Envelope):

```json
{
  "statusCode": 200,
  "message": "Login successful",
  "data": { ... },
  "timestamp": "2026-06-07T07:35:27.6393314Z",
  "path": "/api/Auth/login"
}
```

### Bản đồ ánh xạ Claims (JWT Claims Mapping):

Khi giải mã trường `token` nhận được từ API Đăng nhập, hệ thống dựa vào các khóa XML Soap mặc định để trích xuất quyền và thông tin:

* `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier` → Map thành `userId`
* `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name` → Map thành `username`
* `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` → Map thành `email`
* `http://schemas.microsoft.com/ws/2008/06/identity/claims/role` → Map thành `role`

### Quy tắc chặn quyền đặc thù trên Mobile App:

Ứng dụng di động chỉ chấp nhận người dùng có vai trò là **`User`** (tương đương với vai trò **`Player`** trong nghiệp vụ hệ thống).

* Nếu API đăng nhập trả về đúng thông tin (200 OK) nhưng trường `role` sau khi decode có giá trị khác `User` (Ví dụ: `Admin`, `CafeManager`, `Staff`), hệ thống **bắt buộc phải từ chối phiên**, không lưu Token, hiển thị cảnh báo qua Toast: *"Tài khoản của bạn không có quyền truy cập trên điện thoại."*

---

## 3. CẤU TRÚC THƯ MỤC ĐÃ TRIỂN KHAI

```
lib/
├── core/
│   ├── constants/
│   │   └── api_endpoints.dart          ← Tập trung tất cả API endpoints
│   ├── di/
│   │   └── injection.dart              ← GetIt setup
│   ├── error/
│   │   ├── exceptions.dart             ← ServerException, NetworkException
│   │   └── failures.dart               ← Failure, ServerFailure, NetworkFailure
│   └── network/
│       ├── api_response.dart           ← ApiResponse<T> generic envelope
│       ├── dio_client.dart             ← Dio singleton với baseUrl từ .env
│       └── auth_interceptor.dart       ← Auto-attach token & auto-refresh 401
│
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart
│       │   ├── models/
│       │   │   ├── login_request_model.dart
│       │   │   ├── register_request_model.dart
│       │   │   ├── verify_email_request_model.dart
│       │   │   └── auth_tokens_model.dart
│       │   └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user_entity.dart
│       │   └── repositories/
│       │       └── auth_repository.dart
│       └── presentation/
│           ├── cubit/
│           │   ├── auth_cubit.dart
│           │   └── auth_state.dart
│           └── pages/
│               ├── login_page.dart
│               ├── register_page.dart
│               └── verify_email_page.dart
│
└── main.dart
```

## 4. HƯỚNG DẪN ĐỔI ENDPOINT

Khi backend thay đổi endpoint, chỉ cần sửa **một file duy nhất**:

```
lib/core/constants/api_endpoints.dart
```

Tất cả datasource, interceptor đều reference từ file này.

## 5. HƯỚNG DẪN THÊM FEATURE MỚI

Khi thêm tính năng mới (ví dụ: Profile, Booking), tuân theo cùng pattern:

1. Thêm endpoints mới vào `api_endpoints.dart`
2. Tạo thư mục `lib/features/<feature_name>/` với cấu trúc `data/`, `domain/`, `presentation/`
3. Đăng ký dependencies mới trong `lib/core/di/injection.dart`
