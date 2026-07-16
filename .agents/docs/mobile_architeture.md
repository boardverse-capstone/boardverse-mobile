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
│   │   │   ├── app_colors.dart      # Brand colors, semantic colors (Light)
│   │   │   ├── app_colors_dark.dart # Dark mode colors
│   │   │   ├── app_typography.dart  # Typography với Be Vietnam Pro
│   │   │   ├── app_spacing.dart    # 8pt grid spacing system
│   │   │   ├── app_radius.dart     # Border radius scale
│   │   │   ├── app_elevation.dart   # Shadow presets
│   │   │   ├── app_shimmer.dart    # Skeleton loading animations
│   │   │   ├── app_icons.dart      # Lucide icon mapping
│   │   │   ├── app_theme.dart      # Main theme definition
│   │   │   └── theme.dart          # Export file
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

---

## Đề xuất triển khai: Giả lập Backend với Repository Pattern & DataSource Abstraction + Local Storage

Để phục vụ phát triển các tính năng nghiệp vụ khi chưa có backend thực tế (hoặc API chưa hoàn thiện), chúng ta áp dụng mô hình **Repository Pattern với DataSource Abstraction + Local Storage**.
Mục đích là giữ nguyên cấu trúc tầng Domain và Presentation, khi tích hợp API thực tế chỉ cần thay đổi/bổ sung ở tầng Data mà không ảnh hưởng tới logic của UI/Cubit.

### Mô hình kiến trúc dữ liệu

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (Cubits, Widgets)                       │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Domain Layer: MatchmakingRepository (Abstract Interface)   │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Data Layer                                                  │
│  ┌──────────────────┐         ┌──────────────────────┐      │
│  │ LocalDataSource  │         │   RemoteDataSource   │      │
│  │ (CRUD + Cache)   │         │   (Real API)        │      │
│  └──────────────────┘         └──────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Lợi ích chính
- ✅ **CRUD operations** - Local storage cho phép thêm/sửa/xóa dữ liệu giả lập một cách thực tế.
- ✅ **1 dòng switch** - Chỉ cần đổi cấu hình `USE_MOCK_DATA=true/false` trong file `.env` hoặc cấu hình Global config.
- ✅ **Không cần viết lại hệ thống** - Khi có backend thực tế, chỉ cần viết lớp implement cho `RemoteDataSource` mà không cần sửa đổi Domain Layer hay UI.
- ✅ **Dễ dàng kiểm thử (Easy Testing)** - Mock `LocalDataSource` hoặc `RemoteDataSource` dễ dàng phục vụ viết Unit Test.

---

### Các bước triển khai chi tiết

| Bước | Hoạt động | Mô tả |
| :--- | :--- | :--- |
| **1** | Thêm các dependency cần thiết | Thêm `hive` và `hive_flutter` (hoặc giải pháp local storage tương đương) vào `pubspec.yaml` để lưu trữ dữ liệu offline/mock. |
| **2** | Tạo Local Data Source | Viết lớp `MatchmakingLocalDataSource` thực thi đầy đủ các thao tác CRUD và cache dữ liệu trên thiết bị. |
| **3** | Định nghĩa Remote Data Source | Tạo interface/lớp `MatchmakingRemoteDataSource` định nghĩa các hàm gọi Real API khi sẵn sàng. |
| **4** | Cấu hình Repository Implementation | Cập nhật `MatchmakingRepositoryImpl` sử dụng switch logic dựa trên biến môi trường `USE_MOCK_DATA` để điều hướng gọi dữ liệu từ `LocalDataSource` hay `RemoteDataSource`. |
| **5** | Đăng ký Dependency Injection | Cấu hình trong `lib/core/di/injection.dart` để tự động tiêm (inject) các DataSource và Repository tương ứng tùy theo chế độ chạy ứng dụng. |
| **6** | Quản lý cấu hình môi trường | Thêm cấu hình `USE_MOCK_DATA=true/false` vào file `.env` (hoặc core config) để dễ dàng bật/tắt chế độ giả lập backend. |

---

## Quy tắc sử dụng Theme System

### Packages cần thiết

