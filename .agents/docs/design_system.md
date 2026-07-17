# BoardVerse Mobile - Design System Documentation

> **Document Version**: 1.1
> **Last Updated**: 2026-07-16
> **Target Platform**: Mobile (iOS & Android)
> **Primary Language**: Tiếng Việt (Vietnamese)

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Design Philosophy](#2-design-philosophy)
3. [Color System](#3-color-system)
4. [Typography System](#4-typography-system)
5. [Spacing & Layout](#5-spacing--layout)
6. [Border Radius & Elevation](#6-border-radius--elevation)
7. [Component Styles](#7-component-styles)
8. [Dark Mode](#8-dark-mode)
9. [Animation & Loading States](#9-animation--loading-states) ← SHIMMER
10. [Icons System](#10-icons-system) ← LUCIDE ICONS
11. [Implementation Guide](#11-implementation-guide)

---

## 1. Tổng quan

BoardVerse là nền tảng kết nối người yêu board game với các quán cafe board game. Design system này hướng đến:

- **Gamification**: Tạo cảm giác vui vẻ, năng động cho trải nghiệm game
- **Warm & Cozy**: Không khí ấm cúng như đang ngồi ở quán cafe
- **Trust & Clarity**: Rõ ràng, dễ hiểu cho các tác vụ booking và payment
- **Vietnamese-first**: Tối ưu cho tiếng Việt với font Be Vietnam Pro

---

## 2. Design Philosophy

### 2.1 Core Values

| Value | Mô tả | Ứng dụng |
|-------|-------|----------|
| **Năng động** | Game-like, engaging | Animations, badges, progress indicators |
| **Ấm cúng** | Cozy, welcoming | Border radius lớn, warm colors, soft shadows |
| **Đáng tin** | Trustworthy, clear | Consistent patterns, clear hierarchy |
| **Dễ tiếp cận** | Accessible, inclusive | Đủ contrast, touch targets ≥48px |

### 2.2 Visual Identity

- **Primary Color Direction**: Deep Orange (#E65100) - năng động, game-like
- **Secondary Color**: Teal (#00897B) - cafe vibes, trust
- **Accent**: Amber (#FFD600) - highlights, points, badges
- **Style**: Modern, rounded, friendly

---

## 3. Color System

### 3.1 Brand Colors (Primary Palette)

```dart
// Brand Colors - Sử dụng cho logo, primary buttons, headers
class BrandColors {
  // Primary - Deep Orange (Game energy)
  static const Color primary = Color(0xFFE65100);        // Main brand color
  static const Color primaryLight = Color(0xFFFF9E40);   // Hover, lighter states
  static const Color primaryDark = Color(0xFFAC1900);    // Pressed, darker states

  // Secondary - Teal (Cafe warmth, trust)
  static const Color secondary = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4EBAAA);
  static const Color secondaryDark = Color(0xFF005B4F);

  // Accent - Amber (Highlights, rewards, points)
  static const Color accent = Color(0xFFFFD600);
  static const Color accentLight = Color(0xFFFFFF52);
  static const Color accentDark = Color(0xFFC7A500);

  // Neutral - Black & White
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}
```

### 3.2 Semantic Colors (Ngữ nghĩa)

```dart
// Semantic Colors - Thể hiện trạng thái và ý nghĩa
class SemanticColors {
  // Success - Thành công, xác nhận
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFF5EFF82);
  static const Color successDark = Color(0xFF009C32);

  // Error - Lỗi, hủy, cảnh báo nghiêm trọng
  static const Color error = Color(0xFFFF1744);
  static const Color errorLight = Color(0xFFFF616F);
  static const Color errorDark = Color(0xFFC50E29);

  // Warning - Cảnh báo, chờ xử lý
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningLight = Color(0xFFFFDD4B);
  static const Color warningDark = Color(0xFFC67C00);

  // Info - Thông tin, gợi ý
  static const Color info = Color(0xFF2979FF);
  static const Color infoLight = Color(0xFF73A5FF);
  static const Color infoDark = Color(0xFF004ECB);
}
```

### 3.3 Game Status Colors (Trạng thái game/lobby)

```dart
// Game-specific status colors
class GameStatusColors {
  static const Color available = Color(0xFF00E676);   // Phòng trống, sẵn sàng
  static const Color busy = Color(0xFFFF5252);        // Đầy, đang sử dụng
  static const Color waiting = Color(0xFFFFD740);      // Đang chờ, pending
  static const Color inProgress = Color(0xFF7C4DFF);   // Đang diễn ra
  static const Color completed = Color(0xFF00BCD4);    // Hoàn thành
}
```

### 3.4 ELO/Rating Colors (Hệ thống xếp hạng)

```dart
// ELO tier colors
class EloColors {
  static const Color bronze = Color(0xFFCD7F32);      // < 1000 ELO
  static const Color silver = Color(0xFFC0C0C0);       // 1000 - 1499 ELO
  static const Color gold = Color(0xFFFFD700);          // 1500 - 1999 ELO
  static const Color platinum = Color(0xFFE5E4E2);      // 2000 - 2499 ELO
  static const Color diamond = Color(0xFFB9F2FF);        // 2500+ ELO
}
```

### 3.5 Neutral Colors (Nền và viền)

#### Light Theme

```dart
// Light Theme Neutrals
class LightNeutrals {
  // Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF212121);

  // Borders & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFFE65100);
  static const Color divider = Color(0xFFEEEEEE);

  // Shadows
  static const Color shadowLight = Color(0x0D000000);  // rgba(0,0,0,0.05)
  static const Color shadowMedium = Color(0x1A000000); // rgba(0,0,0,0.10)
  static const Color shadowDark = Color(0x33000000);    // rgba(0,0,0,0.20)
}
```

#### Dark Theme

```dart
// Dark Theme Neutrals
class DarkNeutrals {
  // Backgrounds
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  static const Color cardBackground = Color(0xFF252525);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF707070);
  static const Color textDisabled = Color(0xFF5E5E5E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF212121);

  // Borders & Dividers
  static const Color border = Color(0xFF3D3D3D);
  static const Color borderFocused = Color(0xFFFF9E40);
  static const Color divider = Color(0xFF2D2D2D);

  // Shadows
  static const Color shadowLight = Color(0x1AFFFFFF);  // rgba(255,255,255,0.10)
  static const Color shadowMedium = Color(0x33FFFFFF); // rgba(255,255,255,0.20)
  static const Color shadowDark = Color(0x4DFFFFFF);   // rgba(255,255,255,0.30)
}
```

### 3.6 Color Usage Guidelines

| Color | Sử dụng cho | Ví dụ |
|-------|------------|-------|
| `primary` | Primary actions, headers, logo | Button đặt bàn, AppBar |
| `primaryLight` | Hover states, backgrounds | Selected chips, highlights |
| `secondary` | Secondary actions, cafe-related | Cafe info cards |
| `accent` | Points, badges, rewards | Karma display, achievement badges |
| `success` | Confirmations, available | "Đặt bàn thành công", phòng trống |
| `error` | Errors, cancellations | "Hủy đặt", validation errors |
| `warning` | Pending states | "Đang chờ xác nhận" |
| `info` | Informational | Hướng dẫn, tips |

---

## 4. Typography System

### 4.1 Font Family: Be Vietnam Pro

**Lý do chọn Be Vietnam Pro:**
- Font tiếng Việt chính thức của Chính phủ Việt Nam
- Hỗ trợ đầy đủ dấu tiếng Việt (ă, â, đ, ê, ô, ơ, ư, ơ)
- Thiết kế hiện đại, dễ đọc trên mobile
- Có nhiều weights từ Regular đến Bold

**Google Fonts URL:**
```
https://fonts.google.com/specimen/Be+Vietnam+Pro
```

**Cài đặt trong pubspec.yaml:**
```yaml
dependencies:
  google_fonts: ^6.1.0
```

### 4.2 Font Weights

```dart
// Font Weights enum (sử dụng Be Vietnam Pro)
class AppFontWeights {
  static const FontWeight thin = FontWeight.w100;        // Độ mỏng (ít dùng)
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;      // Mặc định, body text
  static const FontWeight medium = FontWeight.w500;       // Medium emphasis
  static const FontWeight semiBold = FontWeight.w600;     // Tiêu đề phụ, buttons
  static const FontWeight bold = FontWeight.w700;         // Tiêu đề chính
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;        // Display numbers
}
```

### 4.3 Type Scale

```dart
// Typography Scale - Sử dụng Be Vietnam Pro
class AppTypography {
  // Display - Dùng cho numbers lớn (ELO, prices)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 57,
    height: 64 / 57,  // line-height / font-size
    fontWeight: AppFontWeights.black,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 45,
    height: 52 / 45,
    fontWeight: AppFontWeights.bold,
    letterSpacing: 0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 36,
    height: 44 / 36,
    fontWeight: AppFontWeights.bold,
    letterSpacing: 0,
  );

  // Headlines - Tiêu đề chính của trang
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 32,
    height: 40 / 32,
    fontWeight: AppFontWeights.bold,
    letterSpacing: 0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 28,
    height: 36 / 28,
    fontWeight: AppFontWeights.bold,
    letterSpacing: 0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 24,
    height: 32 / 24,
    fontWeight: AppFontWeights.semiBold,
    letterSpacing: 0,
  );

  // Titles - Tiêu đề của cards, dialogs
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 22,
    height: 28 / 22,
    fontWeight: AppFontWeights.semiBold,
    letterSpacing: 0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: AppFontWeights.medium,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: AppFontWeights.medium,
    letterSpacing: 0.1,
  );

  // Body - Nội dung chính
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: AppFontWeights.regular,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: AppFontWeights.regular,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: AppFontWeights.regular,
    letterSpacing: 0.4,
  );

  // Labels - Buttons, chips, tags
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: AppFontWeights.medium,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: AppFontWeights.medium,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 11,
    height: 16 / 11,
    fontWeight: AppFontWeights.medium,
    letterSpacing: 0.5,
  );
}
```

### 4.4 Typography Usage Guide

| Style | Sử dụng cho | Ví dụ |
|-------|------------|-------|
| `displayLarge` | Số ELO lớn, prices | `1,500 ELO`, `₫150,000` |
| `displayMedium` | Hero numbers | Số người chơi trong lobby |
| `headlineLarge` | Page titles | "Khám phá Game", "Đặt bàn" |
| `headlineMedium` | Section headers | "Game phổ biến", "Quán gần đây" |
| `headlineSmall` | Card titles | Tên game, tên quán |
| `titleLarge` | Dialog titles | "Xác nhận đặt bàn" |
| `titleMedium` | List item titles | Tên người dùng, mô tả |
| `bodyLarge` | Main content | Mô tả game, thông tin quán |
| `bodyMedium` | Secondary content | Thời gian chơi, số người |
| `bodySmall` | Captions, hints | "Cập nhật 2 phút trước" |
| `labelLarge` | Primary buttons | "Đặt bàn ngay" |
| `labelMedium` | Chips, badges | "Board Game", "2-4 người" |

### 4.5 Vietnamese Typography Best Practices

```dart
// Lưu ý khi sử dụng tiếng Việt:
// 1. Font size tối thiểu cho body text: 14sp (đảm bảo đọc được dấu)
// 2. Line height cho tiếng Việt: 1.4 - 1.6 (vì có dấu trên/dưới)
// 3. Letter spacing: mặc định hoặc slightly negative cho headers
// 4. Tránh all-caps cho tiếng Việt (khó đọc)

// Ví dụ bad practice:
Text(
  'KHÁM PHÁ BOARD GAME',
  style: TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 14,
    letterSpacing: 1.5,  // Chỉ dùng cho English all-caps
  ),
);

// Good practice:
Text(
  'Khám phá Board Game',
  style: TextStyle(
    fontFamily: 'Be Vietnam Pro',
    fontSize: 14,
    letterSpacing: 0,  // Normal spacing
  ),
);
```

---

## 5. Spacing & Layout

### 5.1 Spacing Scale (8pt Grid System)

```dart
// 8pt Grid System - Giữ nhất quán spacing trong app
class AppSpacing {
  // Base spacing values
  static const double xs = 4.0;     // 4px - Tight spacing
  static const double sm = 8.0;     // 8px - Related elements
  static const double md = 16.0;    // 16px - Default padding
  static const double lg = 24.0;    // 24px - Section spacing
  static const double xl = 32.0;    // 32px - Major sections
  static const double xxl = 48.0;   // 48px - Screen-level
  static const double xxxl = 64.0;   // 64px - Hero spacing

  // Padding presets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // Vertical padding
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // Screen padding (with safe area consideration)
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: md);
}
```

### 5.2 Screen Layout Guidelines

```dart
// Screen structure guidelines
class AppLayout {
  // Screen edge padding
  static const double screenHorizontalPadding = 16.0;
  static const double screenVerticalPadding = 16.0;

  // Card spacing
  static const double cardMargin = 16.0;
  static const double cardPadding = 16.0;
  static const double cardSpacing = 12.0;  // Between cards

  // List spacing
  static const double listItemSpacing = 8.0;
  static const double listSectionSpacing = 24.0;

  // Grid
  static const double gridSpacing = 16.0;
  static const int mobileGridColumns = 2;  // Game cards grid
  static const double gridChildAspectRatio = 0.75;  // width / height
}
```

### 5.3 Responsive Breakpoints

```dart
// Responsive breakpoints
class AppBreakpoints {
  static const double mobile = 375.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;
  static const double largeDesktop = 1440.0;
}

// Responsive helpers
extension BuildContextResponsive on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < tablet;
  bool get isTablet => MediaQuery.of(this).size.width >= tablet &&
                       MediaQuery.of(this).size.width < desktop;
  bool get isDesktop => MediaQuery.of(this).size.width >= desktop;
}
```

---

## 6. Border Radius & Elevation

### 6.1 Border Radius Scale

```dart
// Border Radius - Tạo cảm giác friendly, modern
class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;      // Small chips, small buttons
  static const double sm = 8.0;      // Text fields, small cards
  static const double md = 12.0;     // Default buttons, inputs
  static const double lg = 16.0;     // Cards, bottom sheets
  static const double xl = 20.0;     // Featured cards, modals
  static const double xxl = 24.0;    // Large dialogs
  static const double full = 999.0;   // Pills, avatars, FABs

  // BorderRadius presets
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));

  // Top-only radius (for bottom sheets)
  static const BorderRadius radiusTopLg = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );

  static const BorderRadius radiusTopXl = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
}
```

### 6.2 Elevation/Shadow Scale

```dart
// Elevation - Soft shadows cho modern feel
class AppElevation {
  static const double none = 0;
  static const double xs = 1.0;      // Subtle cards
  static const double sm = 2.0;      // Default cards, list items
  static const double md = 4.0;       // Floating elements
  static const double lg = 8.0;      // FAB, bottom sheets
  static const double xl = 16.0;      // Dialogs, modals
  static const double xxl = 24.0;     // Full-screen modals

  // Shadow presets
  static List<BoxShadow> get shadowXs => [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
```

---

## 7. Component Styles

### 7.1 Primary Button (ElevatedButton)

```dart
// Primary Button - Dùng cho các action chính
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: BrandColors.primary,
    foregroundColor: BrandColors.white,
    elevation: AppElevation.sm,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.radiusMd,
    ),
    textStyle: AppTypography.labelLarge,
    minimumSize: const Size(88, 48),  // Touch target ≥48px
  ),
  child: const Text('Đặt bàn ngay'),
)
```

### 7.2 Secondary Button (OutlinedButton)

```dart
// Secondary Button - Dùng cho cancel, back
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: BrandColors.primary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.radiusMd,
    ),
    side: const BorderSide(
      color: BrandColors.primary,
      width: 1.5,
    ),
    textStyle: AppTypography.labelLarge,
    minimumSize: const Size(88, 48),
  ),
  child: const Text('Hủy'),
)
```

### 7.3 Text Button (TextButton)

```dart
// Text Button - Dùng cho links
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: BrandColors.primary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    textStyle: AppTypography.labelLarge,
  ),
  child: const Text('Xem thêm'),
)
```

### 7.4 Floating Action Button

```dart
// Home FAB - Gradient style với brand colors
Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [BrandColors.primary, BrandColors.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: AppRadius.radiusXl,
    boxShadow: AppElevation.shadowLg,
  ),
  child: FloatingActionButton(
    backgroundColor: Colors.transparent,
    elevation: 0,
    onPressed: () {},
    child: const Icon(Icons.home_rounded, color: BrandColors.white),
  ),
)
```

### 7.5 Cards

```dart
// Game Card
Card(
  elevation: AppElevation.sm,
  shape: RoundedRectangleBorder(
    borderRadius: AppRadius.radiusLg,
  ),
  clipBehavior: Clip.antiAlias,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Image với aspect ratio 4:3
      AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(...),
      ),
      Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catan', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('3-4 người • 60-120 phút', style: AppTypography.bodySmall),
          ],
        ),
      ),
    ],
  ),
)
```

### 7.6 Text Input Fields

```dart
// Input Field
TextField(
  style: AppTypography.bodyMedium,
  decoration: InputDecoration(
    filled: true,
    fillColor: LightNeutrals.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: AppRadius.radiusMd,
      borderSide: const BorderSide(color: LightNeutrals.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.radiusMd,
      borderSide: const BorderSide(
        color: BrandColors.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.radiusMd,
      borderSide: const BorderSide(color: SemanticColors.error),
    ),
    hintStyle: AppTypography.bodyMedium.copyWith(
      color: LightNeutrals.textHint,
    ),
  ),
)
```

### 7.7 Chips/Tags

```dart
// Category Chip
Chip(
  backgroundColor: LightNeutrals.surfaceVariant,
  selectedColor: BrandColors.primaryLight,
  labelStyle: AppTypography.labelMedium,
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: AppRadius.radiusSm,
  ),
)
```

### 7.8 Bottom Navigation Bar

```dart
// Custom Bottom Nav với center FAB
NavigationBar(
  selectedIndex: currentIndex,
  backgroundColor: LightNeutrals.surface,
  indicatorColor: BrandColors.primaryLight.withOpacity(0.3),
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Khám phá',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Đặt bàn',
    ),
    // Center placeholder for FAB
    NavigationDestination(
      icon: SizedBox.shrink(),
      selectedIcon: SizedBox.shrink(),
      label: '',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events),
      label: 'Giải đấu',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Hồ sơ',
    ),
  ],
)
```

### 7.9 Loading States

```dart
// Shimmer loading effect cho cards
Shimmer.fromColors(
  baseColor: LightNeutrals.surfaceVariant,
  highlightColor: LightNeutrals.surface,
  child: Container(
    width: double.infinity,
    height: 200,
    decoration: BoxDecoration(
      color: LightNeutrals.surfaceVariant,
      borderRadius: AppRadius.radiusLg,
    ),
  ),
)

// Circular progress indicator
CircularProgressIndicator(
  color: BrandColors.primary,
  strokeWidth: 3,
)
```

### 7.10 Empty States

```dart
// Empty state pattern
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.search_off_rounded,
        size: 80,
        color: LightNeutrals.textHint,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Không tìm thấy kết quả',
        style: AppTypography.titleMedium.copyWith(
          color: LightNeutrals.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Thử tìm kiếm với từ khóa khác',
        style: AppTypography.bodyMedium.copyWith(
          color: LightNeutrals.textHint,
        ),
      ),
    ],
  ),
)
```

---

## 8. Dark Mode

### 8.1 Dark Mode Implementation

```dart
// ThemeProvider để switch light/dark
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
```

### 8.2 Dark Mode Color Adjustments

**Nguyên tắc:**
1. Giữ primary/secondary colors tương tự light theme (để nhận diện thương hiệu)
2. Tăng lightness cho text trên dark backgrounds
3. Giảm contrast mạnh để tránh mỏi mắt
4. Background nên là `#121212` hoặc `#1E1E1E` (Material Dark guidelines)

**Adjustments:**

```dart
// Dark theme - lightened primary colors
Color darkPrimary = Color.lerp(
  BrandColors.primary,
  BrandColors.white,
  0.2,  // 20% lighter
)!;

// Or use HSL for better results
HSLColor hslPrimary = HSLColor.fromColor(BrandColors.primary);
Color darkPrimary = hslPrimary
  .withLightness((hslPrimary.lightness + 0.2).clamp(0.0, 1.0))
  .toColor();
```

### 8.3 Dark Mode Usage

```dart
// Sử dụng ThemeExtension hoặc ColorScheme
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: darkPrimary,
    secondary: darkSecondary,
    surface: DarkNeutrals.surface,
    error: SemanticColors.error,
  ),
  scaffoldBackgroundColor: DarkNeutrals.background,
  cardColor: DarkNeutrals.cardBackground,
  dividerColor: DarkNeutrals.divider,
  textTheme: darkTextTheme,
);

// Sử dụng trong widget
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.bodyLarge,
  ),
)
```

---

## 9. Animation & Loading States

### 9.1 Shimmer Loading (Skeleton)

**Package:** `shimmer: ^3.0.0`

Dùng shimmer để hiển thị trạng thái loading cho cards, lists, và content areas.

```yaml
# pubspec.yaml
dependencies:
  shimmer: ^3.0.0
```

#### 9.1.1 Shimmer Colors (Light Theme)

```dart
// Shimmer colors cho light mode
class ShimmerColors {
  static const Color baseColor = Color(0xFFE0E0E0);      // #E0E0E0 - Màu nền shimmer
  static const Color highlightColor = Color(0xFFF5F5F5);  // #F5F5F5 - Màu highlight

  // Gradient preset
  static ShimmerColors? _instance;
  static ShimmerColors get instance => _instance ??= ShimmerColors._();
  ShimmerColors._();

  LinearGradient get gradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [baseColor, highlightColor, baseColor],
    stops: [0.0, 0.5, 1.0],
  );
}
```

#### 9.1.2 Shimmer Colors (Dark Theme)

```dart
// Shimmer colors cho dark mode
class ShimmerColorsDark {
  static const Color baseColor = Color(0xFF2C2C2C);
  static const Color highlightColor = Color(0xFF3D3D3D);
}
```

#### 9.1.3 Common Shimmer Patterns

```dart
// Shimmer Box - Dùng cho placeholder boxes
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? ShimmerColorsDark.baseColor : ShimmerColors.baseColor,
      highlightColor: isDark ? ShimmerColorsDark.highlightColor : ShimmerColors.highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Shimmer Card - Dùng cho game card placeholder
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (4:3 aspect ratio)
          const AspectRatio(
            aspectRatio: 4 / 3,
            child: ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder
                ShimmerBox(
                  width: 120,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Subtitle placeholder
                ShimmerBox(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shimmer List Item - Dùng cho list items
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const ShimmerBox(
            width: 56,
            height: 56,
            borderRadius: 12,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.xs),
                ShimmerBox(
                  width: 150,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 9.1.4 Shimmer Usage Guidelines

| Quy tắc | Mô tả |
|---------|--------|
| **Không animate khi data đã load** | Remove shimmer ngay khi có data |
| **Phù hợp content shape** | Card shimmer → card shape, text shimmer → line shapes |
| **Direction** | Mặc định: horizontal (left → right) |
| **Duration** | ~1500ms per cycle là smooth nhất |

---

## 10. Icons System

### 10.1 Material Icons

Sử dụng Material Icons (Flutter's built-in Icons class) thay vì Lucide Icons vì:
- **Native Flutter**: Không cần package bên ngoài, giảm dependency
- **Stable**: Không có vấn đề tương thích với Flutter SDK mới
- **Consistent**: Luôn được cập nhật cùng Flutter
- **Outlined style**: Ưu tiên dùng icons có suffix `_outlined` để đồng nhất với design

> **Lưu ý**: Không cần thêm package `lucide_icons` vào pubspec.yaml vì Material Icons đã có sẵn trong Flutter SDK.

#### 10.1.1 Import & Usage

```dart
import 'package:flutter/material.dart';
// hoặc sử dụng qua AppIcons class
import 'core/theme/app_icons.dart';

// Basic usage - trực tiếp từ Material
Icon(Icons.games_outlined)              // Board game
Icon(Icons.location_on_outlined)        // Location
Icon(Icons.event_available_outlined)    // Booking/Reservation
Icon(Icons.group_outlined)              // Group/Players
Icon(Icons.emoji_events_outlined)       // Ranking/Competition
Icon(Icons.search)                      // Search
Icon(Icons.filter_list)                 // Filter
Icon(Icons.notifications_outlined)      // Notifications
Icon(Icons.settings_outlined)           // Settings
Icon(Icons.person_outline)              // Profile
Icon(Icons.logout)                      // Logout
Icon(Icons.add)                         // Add/Create
Icon(Icons.remove)                      // Remove
Icon(Icons.close)                      // Close/Cancel
Icon(Icons.check)                       // Confirm/Success
Icon(Icons.access_time)                 // Time
Icon(Icons.star)                        // Rating/Favorite
Icon(Icons.favorite)                    // Like/Favorite
Icon(Icons.share_outlined)              // Share
Icon(Icons.camera_alt_outlined)         // Camera
Icon(Icons.qr_code)                    // QR Code
```

#### 10.1.2 Icon Size & Color Guidelines

```dart
// Icon sizes theo context - sử dụng AppIcons class
class AppIconSizes {
  static const double xs = 12.0;   // Inline với text nhỏ
  static const double sm = 16.0;   // Chips, small labels
  static const double md = 20.0;   // Default icon size
  static const double lg = 24.0;   // Navigation, featured
  static const double xl = 32.0;   // Empty state icons
  static const double xxl = 48.0;  // Large decorative icons
}

// Sử dụng với AppIcons
Icon(
  AppIcons.boardGame,
  size: AppIcons.lg,
  color: AppColors.primary,
)
```

#### 10.1.3 Icon Color Usage

| Icon Type | Color | Ví dụ |
|-----------|-------|--------|
| Primary | `AppColors.primary` | Action icons, nav selected |
| Secondary | `AppColors.secondary` | Cafe-related icons |
| Neutral | `AppColors.textSecondary` | Unselected nav icons |
| Success | `AppColors.success` | Success indicators |
| Error | `AppColors.error` | Error indicators |

#### 10.1.4 AppIcons Class Mapping (BoardVerse)

```dart
// Sử dụng AppIcons class cho consistency
import 'core/theme/app_icons.dart';

// Navigation
AppIcons.explore      // Icons.explore_outlined
AppIcons.booking      // Icons.calendar_month_outlined
AppIcons.tournament   // Icons.emoji_events_outlined
AppIcons.profile      // Icons.account_circle_outlined

// Games
AppIcons.boardGame    // Icons.sports_esports_outlined
AppIcons.cardGame     // Icons.layers_outlined
AppIcons.strategy     // Icons.track_changes
AppIcons.party        // Icons.celebration_outlined

// Actions
AppIcons.search       // Icons.search
AppIcons.filter       // Icons.filter_list
AppIcons.sort         // Icons.sort
AppIcons.add          // Icons.add_circle_outlined
AppIcons.edit         // Icons.edit_outlined
AppIcons.delete       // Icons.delete_outline
AppIcons.share        // Icons.share_outlined

// Status
AppIcons.available    // Icons.check_circle_outline
AppIcons.busy         // Icons.cancel_outlined
AppIcons.pending      // Icons.schedule

// Users & Social
AppIcons.users        // Icons.group_outlined
AppIcons.rating       // Icons.star_outline
AppIcons.karma        // Icons.local_fire_department_outlined
AppIcons.elo          // Icons.bolt

// Cafe
AppIcons.cafe         // Icons.store_outlined
AppIcons.location     // Icons.location_on_outlined
AppIcons.phone        // Icons.phone_outlined
AppIcons.schedule     // Icons.calendar_today_outlined

// Booking
AppIcons.book         // Icons.event_available_outlined
AppIcons.cancelBooking // Icons.close
AppIcons.confirmBooking // Icons.check

// Media
AppIcons.camera       // Icons.camera_alt_outlined
AppIcons.qrScan       // Icons.qr_code_scanner
AppIcons.image        // Icons.image_outlined
```

#### 10.1.5 Icon Usage Guidelines

| Quy tắc | Mô tả |
|---------|--------|
| **Ưu tiên Outlined** | Dùng `_outlined` suffix cho consistency |
| **Size nhất quán** | Sử dụng AppIcons size constants |
| **Color theo semantic** | Icon màu nên phản ánh trạng thái |
| **Touch target ≥48px** | Nếu icon là tappable, wrap trong padding |

#### 10.1.6 Material Icons Reference

Xem thêm tại: https://fonts.google.com/icons

Icons được nhóm theo:
- **Navigation**: back, forward, menu, close, more_vert
- **Action**: add, edit, delete, share, copy, refresh
- **Communication**: email, chat, notifications
- **Content**: location, calendar, schedule, clock
- **Device**: camera, qr_code_scanner, videcam
- **Maps**: location_on, directions, store
- **Social**: person, group, star, favorite
- **Status**: check_circle, error, warning, info
- **Toggle**: visibility, lock, dark_mode

---

## 11. Implementation Guide

### 9.1 File Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart              # Main theme definition
│   │   ├── app_colors.dart             # Color constants
│   │   ├── app_typography.dart        # Text styles
│   │   ├── app_spacing.dart           # Spacing constants
│   │   ├── app_radius.dart            # Border radius
│   │   ├── app_elevation.dart         # Shadows
│   │   ├── app_shimmer.dart           # Shimmer colors & widgets
│   │   ├── app_icons.dart             # Material icon mapping
│   │   └── app_colors_dark.dart       # Dark mode colors
│   └── ...
├── widgets/
│   └── shimmer/
│       ├── shimmer_box.dart
│       ├── shimmer_card.dart
│       └── shimmer_list_item.dart
├── app.dart                            # App widget với theme
└── main.dart                           # Entry point
```

### 11.2 pubspec.yaml - Add Dependencies

```yaml
dependencies:
  # Fonts
  google_fonts: ^6.1.0

  # Loading/Animation
  shimmer: ^3.0.0

  # Material Icons được include sẵn trong Flutter SDK
  # Không cần thêm package gì thêm

flutter:
  uses-material-design: true
```

### 11.3 main.dart - Setup Theme

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoardVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Be Vietnam Pro',
        textTheme: GoogleFonts.beVietnamProTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Be Vietnam Pro',
        textTheme: GoogleFonts.beVietnamProTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

### 11.5 Migration Checklist

- [ ] Thêm packages vào pubspec.yaml:
  - `google_fonts: ^6.1.0`
  - `shimmer: ^3.0.0`
  - **Material Icons**: Đã có sẵn trong Flutter SDK (không cần thêm)
- [ ] Tạo folder `lib/core/theme/`
- [ ] Tạo các file theme:
  - `app_colors.dart` - Brand, semantic, neutral colors
  - `app_typography.dart` - Text styles với Be Vietnam Pro
  - `app_spacing.dart` - 8pt grid spacing system
  - `app_radius.dart` - Border radius scale
  - `app_elevation.dart` - Shadow presets
  - `app_shimmer.dart` - Shimmer colors & widget helpers
  - `app_icons.dart` - Lucide icon mapping
  - `app_colors_dark.dart` - Dark mode colors
  - `app_theme.dart` - Main theme definition
- [ ] Tạo folder `lib/widgets/shimmer/` với các shimmer widgets
- [ ] Cập nhật `main.dart` để sử dụng theme mới
- [ ] Thay thế tất cả Material Icons bằng Lucide Icons
- [ ] Implement shimmer loading states cho async content
- [ ] Test trên cả light và dark mode
- [ ] Kiểm tra contrast ratio cho accessibility (WCAG AA)

---

## Appendix A: Color Palette Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    BRAND COLORS                             │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   Primary    │  Secondary   │   Accent     │   Neutrals     │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #E65100      │ #00897B      │ #FFD600      │ #FFFFFF        │
│ Deep Orange  │ Teal         │ Amber        │ White          │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #FF9E40      │ #4EBAAA      │ #FFFFFF52    │ #FAFAFA        │
│ Light Orange │ Light Teal   │ Light Amber  │ Background     │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #AC1900      │ #005B4F      │ #C7A500      │ #F5F5F5        │
│ Dark Orange  │ Dark Teal    │ Dark Amber   │ Surface        │
└──────────────┴──────────────┴──────────────┴────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    SEMANTIC COLORS                           │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   Success    │    Error     │   Warning    │     Info       │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #00C853      │ #FF1744      │ #FFAB00     │ #2979FF        │
│ Green        │ Red          │ Amber       │ Blue           │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

## Appendix B: Typography Scale Visual

```
Display Large    57px ████████████████████████████████
Display Medium   45px ████████████████████████████
Display Small    36px ████████████████████████
─────────────────────────────────────────────────
Headline Large   32px █████████████████████
Headline Medium  28px ███████████████████
Headline Small   24px █████████████████
─────────────────────────────────────────────────
Title Large      22px ██████████████
Title Medium     16px ██████████
Title Small      14px █████████
─────────────────────────────────────────────────
Body Large       16px ██████████
Body Medium      14px █████████
Body Small       12px ████████
─────────────────────────────────────────────────
Label Large      14px █████████
Label Medium     12px ████████
Label Small      11px ███████
```

---

*Document created for BoardVerse Mobile - Design System v1.0*
