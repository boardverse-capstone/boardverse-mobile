# BoardVerse Mobile - Design System Documentation

> **Document Version**: 1.2
> **Last Updated**: 2026-08-03
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
8. [Card Patterns](#8-card-patterns)
9. [Button Styles](#9-button-styles)
10. [Layout Patterns](#10-layout-patterns)
11. [Animation & Interactions](#11-animation--interactions)
12. [Common Widgets](#12-common-widgets)
13. [Dark Mode](#13-dark-mode)
14. [Animation & Loading States](#14-animation--loading-states)
15. [Icons System](#15-icons-system)
16. [Design Principles](#16-design-principles)
17. [Implementation Guide](#17-implementation-guide)

---

## 1. Tổng quan

BoardVerse là nền tảng kết nối người yêu board game với các quán cafe board game. Design system này hướng đến:

- **Gamification**: Tạo cảm giác vui vẻ, năng động cho trải nghiệm game
- **Warm & Cozy**: Không khí ấm cúng như đang ngồi ở quán cafe
- **Trust & Clarity**: Rõ ràng, dễ hiểu cho các tác vụ booking và payment
- **Vietnamese-first**: Tối ưu cho tiếng Việt với font Be Vietnam Pro
- **Modern Mobile**: UI theo phong cách Modern Vietnamese Mobile với gradient CTAs, magazine cover aesthetics

---

## 2. Design Philosophy

### 2.1 Core Values

| Value | Mô tả | Ứng dụng |
|-------|-------|----------|
| **Năng động** | Game-like, engaging | Animations, badges, progress indicators |
| **Ấm cúng** | Cozy, welcoming | Border radius lớn, warm colors, soft shadows |
| **Đáng tin** | Trustworthy, clear | Consistent patterns, clear hierarchy |
| **Dễ tiếp cận** | Accessible, inclusive | Đủ contrast, touch targets ≥48px |
| **Thu hút** | Attention-grabbing | Gradient CTAs, shadow glows, press animations |

### 2.2 Visual Identity

- **Primary Color Direction**: Deep Orange (#E65100) - năng động, game-like
- **Secondary Color**: Teal (#00897B) - cafe vibes, trust
- **Accent**: Amber (#FFD600) - highlights, points, badges
- **Style**: Modern Vietnamese Mobile - kết hợp Material Design 3 + Magazine Cover + Gradient CTAs

### 2.3 Design Influences

```
┌─────────────────────────────────────────────────────────────┐
│                   BoardVerse Style DNA                        │
├─────────────────────────────────────────────────────────────┤
│  Material Design 3    │  Magazine Cover     │  Gaming UI    │
│  (Foundations)       │  (Aesthetics)       │  (Energy)     │
├──────────────────────┼─────────────────────┼───────────────┤
│  • 8pt Grid          │  • Hero Images      │  • Gradients  │
│  • ColorScheme        │  • Gradient Overlay│  • Glow Shadow│
│  • Elevation          │  • Badges @ Corners │  • Press Feed │
│  • Surface Tones     │  • Typography Scale │  • Animations │
└─────────────────────────────────────────────────────────────┘
```

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
  static const Color surfaceContainerHighest = Color(0xFFE8E8E8);  // Shimmer base

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);    // Main text - slightly softer than black
  static const Color textSecondary = Color(0xFF5C5C5C);   // Subtitles, hints
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF212121);

  // Borders & Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFFE65100);
  static const Color outlineVariant = Color(0xFFE0E0E0);
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
  static const Color surfaceContainerHighest = Color(0xFF2C2C2C);  // Shimmer base

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
  static const Color outlineVariant = Color(0xFF3D3D3D);
  static const Color divider = Color(0xFF2D2D2D);

  // Shadows
  static const Color shadowLight = Color(0x1AFFFFFF);  // rgba(255,255,255,0.10)
  static const Color shadowMedium = Color(0x33FFFFFF); // rgba(255,255,255,0.20)
  static const Color shadowDark = Color(0x4DFFFFFF);   // rgba(255,255,255,0.30)
}
```

### 3.6 Gradient Presets (CTA & Decorative)

```dart
// Gradient presets cho CTAs và decorative elements
class AppGradients {
  // Primary CTA Gradient - Nổi bật, thu hút
  static LinearGradient primaryCta = LinearGradient(
    colors: [BrandColors.primary, BrandColors.primary.withAlpha(204)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary with glow effect
  static List<BoxShadow> primaryGlow(Color primary) => [
    BoxShadow(
      color: primary.withAlpha(102),  // 40% opacity
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Hero banner gradient (rotating)
  static List<Color> heroBannerColors = [
    BrandColors.primary,
    BrandColors.accent,
    BrandColors.warning,
    BrandColors.primary,
  ];  // 4 second rotation cycle
}
```

### 3.7 Color Usage Guidelines

| Color | Sử dụng cho | Ví dụ |
|-------|------------|-------|
| `primary` | Primary actions, headers, logo, CTAs | Button đặt bàn, AppBar |
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
  static const FontWeight extraBold = FontWeight.w800;    // Section headers, card titles
  static const FontWeight black = FontWeight.w900;        // Display numbers
}
```

### 4.3 Type Scale & Usage

```dart
// Typography Usage Guide - Theo thực tế implementation
class AppTypographyUsage {
  // Headlines - Tiêu đề chính của trang, section headers
  // FontWeight.w800 (extraBold)
  static TextStyle headlineSmall(BuildContext context) => Theme.of(context)
      .textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);

  // Title Medium - Card titles, section headers nhỏ
  // FontWeight.w700 (bold)
  static TextStyle titleMedium(BuildContext context) => Theme.of(context)
      .textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

  // Body Medium - Descriptions với line-height 1.5 cho tiếng Việt
  static TextStyle bodyMedium(BuildContext context) => Theme.of(context)
      .textTheme.bodyMedium?.copyWith(height: 1.5);

  // Label Small - Badges, chips
  // FontWeight.w700 (bold)
  static TextStyle labelSmall(BuildContext context) => Theme.of(context)
      .textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700);

  // Body Small - Meta info, hints
  static TextStyle bodySmall(BuildContext context) => Theme.of(context)
      .textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline);
}
```

### 4.4 Typography Usage Summary

| Style | Font Weight | Usage | Ví dụ |
|-------|------------|-------|-------|
| `headlineSmall` | w800 | Page titles, section headers | "Khám phá Game", "Quán gần đây" |
| `titleMedium` | w700 | Card titles, subtitles | Tên game, tên quán |
| `bodyMedium` | w400 | Descriptions | Mô tả game (line-height: 1.5) |
| `labelSmall` | w700 | Badges, chips | "HOT", "2-4 người" |
| `bodySmall` | w400 | Meta info, hints | "Cập nhật 2 phút trước" |

### 4.5 Vietnamese Typography Best Practices

```dart
// Lưu ý khi sử dụng tiếng Việt:
// 1. Font size tối thiểu cho body text: 14sp (đảm bảo đọc được dấu)
// 2. Line height cho tiếng Việt: 1.4 - 1.6 (vì có dấu trên/dưới)
// 3. Letter spacing: mặc định hoặc slightly negative cho headers
// 4. Tránh all-caps cho tiếng Việt (khó đọc)
// 5. Sử dụng letterSpacing: 0.3 cho badges để tạo khoảng cách đẹp

// Badge style example
Text(
  'HOT',
  style: TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,  // Tạo khoảng cách cho badge
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
  static const double xxs = 4.0;     // 4px - Icon-label gaps, badge internal padding
  static const double xs = 8.0;      // 8px - Default small spacing, between chips
  static const double sm = 12.0;      // 12px - Card internal padding, button gaps
  static const double md = 16.0;      // 16px - Default medium padding, screen padding
  static const double lg = 20.0;      // 20px - Section spacing, larger gaps
  static const double xl = 24.0;      // 24px - Large section spacing
  static const double xxl = 32.0;     // 32px - Extra large spacing
  static const double xxxl = 40.0;    // 40px - Section headers, major sections
  static const double huge = 48.0;     // 48px - Page section spacing (với sticky CTA)

  // Padding presets
  static const EdgeInsets paddingAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

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

  // Grid - 2 columns for game cards
  static const double gridSpacing = 16.0;
  static const int mobileGridColumns = 2;  // Game cards grid
  static const double gridChildAspectRatio = 4 / 5;  // 4:5 ratio for magazine cards
  static const double cafeCardAspectRatio = 80 / 80;  // Square for cafe thumbnails
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
  static const double xxs = 4.0;      // Tags, tiny badges
  static const double xs = 8.0;       // Input fields, small buttons
  static const double sm = 12.0;      // Chips, small badges
  static const double md = 16.0;      // Cards, dialogs (DEFAULT)
  static const double lg = 20.0;      // Large cards, images
  static const double xl = 24.0;      // Bottom sheets
  static const double full = 999.0;    // Pills, avatar circles

  // BorderRadius presets (all corners)
  static const BorderRadius radiusXxs = BorderRadius.all(Radius.circular(xxs));
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusMdAll = BorderRadius.all(Radius.circular(md));  // Alias
  static const BorderRadius radiusSmAll = BorderRadius.all(Radius.circular(sm));  // Alias
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));

  // Top-only radius (for bottom sheets, sheets)
  static BorderRadius radiusTopOnly({double? custom}) => BorderRadius.only(
    topLeft: Radius.circular(custom ?? lg),
    topRight: Radius.circular(custom ?? lg),
  );

  static BorderRadius radiusTopXl() => BorderRadius.only(
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

### 7.1 Primary Button (FilledButton)

```dart
// Primary Button - Standard Material filled button
FilledButton.icon(
  icon: const Icon(Icons.icon),
  label: const Text('Button'),
  style: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.radiusMdAll,
    ),
  ),
  onPressed: onPressed,
)
```

### 7.2 Secondary Button (OutlinedButton)

```dart
// Secondary Button - Dùng cho cancel, back
OutlinedButton.icon(
  icon: const Icon(Icons.icon, size: 20),
  label: const Text('Button'),
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.radiusMdAll,
    ),
    side: BorderSide(color: theme.colorScheme.outlineVariant),
  ),
  onPressed: onPressed,
)
```

### 7.3 Text Button (TextButton)

```dart
// Text Button - Dùng cho links
TextButton.icon(
  icon: const Icon(Icons.swap_horiz, size: AppSpacing.md + 2),
  label: const Text('Action'),
  onPressed: onPressed,
)
```

### 7.4 Cards

```dart
// Game Card - Xem thêm Section 8 Card Patterns
Card(
  elevation: AppElevation.sm,
  shape: RoundedRectangleBorder(
    borderRadius: AppRadius.radiusMd,
  ),
  clipBehavior: Clip.antiAlias,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Image với aspect ratio 4:5
      AspectRatio(
        aspectRatio: 4 / 5,
        child: Image.network(...),
      ),
      Padding(
        padding: AppSpacing.paddingAllMd,
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

### 7.5 Text Input Fields

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

### 7.6 Chips/Tags

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

### 7.7 Bottom Navigation Bar

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

### 7.8 Empty States

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

## 8. Card Patterns

### 8.1 Board Game Card (Magazine Cover Pattern)

Card kiểu magazine cover với hero image chiếm gần hết card, gradient overlays để hiển thị badges và text.

```
┌─────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← Hero image (4:5 ratio = 80% card height)
│ ▓▓▓[HOT]    ★4.5▓▓ │  ← Top gradient (35% height) + badges
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │  ← Image content
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ╔═══════════════════╗
│ ║ Game Name          ║  ← Bottom gradient (text safe zone)
│ ║ 🎉 Party • 2-6 👤 ║  ← Meta info
│ ╚═══════════════════╝
└─────────────────────┘
```

```dart
// Board Game Card - Magazine Cover Pattern
class BoardGameCard extends StatelessWidget {
  final BoardGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusMd,
          boxShadow: AppElevation.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.radiusMd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Image (4:5 aspect ratio)
              Image.network(
                game.imageUrl,
                fit: BoxFit.cover,
              ),

              // Top Gradient (for badges area)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.width * 0.4 * 0.35,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55000000),  // 35% black at top
                        Color(0x00000000),  // Transparent at bottom
                      ],
                    ),
                  ),
                ),
              ),

              // Badges at corners
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: _HotBadge(),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _RatingBadge(rating: game.rating),
              ),

              // Category pill (top-left below hot badge)
              Positioned(
                top: AppSpacing.sm + 28 + AppSpacing.xs,
                left: AppSpacing.sm,
                child: _CategoryPill(category: game.category),
              ),

              // Bottom Gradient (for text area)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.width * 0.4 * 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),   // Transparent at top
                        Color(0xEE000000),   // 90% black at bottom
                      ],
                    ),
                  ),
                ),
              ),

              // Text content (bottom)
              Positioned(
                bottom: AppSpacing.sm,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.celebration, size: 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${game.category} • ${game.minPlayers}-${game.maxPlayers} người',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Grid Layout:**
```dart
SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: AppSpacing.md,
    childAspectRatio: 4 / 5,  // Magazine cover ratio
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) => BoardGameCard(
      game: games[index],
      onTap: () => navigateToDetail(games[index]),
    ),
    childCount: games.length,
  ),
)
```

### 8.2 Cafe Card (Horizontal Info Card)

Card ngang cho danh sách cafe với thumbnail, thông tin cơ bản và trạng thái.

```
┌────────────────────────────────────────┐
│ ┌──────┐  Name                   [→]   │
│ │ img  │  📍 1.2 km                     │
│ │ 80x80│  ⭐ 4.5 (120)                 │
│ └──────┘  🪑 5/10 bàn trống            │
│           💰 Cọc 50k                    │
└────────────────────────────────────────┘
```

```dart
// Cafe Card - Horizontal Info Pattern
class CafeCard extends StatelessWidget {
  final Cafe cafe;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withAlpha(102),  // 40% opacity
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),  // 5% opacity
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusMd,
          child: Padding(
            padding: AppSpacing.paddingAllSm,
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: AppRadius.radiusXs,
                  child: Image.network(
                    cafe.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        cafe.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),

                      // Distance + Rating
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            '1.2 km',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '4.5 (120)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Availability bar
                      _AvailabilityBar(available: 5, total: 10),

                      // Deposit badge
                      if (cafe.depositAmount > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _DepositPill(amount: cafe.depositAmount),
                      ],
                    ],
                  ),
                ),

                // Arrow indicator
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 8.3 Section Card Pattern

Card bao quanh một section với title header.

```dart
// Section Card - Dùng trong LobbyConfigPage
Card(
  child: Padding(
    padding: AppSpacing.paddingAllMd,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,  // Section content
      ],
    ),
  ),
)
```

---

## 9. Button Styles

### 9.1 Gradient CTA Button (Primary - Nổi bật)

Button CTA chính với gradient, glow shadow và layout row icon+text.

```dart
// Gradient CTA Button - Thu hút, nổi bật
class GradientCtaButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onPressed;

  const GradientCtaButton({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(204),  // 80% opacity
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(102),  // 40% opacity
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,  // ~20px vertical
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),  // 20% white
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withAlpha(217),  // 85% white
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Usage Example:**
```dart
GradientCtaButton(
  label: 'Đặt chỗ ngay',
  subtitle: 'Chơi Catan',
  icon: Icons.calendar_today_rounded,
  onPressed: () => navigateToBooking(game),
)
```

### 9.2 Filter Button with Badge

```dart
// Filter button với badge hiển thị số filter đang active
Material(
  color: theme.colorScheme.primaryContainer,
  borderRadius: AppRadius.radiusSmAll,
  child: InkWell(
    onTap: () => _showFilterDrawer(context),
    borderRadius: AppRadius.radiusSmAll,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Badge(
        backgroundColor: theme.colorScheme.primary,
        label: Text('3'),  // Số filter active
        isLabelVisible: hasActiveFilters,  // Chỉ hiện khi có filter
        child: Icon(
          Icons.tune,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    ),
  ),
)
```

---

## 10. Layout Patterns

### 10.1 Page Structure với Sticky CTA

```
┌────────────────────────────────────┐
│ SliverAppBar (collapsible)         │
├────────────────────────────────────┤
│ Search Bar + Filter Button         │
├────────────────────────────────────┤
│ Quick Filter Chips (horizontal)    │
├────────────────────────────────────┤
│ Featured Section                   │
├────────────────────────────────────┤
│ ┌──────┬──────┐                   │
│ │ Card │ Card │  ← 2-column grid  │
│ ├──────┼──────┤                   │
│ │ Card │ Card │                   │
│ └──────┴──────┘                   │
│                                    │
│      ... more content ...          │
│                                    │
│ ═══════════════════════════════════│
│ [  Gradient Overlay Fade  ]        │
│ [    🗓️ Đặt chỗ ngay      → ]     │  ← Sticky CTA
└────────────────────────────────────┘
```

### 10.2 Sticky Bottom CTA Pattern

```dart
// Sticky bottom CTA với gradient overlay fade
Stack(
  children: [
    // Scrollable content
    CustomScrollView(
      slivers: [
        // ... page content
      ],
    ),

    // Sticky CTA
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,  // Increased padding
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              surface.withAlpha(242),  // 95% opacity
              surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),  // 15% opacity
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,  // Only bottom safe area
          child: GradientCtaButton(
            label: 'Đặt chỗ ngay',
            subtitle: 'Chơi ${game.name}',
            icon: Icons.calendar_today_rounded,
            onPressed: onBook,
          ),
        ),
      ),
    ),
  ],
)
```

### 10.3 Quick Filter Chips Row

```dart
// Horizontal scrollable filter chips
SizedBox(
  height: 40,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
    itemCount: categories.length,
    separatorBuilder: (_, __) => SizedBox(width: AppSpacing.xs),
    itemBuilder: (context, index) {
      final category = categories[index];
      return QuickFilterChip(
        label: category.name,
        icon: category.icon,
        selected: selectedCategory == category,
        onTap: () => onSelectCategory(category),
      );
    },
  ),
)
```

### 10.4 Filter Bottom Sheet Pattern

```dart
// Draggable bottom sheet cho filter options
DraggableScrollableSheet(
  initialChildSize: 0.6,  // 60% screen height
  minChildSize: 0.4,      // Minimum 40%
  maxChildSize: 0.92,     // Maximum 92%
  snap: true,
  snapSizes: const [0.6, 0.92],
  builder: (context, scrollController) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Filter content
        Expanded(
          child: ListView(
            controller: scrollController,
            children: [
              // Filter sections
            ],
          ),
        ),
        // Apply/Clear buttons
      ],
    ),
  ),
)
```

---

## 11. Animation & Interactions

### 11.1 Press Scale Animation

Mọi card và button đều có press feedback với scale animation.

```dart
// Press animation controller - 140ms, scale 0.96
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
```

### 11.2 Section Header Underline Animation

Animation gradient line xuất hiện từ trái sang phải.

```dart
// Section header với animated underline
class AnimatedSectionHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  State<AnimatedSectionHeader> createState() => _AnimatedSectionHeaderState();
}