```yaml
# pubspec.yaml
dependencies:
  # Fonts
  google_fonts: ^6.1.0

  # Icons
  lucide_icons: ^0.257.0

  # Loading/Animation
  shimmer: ^3.0.0
```

### Cách sử dụng Theme

#### 1. Import Theme

```dart
// Import tất cả theme components
import 'package:boardverse_mobile/core/theme/theme.dart';

// Hoặc import riêng lẻ
import 'package:boardverse_mobile/core/theme/app_colors.dart';
import 'package:boardverse_mobile/core/theme/app_theme.dart';
```

#### 2. Sử dụng Colors

```dart
// ✅ DÙNG: AppColors constants
Container(color: AppColors.primary)
Text('Hello', style: TextStyle(color: AppColors.textSecondary))

// ❌ KHÔNG DÙNG: Hardcoded colors
Container(color: Color(0xFFE65100))
```

#### 3. Sử dụng Spacing

```dart
// ✅ DÙNG: AppSpacing constants
Padding(padding: EdgeInsets.all(AppSpacing.md))
SizedBox(height: AppSpacing.sm)

// ❌ KHÔNG DÙNG: Magic numbers
Padding(padding: EdgeInsets.all(16))
SizedBox(height: 8)
```

#### 4. Sử dụng Border Radius

```dart
// ✅ DÙNG: AppRadius constants
Container(
  decoration: BoxDecoration(
    borderRadius: AppRadius.radiusLg,
  ),
)

// ❌ KHÔNG DÙNG: Magic numbers
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
  ),
)
```

#### 5. Sử dụng Icons (Lucide Icons)

```dart
import 'package:lucide_icons/lucide_icons.dart';

// ✅ DÙNG: Lucide Icons
Icon(LucideIcons.gamepad2)      // Board game
Icon(LucideIcons.mapPin)         // Location
Icon(LucideIcons.calendarCheck)  // Booking

// ❌ KHÔNG DÙNG: Material Icons
Icon(Icons.games)
Icon(Icons.location_on)
```

#### 6. Sử dụng Shimmer Loading

```dart
// ✅ DÙNG: AppShimmer
AppShimmer.card(context: context)
AppShimmer.listItem(context: context)
AppShimmer.box(context: context, width: 100, height: 50)

// ❌ KHÔNG DÙNG: Custom shimmer implementation
```

#### 7. Setup Main Theme

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:boardverse_mobile/core/theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppTheme.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

### File Structure của Theme System

```
lib/core/theme/
├── app_colors.dart       # Brand colors (Primary, Secondary, Accent)
│                        # Semantic colors (Success, Error, Warning, Info)
│                        # Neutral colors (Light mode)
├── app_colors_dark.dart  # Dark mode colors
├── app_typography.dart   # Text styles với Be Vietnam Pro font
├── app_spacing.dart      # 8pt grid spacing system
├── app_radius.dart       # Border radius scale
├── app_elevation.dart    # Shadow/elevation presets
├── app_shimmer.dart      # Skeleton loading animations
├── app_icons.dart        # Lucide icon mapping & constants
├── app_theme.dart        # Material theme configuration
└── theme.dart           # Export file
```

### Design Tokens

| Token | Giá trị | Sử dụng |
|-------|---------|----------|
| `AppColors.primary` | `#E65100` | Primary buttons, headers |
| `AppColors.secondary` | `#00897B` | Secondary actions, cafe elements |
| `AppColors.accent` | `#FFD600` | Highlights, badges, points |
| `AppSpacing.md` | `16px` | Default spacing |
| `AppRadius.radiusLg` | `20px` | Card border radius |
| `AppElevation.card` | `4px` | Card shadow |

### Nguyên tắc Theme-First Development

1. **Luôn dùng theme constants** - Không hardcode giá trị màu, spacing, radius
2. **Tách biệt light/dark** - Colors tự động điều chỉnh theo theme
3. **Responsive spacing** - Sử dụng 8pt grid system
4. **Consistent icons** - Chỉ dùng Lucide Icons
5. **Loading states** - Luôn có shimmer cho async content