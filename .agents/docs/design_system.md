# BoardVerse Mobile - Design System Documentation

> **Document Version**: 4.0
> **Last Updated**: 2026-08-07
> **Target Platform**: Mobile (iOS & Android)
> **Design Style**: Neo-Brutalism
> **Primary Language**: Tiếng Việt (Vietnamese)

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Design Philosophy - Neo-Brutalism](#2-design-philosophy---neo-brutalism)
3. [Color System](#3-color-system)
4. [Neo-Brutalism Design Tokens](#4-neo-brutalism-design-tokens)
5. [Typography System](#5-typography-system)
6. [Spacing & Layout](#6-spacing--layout)
7. [Component Patterns](#7-component-patterns)
8. [Profile Components](#8-profile-components)
9. [Navigation Components](#9-navigation-components)
10. [Tournament Components](#10-tournament-components)
11. [Wallet Components](#11-wallet-components)
12. [Friend Management Components](#12-friend-management-components)
13. [Settings Components](#13-settings-components)
14. [Lobby Management Components](#14-lobby-management-components)
15. [Animation & Interactions](#15-animation--interactions)
16. [State Handling](#16-state-handling)
17. [Implementation Checklist](#17-implementation-checklist)

---

## 1. Tổng quan

BoardVerse là nền tảng kết nối người yêu board game với các quán cafe board game.

### Design Style: Neo-Brutalism

```
┌─────────────────────────────────────────────────────────────┐
│              BOARDVERSE NEO-BRUTALISM DNA                     │
├─────────────────────────────────────────────────────────────┤
│                                                                 │
│  ██ Bold Borders (2-3px)                                      │
│  ██ Hard Offset Shadows (4-6px, NO blur)                      │
│  ██ Vibrant Brand Colors (Rực rỡ, sống động)                  │
│  ██ Sharp Corners (với rounded nhẹ 12-16px)                   │
│  ██ Press Animations (scale 0.9-0.95)                         │
│                                                                 │
└─────────────────────────────────────────────────────────────┘
```

### Design Goals

| Goal | Mô tả |
|------|-------|
| **Vibrant** | Màu sắc rực rỡ, sống động trên cả light và dark mode |
| **Bold** | Borders đậm, shadows rõ ràng, visual impact cao |
| **Functional** | UI dễ đọc, thông tin hiển thị đầy đủ |
| **Modern** | Kết hợp neo-brutalism với mobile-first |
| **Consistent** | Thống nhất trong toàn bộ app |

---

## 2. Design Philosophy - Neo-Brutalism

### 2.1 Core Characteristics

```dart
/// Neo-Brutalism Design Characteristics
class NeoBrutalismDesign {
  // BORDERS - Đậm và rõ ràng
  static const double borderWidth = 2.0;
  static const double borderWidthBold = 3.0;

  // SHADOWS - Hard offset, KHÔNG blur
  static const Offset shadowOffset = Offset(3, 3);
  static const Offset shadowOffsetBold = Offset(5, 5);
  
  // BORDER RADIUS - Nhỏ hơn traditional brutalism
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
}
```

### 2.2 Visual Identity

```
LIGHT MODE (Nền sáng)
┌────────────────────────────────────┐
│ ██ Primary    #FF5722  Deep Orange │
│ ██ Secondary  #00BCD4  Cyan        │
│ ██ Accent    #FFC107  Amber Gold   │
│ ██ Surface   #FFFFFF  Trắng tinh   │
│ ██ Background #FFFBFE Trắng ấm     │
└────────────────────────────────────┘

DARK MODE (Nền tối - KHÔNG quá đen)
┌────────────────────────────────────┐
│ ██ Primary    #FF5722  (Vẫn nổi!)  │
│ ██ Secondary  #00BCD4  (Vẫn sáng!)  │
│ ██ Accent    #FFC107  (Vẫn rực!)   │
│ ██ Surface   #1E1E1E  Dark grey    │
│ ██ Background #121212 Đen mềm      │
└────────────────────────────────────┘
```

---

## 3. Color System

### 3.1 Brand Colors (Primary Palette)

```dart
// Brand Colors - Vibrant cho cả Light & Dark Mode
class AppColors {
  // ========================
  // PRIMARY - CAM (Game Energy)
  // ========================
  
  /// Primary - Vibrant Orange
  /// LIGHT: Sáng rực | DARK: Đậm vừa, vẫn nổi bật
  static const Color primary = Color(0xFFFF5722);      // Deep Orange
  static const Color primaryLight = Color(0xFFFF8A50);  // Cam nhạt
  static const Color primaryDark = Color(0xFFE64A19);   // Cam đậm

  // ========================
  // SECONDARY - XANH DƯƠNG (Trust)
  // ========================
  
  /// Secondary - Deep Cyan
  static const Color secondary = Color(0xFF00BCD4);   
  static const Color secondaryLight = Color(0xFF4DD0E1);
  static const Color secondaryDark = Color(0xFF0097A7);

  // ========================
  // ACCENT - VÀNG (Highlights)
  // ========================
  
  /// Accent - Amber Gold
  static const Color accent = Color(0xFFFFC107);        
  static const Color accentLight = Color(0xFFFFD54F);
  static const Color accentDark = Color(0xFFFFA000);
}
```

### 3.2 Semantic Colors

```dart
  // Success - Xanh lá tươi
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  // Error - Đỏ nổi bật
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  // Warning - Cam vàng
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  // Info - Xanh dương
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);
```

### 3.3 Light Theme Colors

```dart
  // ========================
  // LIGHT THEME - SÁNG VÀ TƯƠI
  // ========================

  /// Background - Trắng ấm (Material 3)
  static const Color background = Color(0xFFFFFBFE);
  
  /// Surface - Trắng tinh (cho cards)
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Surface Variant - Grey nhẹ
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  /// Text (Light mode)
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textTertiary = Color(0xFF79747E);
  static const Color textDisabled = Color(0xFFCAC4D0);

  /// Borders
  static const Color border = Color(0xFFCAC4D0);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE7E0EC);
```

### 3.4 Dark Theme Colors

```dart
  // ========================
  // DARK THEME - ĐẬM VÀ HÀI HÒA
  // ========================

  /// Dark surfaces - KHÔNG quá đen, có depth
  static const Color surfaceDark = Color(0xFF1E1E1E);      // Dark grey
  static const Color surfaceElevatedDark = Color(0xFF2D2D2D);
  static const Color surfaceContainerDark = Color(0xFF252525);
  static const Color backgroundDark = Color(0xFF121212);   // Nền đen mềm

  /// Text (Dark mode)
  static const Color textPrimaryDark = Color(0xFFE6E1E5);
  static const Color textSecondaryDark = Color(0xFFCAC4D0);
  static const Color textTertiaryDark = Color(0xFF938F99);

  /// Borders (Dark mode)
  static const Color borderDark = Color(0xFF49454F);
  static const Color borderDarkAccent = Color(0xFF625B71);
```

### 3.5 Gradients

```dart
  // ========================
  // GRADIENTS - VIBRANT
  // ========================

  /// Gradient Primary - Cam
  static const List<Color> cardGradientOrange = [
    Color(0xFFFF5722),
    Color(0xFFFF8A50),
  ];

  /// Gradient Secondary - Teal
  static const List<Color> cardGradientTeal = [
    Color(0xFF00BCD4),
    Color(0xFF4DD0E1),
  ];

  /// Gradient Accent - Vàng
  static const List<Color> cardGradientAmber = [
    Color(0xFFFFC107),
    Color(0xFFFFD54F),
  ];
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

### 3.7 Color Palette Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    BRAND COLORS                             │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   Primary    │  Secondary   │   Accent     │   Neutrals     │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #FF5722      │ #00BCD4      │ #FFC107     │ #FFFFFF        │
│ Deep Orange  │ Cyan         │ Amber Gold   │ White          │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #FF8A50      │ #4DD0E1      │ #FFD54F     │ #FFFBFE        │
│ Light Orange │ Light Cyan   │ Light Amber │ Background     │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ #E64A19      │ #0097A7      │ #FFA000     │ #1E1E1E        │
│ Dark Orange  │ Dark Cyan    │ Dark Amber  │ Surface Dark   │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

---

## 4. Neo-Brutalism Design Tokens

### 4.1 Theme Class

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Neo-brutalism Design Tokens
class NeoBrutalismTheme {
  NeoBrutalismTheme._();

  // ========================
  // TOKENS
  // ========================
  
  static const double borderWidth = 2.0;
  static const double borderWidthBold = 3.0;
  
  static const Offset shadowOffset = Offset(3, 3);
  static const Offset shadowOffsetBold = Offset(5, 5);

  // ========================
  // BRAND COLORS
  // ========================
  
  static Color get primary => AppColors.primary;
  static Color get primaryLight => AppColors.primaryLight;
  static Color get primaryDark => AppColors.primaryDark;
  
  static Color get secondary => AppColors.secondary;
  static Color get secondaryLight => AppColors.secondaryLight;
  
  static Color get accent => AppColors.accent;
  static Color get accentLight => AppColors.accentLight;
  
  static Color get success => AppColors.success;
  static Color get error => AppColors.error;
  static Color get warning => AppColors.warning;
  static Color get info => AppColors.info;
  
  // ========================
  // THEME COLORS
  // ========================
  
  /// Light mode
  static const Color bgLight = AppColors.background;
  static const Color surfaceLight = AppColors.surface;
  static const Color surfaceWarm = Color(0xFFFFFBF7);
  static const Color borderLight = AppColors.border;
  
  /// Dark mode
  static const Color bgDark = AppColors.backgroundDark;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color surfaceElevatedDark = AppColors.surfaceElevatedDark;
  static const Color borderDark = AppColors.borderDark;
  
  // ========================
  // SHADOWS
  // ========================
  
  /// Light mode - Black shadow với opacity vừa phải
  static List<BoxShadow> lightShadow({bool bold = false, Color? shadowColor}) => [
    BoxShadow(
      color: shadowColor ?? Colors.black.withValues(alpha: 0.5),
      offset: bold ? shadowOffsetBold : shadowOffset,
      blurRadius: 0,  // NO BLUR - Neo-brutalism signature
      spreadRadius: 0,
    ),
  ];
  
  /// Dark mode - Subtle shadow
  static List<BoxShadow> darkShadow({bool bold = false, Color? shadowColor}) => [
    BoxShadow(
      color: shadowColor ?? Colors.black.withValues(alpha: 0.4),
      offset: bold ? const Offset(3, 3) : const Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  // ========================
  // DECORATIONS
  // ========================
  
  /// Light mode decoration
  static BoxDecoration brutalBox({
    Color? backgroundColor,
    Color borderColor = AppColors.border,
    bool bold = false,
    double borderRadius = 16,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: bold ? borderWidthBold : borderWidth,
      ),
      boxShadow: lightShadow(bold: bold, shadowColor: shadowColor),
    );
  }
  
  /// Dark mode decoration
  static BoxDecoration brutalBoxDark({
    Color? backgroundColor,
    Color borderColor = borderDark,
    bool bold = false,
    double borderRadius = 16,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? surfaceDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: bold ? borderWidthBold : borderWidth,
      ),
      boxShadow: darkShadow(bold: bold, shadowColor: shadowColor),
    );
  }

  // ========================
  // CONTEXT HELPERS
  // ========================
  
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? surfaceDark 
        : surfaceLight;
  }
  
  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? bgDark 
        : bgLight;
  }
  
  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? AppColors.textPrimaryDark 
        : AppColors.textPrimary;
  }
  
  static Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? AppColors.textSecondaryDark 
        : AppColors.textSecondary;
  }
  
  /// Main auto decoration - tự chọn light/dark theo context
  static BoxDecoration autoBox(
    BuildContext context, {
    Color? backgroundColor,
    Color? borderColor,
    bool bold = false,
    double borderRadius = 16,
    Color? shadowColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return isDark
        ? brutalBoxDark(
            backgroundColor: backgroundColor,
            borderColor: borderColor ?? borderDark,
            bold: bold,
            borderRadius: borderRadius,
            shadowColor: shadowColor,
          )
        : brutalBox(
            backgroundColor: backgroundColor ?? AppColors.surface,
            borderColor: borderColor ?? AppColors.border,
            bold: bold,
            borderRadius: borderRadius,
            shadowColor: shadowColor,
          );
  }
}
```

---

## 5. Typography System

### 5.1 Font Family: Be Vietnam Pro

- Font tiếng Việt chính thức của Chính phủ Việt Nam
- Hỗ trợ đầy đủ dấu tiếng Việt (ă, â, đ, ê, ô, ơ, ư, ơ)
- Nhiều weights từ Regular đến Bold

### 5.2 Font Weights

```dart
class AppFontWeights {
  static const FontWeight regular = FontWeight.w400;      // Body text
  static const FontWeight medium = FontWeight.w500;       // Medium emphasis
  static const FontWeight semiBold = FontWeight.w600;     // Subtitles, buttons
  static const FontWeight bold = FontWeight.w700;         // Titles
  static const FontWeight extraBold = FontWeight.w800;    // Headers, card titles
  static const FontWeight black = FontWeight.w900;       // Display numbers
}
```

### 5.3 Typography Usage

| Style | Font Weight | Usage | Ví dụ |
|-------|------------|-------|-------|
| `headlineSmall` | w800-900 | Page titles, section headers | "Khám phá Game", "Hồ sơ" |
| `titleLarge/Medium` | w700-800 | Card titles, subtitles | Tên game, tên quán |
| `bodyMedium` | w400 | Descriptions với line-height: 1.5 | Mô tả game |
| `labelSmall` | w700 | Badges, chips | "HOT", "2-4 người" |
| `bodySmall` | w400 | Meta info, hints | "Cập nhật 2 phút trước" |

### 5.4 Vietnamese Typography Best Practices

```dart
// Lưu ý khi sử dụng tiếng Việt:
// 1. Font size tối thiểu cho body text: 14sp
// 2. Line height cho tiếng Việt: 1.4 - 1.6 (vì có dấu trên/dưới)
// 3. Letter spacing: mặc định hoặc slightly negative cho headers
// 4. Tránh all-caps cho tiếng Việt (khó đọc)

// Badge style
Text(
  'VIP',
  style: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  ),
);
```

---

## 6. Spacing & Layout

### 6.1 Spacing Scale (8pt Grid)

```dart
class AppSpacing {
  static const double xxs = 4.0;     // 4px - Icon-label gaps, badge internal
  static const double xs = 8.0;      // 8px - Default small spacing
  static const double sm = 12.0;      // 12px - Card internal padding
  static const double md = 16.0;       // 16px - Default medium padding
  static const double lg = 20.0;      // 20px - Section spacing
  static const double xl = 24.0;      // 24px - Large section spacing
  static const double xxl = 32.0;     // 32px - Extra large spacing
}
```

### 6.2 Screen Layout Guidelines

```dart
class AppLayout {
  // Screen edge padding
  static const double screenHorizontalPadding = 16.0;

  // Card spacing
  static const double cardMargin = 16.0;
  static const double cardPadding = 16.0;
  static const double cardSpacing = 12.0;

  // Grid - 2 columns for game cards
  static const double gridSpacing = 16.0;
  static const int mobileGridColumns = 2;
  static const double gridChildAspectRatio = 4 / 5;  // Magazine cards
}
```

---

## 7. Component Patterns

### 7.1 Neo-Brutalist Card Pattern

```
┌─────────────────────────────┐
│  ╔═══════════════════════╗  │ ← Border 2-3px
│  ║                       ║  │
│  ║      CONTENT          ║  │ ← Padding 16px
│  ║                       ║  │
│  ╚═══════════════════════╝  │
│        ▓▓▓▓▓▓▓▓▓▓▓▓          │ ← Hard shadow 3-5px
└─────────────────────────────┘
```

```dart
// Neo-brutalist Card
Container(
  decoration: NeoBrutalismTheme.autoBox(
    context,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
    shadowColor: AppColors.primary.withValues(alpha: 0.2),
    bold: true,
    borderRadius: 16,
  ),
  child: // Content
)

// With colored border
Container(
  decoration: NeoBrutalismTheme.autoBox(
    context,
    backgroundColor: color.withValues(alpha: 0.1),
    borderColor: color,
    borderRadius: 16,
  ),
)
```

### 7.2 Profile Header Card - VERTICAL LAYOUT

```
┌─────────────────────────────┐
│  👤 Avatar    Username   ✏️ │
│               @handle       │
│               Full Name     │
├─────────────────────────────┤
│  📝 Bio - Full display      │
│     Không giới hạn dòng    │
└─────────────────────────────┘
```

```dart
// Profile Header - Layout dọc
Container(
  decoration: NeoBrutalismTheme.autoBox(
    context,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
    shadowColor: AppColors.primary.withValues(alpha: 0.2),
    bold: true,
    borderRadius: 20,
  ),
  child: Column(
    children: [
      // TOP: Avatar + Info + Edit
      Row(
        children: [
          _AvatarNeo(...),
          Expanded(child: Column(...)),
          _EditButtonNeo(...),
        ],
      ),
      // BOTTOM: Bio (Full display)
      if (hasBio) ...[
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            profile.bio!,
            // KHÔNG maxLines - hiển thị full bio
          ),
        ),
      ],
    ],
  ),
)
```

### 7.3 Profile Stats Card - BIG CARDS

```
┌─────────────────────────────┐
│  🏆 ELO RATING              │
│     1850                    │
│     ⚔️ Master               │
└─────────────────────────────┘
┌───────────┐ ┌───────────┐
│  📊 LVL   │ │  ⭐ KARMA │
│    42     │ │   1250    │
│  🎖️ VET  │ │  🌟 Hero  │
└───────────┘ └───────────┘
```

```dart
// Profile Stat Card - BIG
class ProfileStatCardNeo extends StatelessWidget {
  const ProfileStatCardNeo({
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.subtitle,  // Optional: rank name, trend
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shadowColor: color.withValues(alpha: 0.15),
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Value - BIG
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -1,
            ),
          ),
          
          // Subtitle
          if (subtitle != null)
            Text(subtitle!),
        ],
      ),
    );
  }
}
```

### 7.4 Quick Actions Grid - BIG CARDS

```
┌──────────┐ ┌──────────┐
│    👥    │ │    🏆    │
│ Bạn bè   │ │ Xếp hạng │
└──────────┘ └──────────┘
┌──────────┐ ┌──────────┐
│    💰    │ │    ⚙️    │
│ Ví BVC   │ │ Cài đặt  │
└──────────┘ └──────────┘
```

```dart
// Quick Actions Grid - BIG CARDS 2x2
class QuickActionsGridNeo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,  // Cards cao hơn
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: actions.map((item) => _ActionTileNeo(...)).toList(),
    );
  }
}

class _ActionTileNeo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeoBrutalismTheme.autoBox(
        context,
        backgroundColor: isPressed
            ? accentColor.withValues(alpha: 0.15)
            : (isDark ? AppColors.surfaceDark : AppColors.surface),
        shadowColor: accentColor.withValues(alpha: 0.2),
        borderRadius: 16,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon lớn với neo-brutalist background
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: NeoBrutalismTheme.borderWidth,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
```

### 7.5 Tier Badge

```dart
// Tier Badge - Amber Gold
class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accentDark,
          width: 1.5,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: AppColors.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        tier.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
```

---

## 8. Profile Components

### 8.1 Profile Stats Row - Vertical Layout

```dart
// ProfileStatsRowNeoCompact - BIG CARDS
class ProfileStatsRowNeoCompact extends StatelessWidget {
  const ProfileStatsRowNeoCompact({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ELO Card - CAM (Primary)
        ProfileStatCardNeo(
          label: 'ELO RATING',
          value: '${profile.globalElo}',
          icon: Icons.emoji_events_rounded,
          accentColor: AppColors.primary,
          subtitle: _getEloTitle(profile.globalElo),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Level + Karma - 2 cards ngang
        Row(
          children: [
            Expanded(child: ProfileStatCardNeo(
              label: 'LEVEL',
              value: '${profile.level}',
              icon: AppIcons.level,
              accentColor: AppColors.secondary,
              subtitle: _getLevelTitle(profile.level),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: ProfileStatCardNeo(
              label: 'KARMA',
              value: profile.karmaPoints?.toString() ?? '—',
              icon: AppIcons.karma,
              accentColor: AppColors.success,
              subtitle: _getKarmaTitle(profile.karmaPoints),
            )),
          ],
        ),
      ],
    );
  }
}
```

### 8.2 ELO/Level/Karma Titles

```dart
String _getEloTitle(int elo) {
  if (elo >= 2000) return '⚔️ Master';
  if (elo >= 1800) return '🏆 Diamond';
  if (elo >= 1600) return '💎 Platinum';
  if (elo >= 1400) return '🥇 Gold';
  if (elo >= 1200) return '🥈 Silver';
  return '🥉 Bronze';
}

String _getLevelTitle(int level) {
  if (level >= 50) return '🎖️ Veteran';
  if (level >= 40) return '⭐ Expert';
  if (level >= 30) return '🌟 Advanced';
  if (level >= 20) return '📈 Intermediate';
  if (level >= 10) return '🔰 Beginner';
  return '🆕 Newbie';
}

String _getKarmaTitle(int? karma) {
  if (karma == null) return 'Chưa có';
  if (karma >= 5000) return '✨ Legend';
  if (karma >= 2500) return '🌟 Hero';
  if (karma >= 1000) return '👍 Good';
  if (karma >= 500) return '👤 Member';
  return '🌱 Fresh';
}
```

---

## 9. Navigation Components

### 9.1 Bottom Navigation Bar - Compact

```
┌──────────────────────────────────────────┐
│  🏠    📅    🔍    🏆    👤              │
│ Home  Book  Disco  Tour  Prof            │
└──────────────────────────────────────────┘
```

```dart
// BoardVerseNavBarNeo - Compact để tránh overflow
class BoardVerseNavBarNeo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: isDark
          ? NeoBrutalismTheme.brutalBoxDark(
              backgroundColor: AppColors.surfaceDark,
              borderColor: AppColors.borderDark,
              bold: true,
              borderRadius: 20,
            )
          : NeoBrutalismTheme.brutalBox(
              backgroundColor: AppColors.surface,
              borderColor: AppColors.border,
              bold: true,
              borderRadius: 20,
              shadowColor: AppColors.primary.withValues(alpha: 0.2),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 64 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Row(
            children: [
              for (final tab in NavTab.values)
                Expanded(
                  child: _NavItemNeo(
                    icon: _iconFor(tab),
                    label: tab.label,
                    isSelected: currentIndex == tab.tabIndex,
                    onTap: () => onTabSelected(tab.tabIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemNeo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon với neo-brutalist background khi selected
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
            child: Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : unselectedColor,
            ),
          ),
          const SizedBox(height: 2),
          // Label - nhỏ hơn để tránh overflow
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

---

## 10. Animation & Interactions

### 10.1 Press Scale Animation

```dart
// Press animation - 100ms, scale 0.9
class PressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleValue;  // 0.85 - 0.95

  @override
  State<PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<PressableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  void _onTapDown(TapDownDetails details) => _pressCtrl.forward();
  void _onTapUp(TapUpDetails details) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
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

### 10.2 Animation Timing Summary

| Animation | Duration | Curve | Scale | Usage |
|-----------|----------|-------|-------|-------|
| **Press (Buttons)** | 80-100ms | easeOut | 0.85 | Small buttons |
| **Press (Cards)** | 100ms | easeOut | 0.90-0.95 | Cards, tiles |
| **Nav Icon** | 200ms | easeOut | - | Icon color/size change |
| **Container** | 100ms | easeOut | - | Background color change |

---

## 11. State Handling

### 11.1 Loading States

```dart
// Shimmer Loading cho neo-brutalist cards
class NeoBrutalismShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: NeoBrutalismTheme.borderWidth,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceVariant,
        highlightColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        child: // Skeleton content
      ),
    );
  }
}
```

### 11.2 Empty States

```dart
// Empty state với neo-brutalist styling
class EmptyStateNeo extends StatelessWidget {
  const EmptyStateNeo({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: NeoBrutalismTheme.autoBox(
                context,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: 20,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: theme.textTheme.bodyMedium),
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _NeoButton(...),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 11.3 Error States

```dart
// Error state với retry button
class ErrorStateNeo extends StatelessWidget {
  const ErrorStateNeo({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: NeoBrutalismTheme.autoBox(
                context,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                borderColor: AppColors.error,
                borderRadius: 16,
              ),
              child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Đã xảy ra lỗi', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            _NeoButton(
              label: 'THỬ LẠI',
              icon: Icons.refresh,
              color: AppColors.primary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 12. Implementation Checklist

### 12.1 Áp dụng cho Component mới

Khi tạo component mới, checklist:

- [ ] **Colors**: Sử dụng `AppColors.*` thay vì hardcode
- [ ] **Theme-aware**: Sử dụng `isDark` để check theme
- [ ] **Neo-brutalist decoration**: Dùng `NeoBrutalismTheme.autoBox()` hoặc `brutalBox/brutalBoxDark()`
- [ ] **Spacing**: Dùng `AppSpacing.*` constants
- [ ] **Border radius**: 12-16px cho cards, 8px cho buttons/chips
- [ ] **Shadow**: Dùng `NeoBrutalismTheme.lightShadow()` hoặc `darkShadow()`
- [ ] **Press animation**: Scale 0.85-0.95 cho touch feedback
- [ ] **Text colors**: Dùng `AppColors.textPrimary/textSecondary` hoặc `textPrimaryDark/textSecondaryDark`
- [ ] **Loading states**: Shimmer với neo-brutalist styling
- [ ] **Safe area**: Cho sticky elements và navigation

### 12.2 Common Mistakes

```dart
// ❌ BAD: Hardcoded colors
Container(color: Color(0xFFFF5722))

// ✅ GOOD: Use AppColors
Container(color: AppColors.primary)

// ❌ BAD: Random spacing
padding: EdgeInsets.all(17)

// ✅ GOOD: Use AppSpacing
padding: EdgeInsets.all(AppSpacing.md)

// ❌ BAD: Blur shadow (not neo-brutalist)
BoxShadow(color: Colors.black26, blurRadius: 8)

// ✅ GOOD: Hard shadow (neo-brutalist signature)
BoxShadow(color: Colors.black54, blurRadius: 0, offset: Offset(3, 3))

// ❌ BAD: No border on dark cards
Container(color: Colors.grey[900])

// ✅ GOOD: Border + shadow for neo-brutalist
Container(
  decoration: NeoBrutalismTheme.brutalBoxDark(
    borderColor: AppColors.borderDark,
  ),
)
```

### 12.3 File Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart              # Brand, semantic, neutral colors
│   │   ├── neo_brutalism_theme.dart    # Neo-brutalist design tokens
│   │   ├── app_spacing.dart             # 8pt grid spacing
│   │   └── app_icons.dart               # Material icon mapping
│   ├── navigation/
│   │   └── widgets/
│   │       └── board_verse_nav_bar_neo.dart
│   └── widgets/
│       └── shimmer_skeletons.dart
├── features/
│   └── profile/
│       └── presentation/
│           └── widgets/
│               ├── profile_header_card_neo.dart
│               ├── profile_stat_card_neo.dart
│               ├── profile_stats_row_neo.dart
│               ├── quick_actions_card_neo.dart
│               └── location_card_neo.dart
│   ├── tournament/
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── tournament_list_card.dart
│   │           ├── tournament_filter_section.dart
│   │           ├── tournament_status_pill.dart
│   │           ├── tournament_hero.dart
│   │           └── tournament_action_button.dart
│   ├── wallet/
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── balance_card.dart
│   │           ├── transaction_tile.dart
│   │           └── insufficient_balance_dialog.dart
│   └── friend_management/
│       └── presentation/
│           └── widgets/
│               ├── common/
│               │   └── outlined_card.dart
│               ├── shared/
│               │   ├── status_chip.dart
│               │   └── meta_row.dart
│               ├── friend_card.dart
│               ├── friend_request_card.dart
│               ├── user_search_card.dart
│               ├── friend_profile_actions.dart
│               └── common/
│                   ├── avatar_widgets.dart
│                   └── state_widgets.dart
```

---

## 10. Tournament Components

Tournament feature sử dụng Neo-Brutalism với accent color chính là **`AppColors.primary` (Orange)** cho các giải đang diễn ra, kết hợp với các màu status pills đa dạng.

### 10.1 Tournament Status Pills

```dart
// TournamentStatusPill - Hiển thị trạng thái giải đấu
class TournamentStatusPill extends StatelessWidget {
  final TournamentStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      TournamentStatus.upcoming => StatusPalette(
        bg: AppColors.accent,
        fg: AppColors.black,
      ),
      TournamentStatus.ongoing => StatusPalette(
        bg: AppColors.primary,
        fg: AppColors.white,
      ),
      TournamentStatus.registration => StatusPalette(
        bg: AppColors.secondary,
        fg: AppColors.black,
      ),
      TournamentStatus.completed => StatusPalette(
        bg: AppColors.success,
        fg: AppColors.white,
      ),
      TournamentStatus.cancelled => StatusPalette(
        bg: AppColors.error,
        fg: AppColors.white,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: NeoBrutalismTheme.brutalBox(
        color: palette.bg,
        borderColor: isDark ? AppColors.borderDark : AppColors.border,
        shadowColor: isDark ? AppColors.shadowDark : AppColors.shadow,
        borderWidth: 2,
        radius: 8,
        offset: const Offset(2, 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.fg,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
```

### 10.2 Tournament List Card

```dart
// TournamentListCard - Card hiển thị thông tin giải đấu
class TournamentListCard extends StatelessWidget {
  final TournamentEntity tournament;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: NeoBrutalismTheme.brutalBox(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderColor: isDark ? AppColors.borderDark : AppColors.border,
          shadowColor: isDark ? AppColors.shadowDark : AppColors.shadow,
          borderWidth: 3,
          radius: 16,
          offset: const Offset(4, 4),
        ),
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament name (bold, large)
            Text(
              tournament.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            // Date range
            _MetaItem(
              icon: AppIcons.calendar,
              text: DateFormat('dd/MM/yyyy').format(tournament.startDate),
            ),
            // Entry fee + max participants
            Row(
              children: [
                _MetaItem(
                  icon: AppIcons.ticket,
                  text: '${tournament.entryFee} BVC',
                ),
                SizedBox(width: AppSpacing.md),
                _MetaItem(
                  icon: AppIcons.users,
                  text: '${tournament.currentParticipants}/${tournament.maxParticipants}',
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            // Status pill
            TournamentStatusPill(status: tournament.status),
          ],
        ),
      ),
    );
  }
}
```

### 10.3 Tournament Filter Section

```dart
// TournamentFilterSection - Filter chips với press animation
class _FilterChipNeo extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FilterChipNeo> createState() => _FilterChipNeoState();
}

class _FilterChipNeoState extends State<_FilterChipNeo> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.isSelected
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: NeoBrutalismTheme.brutalBox(
            color: bgColor,
            borderColor: widget.isSelected
                ? AppColors.border
                : (isDark ? AppColors.borderDark : AppColors.border),
            borderWidth: 2,
            radius: 12,
            offset: widget.isSelected ? Offset.zero : const Offset(3, 3),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected
                  ? AppColors.white
                  : (isDark ? AppColors.white : AppColors.black),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
```

### 10.4 Tournament Hero

```dart
// TournamentHero - Hero section với gradient và decorative patterns
Container(
  height: 200,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.primary,
        AppColors.primary.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppColors.border,
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        offset: const Offset(4, 4),
        blurRadius: 0,
      ),
    ],
  ),
  child: Stack(
    children: [
      // Decorative circles
      Positioned(
        top: -30,
        right: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Content
      Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TOURNAMENT',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 2,
              ),
            ),
            // ...
          ],
        ),
      ),
    ],
  ),
)
```

---

## 11. Wallet Components

Wallet feature sử dụng Neo-Brutalism với color palette mạnh mẽ, **gradient backgrounds** cho balance card và **icon badges** rõ ràng cho transaction types.

### 11.1 Balance Card

```dart
// BalanceCard - Card hiển thị số dư ví BVC
class BalanceCard extends StatelessWidget {
  final WalletEntity wallet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.primaryDark, AppColors.accentDark]
              : [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadow,
            offset: const Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'SỐ DƯ KHẢ DỤNG',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Amount
          Text(
            '${wallet.balance} BVC',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
          // Held balance (if any)
          if (wallet.heldBalance > 0)
            Text(
              'Đang giữ: ${wallet.heldBalance} BVC',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          SizedBox(height: AppSpacing.md),
          // Top up button
          NeoFilledButton(
            label: 'Nạp tiền',
            icon: AppIcons.plus,
            color: AppColors.white,
            textColor: AppColors.primary,
            onPressed: onTopUpPressed,
          ),
        ],
      ),
    );
  }
}
```

### 11.2 Transaction Tile

```dart
// TransactionTile - Mỗi giao dịch trong lịch sử
class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = transaction.type == TransactionType.deposit ||
        transaction.type == TransactionType.refund;

    // Icon styling theo loại giao dịch
    final iconBgColor = switch (transaction.type) {
      TransactionType.deposit => AppColors.success,
      TransactionType.withdraw => AppColors.error,
      TransactionType.payment => AppColors.primary,
      TransactionType.refund => AppColors.secondary,
      TransactionType.transfer => AppColors.accent,
    };

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.brutalBox(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderColor: isDark ? AppColors.borderDark : AppColors.border,
        borderWidth: 2,
        radius: 12,
        offset: const Offset(3, 3),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Icon(
              isIncome ? AppIcons.arrowDown : AppIcons.arrowUp,
              color: AppColors.white,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isIncome ? '+' : '-'}${transaction.amount} BVC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 11.3 Insufficient Balance Dialog

```dart
// Neo-brutalism dialog với hard shadow
showDialog(
  context: context,
  builder: (_) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: NeoBrutalismTheme.brutalBox(
        color: AppColors.surface,
        borderColor: AppColors.border,
        borderWidth: 3,
        radius: 20,
        offset: const Offset(6, 6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 3),
            ),
            child: Icon(AppIcons.warning, color: AppColors.white, size: 32),
          ),
          SizedBox(height: AppSpacing.md),
          Text('Số dư không đủ', style: titleStyle),
          SizedBox(height: AppSpacing.sm),
          Text('Bạn cần thêm X BVC...', style: bodyStyle),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: NeoOutlineButton(label: 'Hủy', onPressed: () => Navigator.pop(context))),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: NeoFilledButton(label: 'Nạp ngay', onPressed: () {})),
            ],
          ),
        ],
      ),
    ),
  ),
)
```

### 11.4 Topup Page - Package Selection

```dart
// _NeoPackageCard - Card chọn gói nạp tiền
class _NeoPackageCard extends StatelessWidget {
  final TopupPackage package;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : AppColors.surface);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: NeoBrutalismTheme.brutalBox(
        color: bgColor,
        borderColor: isSelected ? AppColors.primary : AppColors.border,
        borderWidth: 3,
        radius: 16,
        offset: isSelected ? Offset.zero : const Offset(4, 4),
      ),
      child: Column(
        children: [
          Text(
            '${package.amount} BVC',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isSelected ? AppColors.white : (isDark ? AppColors.white : AppColors.black),
            ),
          ),
          Text(
            '${package.price.toStringAsFixed(0)}đ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 12. Friend Management Components

Friend Management sử dụng Neo-Brutalism với **OutlinedCard** làm base component chung, và **StatusChip** để hiển thị trạng thái quan hệ.

### 12.1 OutlinedCard (Base Component)

```dart
// OutlinedCard - Component nền tảng cho mọi card trong friend_management
class OutlinedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final Offset shadowOffset;

  const OutlinedCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 3,
    this.radius = 16,
    this.shadowOffset = const Offset(4, 4),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: NeoBrutalismTheme.brutalBox(
        color: backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
        borderColor: borderColor ?? (isDark ? AppColors.borderDark : AppColors.border),
        borderWidth: borderWidth,
        radius: radius,
        offset: shadowOffset,
      ),
      child: child,
    );
  }
}
```

### 12.2 Status Chip

```dart
// StatusChip - Hiển thị trạng thái quan hệ (Friend, Pending, Blocked...)
class StatusChip extends StatelessWidget {
  final FriendshipStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      FriendshipStatus.friends => (
        bg: AppColors.success,
        fg: AppColors.white,
        icon: AppIcons.check,
      ),
      FriendshipStatus.pending => (
        bg: AppColors.accent,
        fg: AppColors.black,
        icon: AppIcons.clock,
      ),
      FriendshipStatus.blocked => (
        bg: AppColors.error,
        fg: AppColors.white,
        icon: AppIcons.ban,
      ),
      FriendshipStatus.none => (
        bg: AppColors.surfaceDark,
        fg: AppColors.white,
        icon: AppIcons.userPlus,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: NeoBrutalismTheme.brutalBox(
        color: palette.bg,
        borderColor: AppColors.border,
        borderWidth: 2,
        radius: 8,
        offset: const Offset(2, 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(palette.icon, size: 12, color: palette.fg),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.fg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 12.3 Friend Card

```dart
// FriendCard - Card hiển thị thông tin bạn bè
class FriendCard extends StatelessWidget {
  final FriendEntity friend;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar with neo border
          NeoAvatar(
            imageUrl: friend.avatarUrl,
            name: friend.displayName,
            size: 56,
            tierColor: friend.tier.color,
          ),
          SizedBox(width: AppSpacing.md),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.displayName, style: boldTitleStyle),
                MetaRow(
                  karma: friend.karma,
                  mutualFriends: friend.mutualFriendsCount,
                ),
                // Activity chip
                if (friend.isOnline)
                  ActivityChip(status: friend.activityStatus),
              ],
            ),
          ),
          // Message button
          NeoIconButton(
            icon: AppIcons.message,
            onPressed: onMessage,
          ),
        ],
      ),
    );
  }
}
```

### 12.4 Friend Profile Actions

```dart
// FriendProfileActions - Nhóm nút hành động trên trang profile bạn bè
class _NeoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: NeoBrutalismTheme.brutalBox(
          color: color,
          borderColor: AppColors.border,
          borderWidth: 2,
          radius: 12,
          offset: const Offset(3, 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.white),
            SizedBox(width: AppSpacing.xs),
            Text(label, style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            )),
          ],
        ),
      ),
    );
  }
}

// Sử dụng:
// _NeoActionButton(icon: AppIcons.message, label: 'Nhắn tin', color: AppColors.primary)
// _NeoActionButton(icon: AppIcons.userMinus, label: 'Hủy kết bạn', color: AppColors.error)
```

### 12.5 Avatar Widgets

```dart
// NeoAvatar - Avatar với colored border theo tier
class NeoAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? tierColor;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final borderColor = tierColor ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsFallback(initials: initials),
              )
            : _InitialsFallback(initials: initials),
      ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String initials;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.white,
        ),
      ),
    );
  }
}
```

### 12.6 State Widgets (Loading, Empty, Error)

```dart
// LoadingWidget - CircularProgressIndicator với neo color
Center(
  child: CircularProgressIndicator(
    color: AppColors.primary,
    strokeWidth: 3,
  ),
)

// EmptyState - Khi list rỗng
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 3),
            ),
            child: Icon(icon, size: 48, color: AppColors.textSecondary),
          ),
          SizedBox(height: AppSpacing.md),
          Text(title, style: titleStyle),
          if (description != null) Text(description!, style: bodyStyle),
        ],
      ),
    );
  }
}

// ErrorRetryView - Khi có lỗi và cho phép retry
class ErrorRetryView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  // ... similar to EmptyState but with retry button
}
```

---

## 13. Settings Components

Settings feature sử dụng Neo-Brutalism đơn giản và sạch sẽ với **section cards** và **settings tiles** rõ ràng.

### 13.1 System Settings Page

```dart
// SystemSettingsPage - Trang cài đặt hệ thống
Scaffold(
  backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
  appBar: AppBar(
    title: Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.w900)),
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
    shape: Border(
      bottom: BorderSide(color: AppColors.border, width: 3),
    ),
  ),
  body: ListView(
    padding: EdgeInsets.all(AppSpacing.md),
    children: [
      // Section header
      Text(
        'GIAO DIỆN',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: AppColors.primary,
        ),
      ),
      SizedBox(height: AppSpacing.sm),
      // Settings card
      OutlinedCard(
        child: Column(
          children: [
            // Theme switcher
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(AppIcons.theme, color: AppColors.white, size: 20),
              ),
              title: Text('Giao diện', style: boldStyle),
              subtitle: Text(currentThemeLabel),
              trailing: Icon(AppIcons.chevronRight),
              onTap: () => _showThemeSwitcher(context),
            ),
            Divider(height: 1, color: AppColors.border),
            // Language switcher
            ListTile(...),
          ],
        ),
      ),
      SizedBox(height: AppSpacing.lg),
      // Another section: Thông báo
      Text('THÔNG BÁO', style: sectionHeaderStyle),
      // ...
    ],
  ),
)
```

### 13.2 Theme Switcher Bottom Sheet

```dart
// ThemeSwitcherSheet - Bottom sheet chọn theme
showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (_) => Container(
    padding: EdgeInsets.all(AppSpacing.lg),
    decoration: NeoBrutalismTheme.brutalBox(
      color: AppColors.surface,
      borderColor: AppColors.border,
      borderWidth: 3,
      radius: 24,
      offset: const Offset(0, -6),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn giao diện', style: titleStyle),
        SizedBox(height: AppSpacing.md),
        // Theme options
        _ThemeOption(
          icon: AppIcons.sun,
          label: 'Sáng',
          isSelected: currentTheme == ThemeMode.light,
          onTap: () => _changeTheme(ThemeMode.light),
        ),
        _ThemeOption(
          icon: AppIcons.moon,
          label: 'Tối',
          isSelected: currentTheme == ThemeMode.dark,
          onTap: () => _changeTheme(ThemeMode.dark),
        ),
        _ThemeOption(
          icon: AppIcons.cog,
          label: 'Theo hệ thống',
          isSelected: currentTheme == ThemeMode.system,
          onTap: () => _changeTheme(ThemeMode.system),
        ),
      ],
    ),
  ),
)
```

### 13.3 Settings Tile Pattern

```dart
// _SettingsTile - Single setting row
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Icon(icon, color: AppColors.white, size: 18),
            ),
            SizedBox(width: AppSpacing.md),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Trailing widget
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
```

---

## 14. Lobby Management Components

Lobby Management là feature phức tạp nhất — quản lý phòng chờ, check-in, mời bạn bè, consensus trận đấu. Neo-brutalism giúp phân biệt rõ ràng các trạng thái qua badges, banners, và action buttons.

### 14.1 Lobby Status Badge

`LobbyStatusBadge` hiển thị trạng thái lobby/reservation. Mỗi variant có cặp màu `bg/fg` riêng biệt:

```dart
// Ví dụ: badge "Phòng đầy" - xanh lá đậm
const _BadgeStyle(
  label: 'Phòng đầy',
  icon: AppIcons.check,
  background: AppColors.success,
  foreground: AppColors.white,
);

// Sử dụng: Container với bold border + hard shadow
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(
    color: style.background,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.border, width: 2),
    boxShadow: [
      BoxShadow(
        color: AppColors.black,
        blurRadius: 0,
        offset: Offset(2, 2),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(style.icon, size: 14, color: style.foreground),
      SizedBox(width: 4),
      Text(style.label, style: TextStyle(
        color: style.foreground,
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 0.3,
      )),
    ],
  ),
)
```

**Bảng trạng thái & màu sắc:**

| Variant | Màu nền | Màu chữ | Icon |
|---------|---------|---------|------|
| recruiting | `AppColors.info` | white | `users` |
| viable | `AppColors.accent` | black | `check` |
| full | `AppColors.success` | white | `check` |
| pendingCafeApproval | `AppColors.warning` | black | `warning` |
| rejectedByCafe | `AppColors.error` | white | `cancelBooking` |
| confirmed | `AppColors.success` | white | `check` |
| checkedIn | `AppColors.success` | white | `location` |
| inProgress | `AppColors.primary` | white | `sports_esports` |
| ratingOpen | `AppColors.accent` | black | `star_outline` |
| closed | `AppColors.textTertiary` | white | `lock` |
| hostCancelled | `AppColors.error` | white | `cancelBooking` |
| timeoutFailed | `AppColors.error` | white | `timer_off` |

### 14.2 Lobby Hero Header

```dart
// Hero header với gradient cam, border đậm, hard shadow
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary, AppColors.primaryLight],
    ),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border, width: 3),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.4),
        blurRadius: 0,
        offset: const Offset(5, 5),
      ),
    ],
  ),
  child: Column(
    children: [
      // Cafe avatar (48x48) + name + countdown timer
      // Stats row: 3 stat cards với icon + value + progress
      // Invite code pill (mono-letter spacing 1.5)
    ],
  ),
)
```

### 14.3 Lobby Player Card & Grid

```dart
// Player card với neo-brutalism borders
Container(
  decoration: BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.4),
        blurRadius: 0,
        offset: const Offset(3, 3),
      ),
    ],
  ),
  padding: EdgeInsets.all(AppSpacing.sm),
  child: Column(
    children: [
      // Avatar 56x56 với colored border (primary cho currentUser)
      // Ready/Host badge ở góc (absolute position)
      // Name (bold 14px)
      // Status chip với màu theo trạng thái (success/accent/tertiary)
    ],
  ),
)
```

### 14.4 Confirmation Status Banner

```dart
// Banner lớn với màu semantic cho từng trạng thái booking
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: cfg.color,  // success / warning / accent / error / info
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border, width: 3),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.4),
        blurRadius: 0,
        offset: const Offset(4, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      // Icon container (white bg + colored icon)
      // Title (bold 15px)
      // Subtitle (13px với alpha 0.9)
    ],
  ),
)
```

### 14.5 Lobby Invite Card

```dart
// Card với gradient header + bordered body
Column(
  children: [
    // Header gradient (primary orange) + avatar + tên + status badge
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
    ),
    // Body: message bubble (yellow accent) + info chips + action buttons
    Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 3),
      ),
    ),
  ],
)
```

### 14.6 Consensus Status Card

Card hiển thị trạng thái đồng thuận kết quả trận đấu với progress bar và submissions list:

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor, width: 3),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.4),
        blurRadius: 0,
        offset: const Offset(4, 4),
      ),
    ],
  ),
  child: Column(
    children: [
      // Header: icon badge + title + StatusChip (awaiting/conflict/finalized)
      // LinearProgressIndicator 10px height với status color
      // Conflict warning (yellow container với border)
      // Submissions list với avatar + outcome chip (win/loss/draw)
    ],
  ),
)
```

### 14.7 Lobby Full Guidance Banner

Banner hướng dẫn khi lobby đã đầy (`Full` status), giúp user biết phải làm gì tiếp:

- **Header**: Icon badge + số thành viên tối đa
- **Progress chip**: Hiển thị `readyCount/totalMembers` (yellow = pendng, green = all ready)
- **Body**: Hướng dẫn tiếp theo (chờ member khác ready / đã đủ / đến quán check-in)
- **Action**: 1-2 nút (`Bấm Sẵn sàng` với primary color, hoặc `Chi tiết` outline)

### 14.8 Lobby Bottom Bar

```dart
// Bottom bar với border-top và hard shadow
Container(
  decoration: BoxDecoration(
    color: surface,
    border: Border(top: BorderSide(color: borderColor, width: 3)),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.3),
        blurRadius: 0,
        offset: const Offset(0, -4),
      ),
    ],
  ),
  child: Row(
    children: [
      // "Rời phòng" (outline, secondary action)
      _NeoOutlineBarButton(label: 'Rời phòng', icon: AppIcons.logout),
      // "Huỷ phòng" (filled error, chỉ host)
      _NeoFilledBarButton(
        label: 'Huỷ phòng',
        icon: AppIcons.cancelBooking,
        color: AppColors.error,
      ),
    ],
  ),
)
```

### 14.9 Lobby Check-In Section

```dart
// Section lớn với border 3px và clear visual hierarchy
Container(
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: isInProgress ? AppColors.primary : AppColors.success,
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.4),
        blurRadius: 0,
        offset: const Offset(4, 4),
      ),
    ],
  ),
  child: Column(
    children: [
      // InProgress banner (gradient orange với live timer)
      // ConfirmationStatusBanner
      // ScheduledTimeCountdown
      // PreCheckinActions (chips wrap)
      // Self-report status chip
      // QR + code (white box với border đậm)
      // Action buttons (Sao chép mã / Hiện QR)
    ],
  ),
)
```

### 14.10 Pre Check-In Actions

Các nút hành động nhanh (Chỉ đường, Gọi quán, Sao chép mã, Đang trên đường, Tôi đã đến, Đặt báo thức):

- **Outline variant**: Background surface, border màu semantic
- **Filled variant**: Background màu semantic, white text
- Tất cả đều có **border 2.5px** + **hard shadow 2,2** khi enabled

### 14.11 Scheduled Time Countdown

```dart
// Countdown với màu thay đổi theo thời gian
Container(
  decoration: BoxDecoration(
    color: color,  // warning (< 30min) / accent (< 2h) / success / tertiary
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderColor, width: 3),
    boxShadow: hardShadow,
  ),
  child: Row(
    children: [
      // Icon alarm/alarm_off (white/black contrast depending on color)
      // Title (12px)
      // Time string (22px bold, tab figures)
      // Subtitle (cafe name)
    ],
  ),
)
```

### 14.12 Members Arrival Checklist

Card cho host view tổng hợp arrival status:

```dart
Container(
  decoration: BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderColor, width: 3),
    boxShadow: hardShadow,
  ),
  child: Column(
    children: [
      // Header: Groups icon badge + "Trạng thái các thành viên"
      // Summary chips: 4 chip đếm số người theo trạng thái
      // Divider
      // Per-member row: avatar + name + status pill
    ],
  ),
)
```

### 14.13 Online Friends List

```dart
// List tile với border 2px + shadow
Material(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(color: borderColor, width: 2),
  ),
  child: Padding(
    child: Row(
      children: [
        // Avatar 48x48 với inline "online" dot góc dưới
        // Name + status (online/in lobby)
        // Action buttons (Mời/Đã mời/Thêm)
      ],
    ),
  ),
)
```

### 14.14 Lobby Ended View

View khi lobby kết thúc (closed/timeout/cancelled/rejected/expired):

- **Status Banner**: Solid color (theo terminal state) + icon + title + subtitle
- **Ended Info Card**: Border 3px + rows với icon badge + label + value
- **Refund Banner**: Container màu `AppColors.success` với border đậm
- **Action Cards**: Border 2.5px màu iconColor + hard shadow khi enabled
- **Confirmation Dialog**: Container với border 3px + hard shadow 6,6

### 14.15 Lobby Countdown Timer

```dart
// Live timer hiển thị MM:SS hoặc HH:MM:SS
Container(
  decoration: BoxDecoration(
    color: AppColors.black.withValues(alpha: 0.3),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppColors.white.withValues(alpha: 0.4),
      width: 2,
    ),
  ),
  child: Row(
    children: [
      Icon(Icons.timer_outlined, color: AppColors.white, size: 14),
      Text(elapsed, style: TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        fontFeatures: [FontFeature.tabularFigures()],
      )),
    ],
  ),
)
```

### 14.16 Invite Code Pill

```dart
// Pill với mono-spaced code
Container(
  decoration: BoxDecoration(
    color: AppColors.white.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: AppColors.white.withValues(alpha: 0.5),
      width: 2,
    ),
  ),
  child: Row(
    children: [
      Icon(AppIcons.userAdd, color: AppColors.white),
      Column(
        children: [
          Text('Mã mời', style: TextStyle(fontSize: 10, fontWeight: 700)),
          Text(code, style: TextStyle(
            fontSize: 16,
            fontWeight: 900,
            letterSpacing: 1.5,
          )),
        ],
      ),
      Icon(AppIcons.copy, color: AppColors.white70),
    ],
  ),
)
```

---

## 15. Animation & Interactions

### 15.1 Press Animation (Standard Pattern)

Mọi nút và chip trong app đều sử dụng cùng một pattern press animation:

```dart
class _NeoPressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
}

