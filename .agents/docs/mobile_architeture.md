Kiến trúc cốt lõi: Feature-First Clean Architecture
chia theo từng tính năng nghiệp vụ (ví dụ: chatbot, home, services)
State Management (Quản lý trạng thái): Sử dụng Cubit (một biến thể nhẹ gọn của BLoC). Công nghệ này tách biệt hoàn toàn logic thay đổi trạng thái ra khỏi Ui
Localization (Đa ngôn ngữ): Hệ thống hỗ trợ i18n/l10n (đang xem xét)
BaaS: Tích hợp Firebase (dựa trên file firebase.json), thường dùng để đẩy thông báo (Push Notification), phân tích người dùng (Analytics) hoặc giám sát lỗi (Crashlytics).

- Tầng Domain: Chứa các quy tắc nghiệp vụ cốt lõi thông qua các entities (thực thể) và repositories
- Tầng Data (Xử lý dữ liệu): Nhận nhiệm vụ giao tiếp với bên ngoài. 
Chứa models (để parse dữ liệu JSON từ API thành các thực thể Domain), datasources (nơi gọi API thực tế) và repository_impl (triển khai chi tiết các giao diện đã định nghĩa ở tầng Domain).
- Tầng Presentation (Giao diện người dùng): Hoàn toàn tập trung vào việc hiển thị (pages, widgets) và quản lý trạng thái (cubit).


project/
├── android/                   # Chứa cấu hình và mã nguồn Native cho nền tảng Android.
├── ios/                       # Chứa cấu hình và mã nguồn Native cho nền tảng iOS.
├── assets/                    # Thư mục lưu trữ tài nguyên tĩnh (hình ảnh, fonts, file JSON).
│   └── images/                # (Ví dụ: logo.png, vn.svg).
├── lib/                       # THƯ MỤC QUAN TRỌNG NHẤT: Chứa toàn bộ mã nguồn Dart của ứng dụng.
│   ├── core/                  # Hạ tầng dùng chung cho toàn bộ dự án (Nguyên tắc DRY - Don't Repeat Yourself).
│   │   ├── constants/         # Các hằng số: màu sắc, kích thước, chuỗi văn bản cố định.
│   │   ├── di/                # Dependency Injection: Cấu hình tiêm phụ thuộc (injection.dart).
│   │   ├── error/             # Định nghĩa các loại Exception và Failure chung (Lỗi mạng, lỗi dữ liệu).
│   │   ├── localization/      # Logic xử lý đa ngôn ngữ và chuyển đổi ngôn ngữ.
│   │   ├── network/           # API Client, interceptors, và kiểm tra trạng thái mạng.
│   │   ├── routing/           # Cấu hình điều hướng tập trung (Router & Routes).
│   │   ├── theme/             # Cấu hình giao diện tổng thể (Light/Dark mode, Typography).
│   │   ├── utils/             # Các hàm tiện ích (Format ngày tháng, Validator).
│   │   └── widgets/           # Các UI Component dùng chung ở nhiều nơi (Button, Dialog, Custom AppBar).
│   │
│   ├── features/              # Các Module tính năng nghiệp vụ độc lập (Scalability).
│   │   └── [feature_name]/    # (Ví dụ: chatbot, home, services, ticket_lookup)
│   │       ├── data/          
│   │       │   ├── datasources/# Code kết nối trực tiếp với API hoặc Local Database.
│   │       │   ├── models/     # Định nghĩa cấu trúc JSON map sang Object.
│   │       │   └── [feature]_repository_impl.dart # Code thực thi lấy/gửi dữ liệu.
│   │       ├── domain/        
│   │       │   ├── entities/   # Thực thể nghiệp vụ thuần túy (Object-Oriented Analysis).
│   │       │   └── repositories/# Giao diện (Interface) quy định các chức năng dữ liệu cần có.
│   │       └── presentation/  
│   │           ├── cubit/      # Logic điều khiển trạng thái màn hình của tính năng này.
│   │           ├── pages/      # Các màn hình chính của tính năng.
│   │           └── widgets/    # Các thành phần giao diện nhỏ chỉ dùng riêng cho tính năng này.
│   │
│   ├── l10n/                  # Chứa các file từ điển dịch thuật (.arb) như app_en.arb, app_vi.arb.
│   └── main.dart              # Entry point: Điểm khởi chạy ứng dụng, khởi tạo cấu hình hệ thống.
│
├── analysis_options.yaml      # Cấu hình linter, quy định các luật viết code sạch và đồng nhất cho team.
├── l10n.yaml                  # Cấu hình biên dịch tự động cho đa ngôn ngữ.
├── pubspec.yaml               # File quản lý thông tin dự án, phiên bản SDK, khai báo thư viện (dependencies) và assets.
└── firebase.json              # File cấu hình liên kết các dịch vụ của Firebase.