class _AnimatedSectionHeaderState extends State<AnimatedSectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _widthAnimation = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    );
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),

            // Animated underline
            AnimatedBuilder(
              animation: _widthAnimation,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Background line
                    Container(
                      width: constraints.maxWidth,
                      height: 2,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    // Animated gradient line
                    Container(
                      width: constraints.maxWidth * _widthAnimation.value,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
```

### 11.3 Auto-Scroll Carousel

```dart
// Carousel tự động chuyển sau 5 giây
class AutoScrollCarousel extends StatefulWidget {
  final List<Widget> items;

  @override
  State<AutoScrollCarousel> createState() => _AutoScrollCarouselState();
}

class _AutoScrollCarouselState extends State<AutoScrollCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _autoScrollCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _autoScrollCtrl = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextPage();
        }
      });
    _autoScrollCtrl.forward();
  }

  void _goToNextPage() {
    _autoScrollCtrl.reset();
    final nextPage = (_currentPage + 1) % widget.items.length;
    _pageController.animateToPage(
      nextPage,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = nextPage);
    _autoScrollCtrl.forward();
  }

  // Side items scale/opacity effect
  Widget _buildItem(int index) {
    final isCurrentPage = index == _currentPage;
    final distance = (index - _currentPage).abs();

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double scale = 1 - (distance * 0.06).clamp(0.0, 0.06);
        double opacity = 1 - (distance * 0.35).clamp(0.0, 0.35);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: widget.items[index],
    );
  }
}
```

### 11.4 Filter Selection Animation

```dart
// Filter option với animated selection
class FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.radiusSmAll,
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected ? AppElevation.shadowXs : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusSmAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const SizedBox(width: AppSpacing.xs),
                AnimatedScale(
                  scale: isSelected ? 1 : 0,
                  duration: Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 11.5 Animation Timing Summary

| Animation | Duration | Curve | Usage |
|-----------|----------|-------|-------|
| Press scale | 140ms | easeOut | Cards, buttons |
| Section reveal | 800ms | easeInOut | Underline animation |
| Auto-carousel | 5s interval | linear | Featured banners |
| Page transition | 300ms | easeInOut | Carousel page change |
| Filter select | 180ms | easeOutBack | Checkmarks, selections |
| Container color | 180ms | easeOut | Selection state changes |

---

## 12. Common Widgets

### 12.1 Chips & Badges

#### QuickFilterChip
```dart
// Gradient background when selected, scale animation on tap
class QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [primary, primary.withAlpha(204)])
              : null,
          color: selected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### RatingPill
```dart
// Star icon + rating number
class RatingPill extends StatelessWidget {
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(38),  // 15% opacity
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: AppSpacing.sm, color: AppColors.warning),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### MetaChip
```dart
// Icon + text for compact info
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.sm, color: chipColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: chipColor),
        ),
      ],
    );
  }
}
```

#### DepositPill
```dart
// Shows deposit amount with icon
class DepositPill extends StatelessWidget {
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(153),  // 60% opacity
        borderRadius: AppRadius.radiusXsAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_outlined,
            size: AppSpacing.sm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Cọc ${_formatPrice(amount)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### HotBadge
```dart
// "HOT" badge với warning color
class HotBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.radiusXxsAll,
      ),
      child: Text(
        'HOT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
```

### 12.2 Info Components

#### InfoRow
```dart
// Simple icon + label row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.lg,
          color: iconColor ?? theme.colorScheme.outline,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
```

#### TappableInfoRow
```dart
// Row có thể tap để thực hiện action
class _TappableInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusXs,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: AppSpacing.lg, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
```

#### AvailabilityBar
```dart
// Progress bar hiển thị số bàn trống
class AvailabilityBar extends StatelessWidget {
  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? available / total : 0.0;

    Color barColor;
    if (percentage >= 0.5) {
      barColor = AppColors.success;
    } else if (percentage >= 0.25) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.chair, size: 14, color: theme.colorScheme.outline),
            const SizedBox(width: 4),
            Text(
              '$available/$total bàn trống',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
```

### 12.3 Image Handling

#### SafeNetworkImage
```dart
// Custom wrapper xử lý loading và error states
class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafeNetworkImage({
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (url == null || url!.isEmpty) {
      return _PlaceholderImage(width: width, height: height);
    }

    return Image.network(
      url!,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _LoadingPlaceholder(width: width, height: height);
      },
      errorBuilder: (context, error, stackTrace) {
        return _PlaceholderImage(width: width, height: height);
      },
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.extension,
        size: AppSpacing.xxl,
        color: theme.colorScheme.outline,
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
```

### 12.4 Empty & Error States

#### EmptyBoardGameState
```dart
// Empty state với illustration, message và optional CTA
class EmptyBoardGameState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration (SVG hoặc custom painted widget)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(76),  // 30%
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.extension_off_outlined,
                size: 80,
                color: theme.colorScheme.primary.withAlpha(128),  // 50%
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional CTA
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                icon: Icon(actionIcon ?? Icons.refresh),
                label: Text(actionLabel ?? 'Thử lại'),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 12.5 Skeleton Loading

#### GameSkeleton
```dart
// Skeleton placeholder cho game card
class GameSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surface,
              child: Container(color: Colors.white),
            ),
          ),

          // Text skeleton
          Padding(
            padding: AppSpacing.paddingAllMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: AppSpacing.xs),
                ShimmerBox(
                  width: 100,
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

---

## 13. Dark Mode

### 13.1 Dark Mode Implementation

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

### 13.2 Dark Mode Color Adjustments

**Nguyên tắc:**
1. Giữ primary/secondary colors tương tự light theme (để nhận diện thương hiệu)
2. Tăng lightness cho text trên dark backgrounds
3. Giảm contrast mạnh để tránh mỏi mắt
4. Background nên là `#121212` hoặc `#1E1E1E` (Material Dark guidelines)

---

## 14. Animation & Loading States

### 14.1 Shimmer Loading (Skeleton)

**Package:** `shimmer: ^3.0.0`

#### Shimmer Colors

```dart
// Shimmer colors cho light mode
class ShimmerColors {
  static const Color baseColor = Color(0xFFE0E0E0);      // #E0E0E0 - Màu nền shimmer
  static const Color highlightColor = Color(0xFFF5F5F5);  // #F5F5F5 - Màu highlight
}

// Shimmer colors cho dark mode
class ShimmerColorsDark {
  static const Color baseColor = Color(0xFF2C2C2C);
  static const Color highlightColor = Color(0xFF3D3D3D);
}
```

#### Shimmer Usage Guidelines

| Quy tắc | Mô tả |
|---------|--------|
| **Không animate khi data đã load** | Remove shimmer ngay khi có data |
| **Phù hợp content shape** | Card shimmer → card shape, text shimmer → line shapes |
| **Direction** | Mặc định: horizontal (left → right) |
| **Duration** | ~1500ms per cycle là smooth nhất |

---

## 15. Icons System

### 15.1 Material Icons

Sử dụng Material Icons (Flutter's built-in Icons class) thay vì Lucide Icons vì:
- **Native Flutter**: Không cần package bên ngoài, giảm dependency
- **Stable**: Không có vấn đề tương thích với Flutter SDK mới
- **Consistent**: Luôn được cập nhật cùng Flutter
- **Outlined style**: Ưu tiên dùng icons có suffix `_outlined` để đồng nhất với design

#### Icon Size Guidelines

```dart
class AppIconSizes {
  static const double xs = 12.0;   // Inline với text nhỏ
  static const double sm = 16.0;   // Chips, small labels
  static const double md = 20.0;   // Default icon size
  static const double lg = 24.0;   // Navigation, featured
  static const double xl = 32.0;   // Empty state icons
  static const double xxl = 48.0;  // Large decorative icons
}
```

### 15.2 Icon Usage Guidelines

| Quy tắc | Mô tả |
|---------|--------|
| **Ưu tiên Outlined** | Dùng `_outlined` suffix cho consistency |
| **Size nhất quán** | Sử dụng AppIcons size constants |
| **Color theo semantic** | Icon màu nên phản ánh trạng thái |
| **Touch target ≥48px** | Nếu icon là tappable, wrap trong padding |

---

## 16. Design Principles

### 16.1 Tổng hợp Design Principles

```
┌─────────────────────────────────────────────────────────────────┐
│                    BOARDVERSE DESIGN PRINCIPLES                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. CONSISTENCY          - 8pt grid, defined tokens             │
│  2. VISUAL HIERARCHY     - Font weights (w800→w500)             │
│  3. FEEDBACK             - Mọi interaction có visual response  │
│  4. BREATHING ROOM       - Padding dồi dào, không crowded        │
│  5. READABILITY          - Gradient overlays bảo vệ text        │
│  6. STATE HANDLING       - Loading/error/empty/success states    │
│  7. TOUCH TARGETS        - Tối thiểu 48x48px                    │
│  8. ACCESSIBILITY        - Color contrast, screen reader        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 16.2 Áp dụng cho Screen mới

Khi tạo screen mới, checklist:

- [ ] Sử dụng `AppSpacing` tokens cho spacing
- [ ] Sử dụng `AppRadius` cho border radius
- [ ] Dùng `theme.colorScheme.primary` thay vì hardcode màu
- [ ] Board game cards: Hero image 4:5 ratio, gradient overlays
- [ ] Info cards: Horizontal layout với image thumbnail
- [ ] CTAs: Gradient với shadow glow
- [ ] Page structure: SliverAppBar → Search/Filter → Content → Sticky CTA
- [ ] Thêm press animation (scale 0.96) cho cards/buttons
- [ ] Xử lý loading/error/empty states
- [ ] Safe area cho sticky elements

### 16.3 Common Mistakes to Avoid

```dart
// ❌ Bad: Hardcoded colors
Container(color: Color(0xFFE65100))

// ✅ Good: Use theme
Container(color: theme.colorScheme.primary)

// ❌ Bad: Random spacing values
padding: EdgeInsets.all(17)

// ✅ Good: Use spacing tokens
padding: EdgeInsets.all(AppSpacing.md)

// ❌ Bad: Magic numbers for radius
borderRadius: BorderRadius.circular(15)

// ✅ Good: Use radius tokens
borderRadius: AppRadius.radiusMd

// ❌ Bad: No loading state
// [Show empty container while loading]

// ✅ Good: Shimmer loading state
// [Show ShimmerBox/Skeleton while loading]
```

---

## 17. Implementation Guide

### 17.1 File Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart              # Main theme definition
│   │   ├── app_colors.dart             # Color constants
│   │   ├── app_typography.dart          # Text styles
│   │   ├── app_spacing.dart            # Spacing constants
│   │   ├── app_radius.dart             # Border radius
│   │   ├── app_elevation.dart          # Shadows
│   │   ├── app_shimmer.dart            # Shimmer colors & widgets
│   │   ├── app_icons.dart              # Material icon mapping
│   │   └── app_colors_dark.dart        # Dark mode colors
│   └── ...
├── widgets/
│   ├── cards/
│   │   ├── board_game_card.dart
│   │   └── cafe_card.dart
│   ├── chips/
│   │   ├── quick_filter_chip.dart
│   │   ├── rating_pill.dart
│   │   ├── meta_chip.dart
│   │   └── deposit_pill.dart
│   ├── buttons/
│   │   └── gradient_cta_button.dart
│   ├── empty/
│   │   └── empty_board_game_state.dart
│   └── shimmer/
│       ├── shimmer_box.dart
│       ├── shimmer_card.dart
│       └── shimmer_list_item.dart
├── app.dart                            # App widget với theme
└── main.dart                           # Entry point
```

### 17.2 pubspec.yaml - Add Dependencies

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

### 17.3 Migration Checklist

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
  - `app_icons.dart` - Material icon mapping
  - `app_colors_dark.dart` - Dark mode colors
  - `app_theme.dart` - Main theme definition
- [ ] Tạo folder `lib/widgets/` với các reusable widgets
- [ ] Cập nhật `main.dart` để sử dụng theme mới
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

## Appendix B: Spacing Quick Reference

```
xxs (4px)  ─┬─ Icon-label gaps, badge padding
xs  (8px)  ─├─ Between chips, related elements
sm  (12px) ─├─ Card padding, button gaps
md  (16px) ─├─ Default padding, screen margins  ← MOST USED
lg  (20px) ─├─ Section spacing
xl  (24px) ─├─ Large section gaps
xxl (32px) ─├─ Extra large spacing
xxxl(40px) ─┴─ Section headers
huge(48px) ─┴─ Page sections (với sticky CTA)
```

## Appendix C: Border Radius Quick Reference

```
xxs (4px)  ─┬─ Tags, tiny badges
xs  (8px)  ─├─ Input fields, small buttons
sm  (12px) ─├─ Chips, small badges        ← FILTER CHIPS
md  (16px) ─├─ Cards, dialogs             ← DEFAULT CARDS
lg  (20px) ─├─ Large cards, images        ← BOARD GAME CARDS
xl  (24px) ─┴─ Bottom sheets
full(999px)─┴─ Pills, avatar circles
```

## Appendix D: Typography Scale

```
Display Large    57px ████████████████████████████████
Display Medium   45px ████████████████████████████
Display Small    36px ████████████████████████
─────────────────────────────────────────────────
Headline Large   32px █████████████████████
Headline Medium  28px ███████████████████
Headline Small   24px █████████████████   ← w800
─────────────────────────────────────────────────
Title Large      22px ██████████████
Title Medium     16px ██████████         ← w700
Title Small      14px █████████
─────────────────────────────────────────────────
Body Large       16px ██████████         ← height: 1.5
Body Medium      14px █████████
Body Small       12px ████████
─────────────────────────────────────────────────
Label Large      14px █████████
Label Medium     12px ████████
Label Small      11px ███████
```

---

*Document created for BoardVerse Mobile - Design System v1.2*
*Last Updated: 2026-08-03*