class _NeoPressableWidgetState extends State<_NeoPressableWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
```

### 14.2 State Transitions

- **Loading → Loaded**: Fade in 200ms
- **Error → Loaded**: Slide up + Fade in
- **Tab Switch**: Fade transition 150ms

---

---

## Appendix: Quick Reference

### Colors

```
LIGHT MODE                          DARK MODE
────────────────────────────────────────────────────────
primary:      #FF5722  (Orange)     primary:      #FF5722  (Still vibrant!)
secondary:    #00BCD4  (Cyan)       secondary:    #00BCD4  (Still bright!)
accent:       #FFC107  (Amber)      accent:       #FFC107  (Still gold!)
surface:      #FFFFFF              surfaceDark:  #1E1E1E
background:   #FFFBFE              backgroundDark: #121212
border:       #CAC4D0              borderDark:   #49454F
textPrimary:  #1C1B1F              textPrimaryDark: #E6E1E5
```

### Spacing

```
xxs (4px)  ─┬─ Icon-label gaps, badge padding
xs  (8px)  ─┼─ Default small spacing
sm  (12px) ─┼─ Card internal padding
md  (16px) ─┴─ Default padding, screen margins
lg  (20px) ─┬─ Section spacing
xl  (24px) ─┴─ Large section gaps
```

### Border Radius

```
8px   ─┬─ Buttons, chips, small elements
12px  ─┼─ Small cards, inputs
16px  ─┴─ Default cards (MOST USED)
20px  ─┬─ Large cards, nav bar
```

### Animation

```
Press scale:    80-100ms, 0.85-0.95 scale
Color change:   100-200ms
Nav transition:  200ms
```

---

*Document created for BoardVerse Mobile - Neo-Brutalism Design System v4.0*
*Covers: Profile, Tournament, Wallet, Friend Management, Settings, Matchmaking/Discovery, Lobby Management*
*Last Updated: 2026-08-07*
