# Home Feature Module

## Overview

Module trang chủ của ứng dụng. Dashboard đơn giản hiển thị lời chào theo thời gian, quick actions, news/events placeholders, và personalized suggestions dựa trên ELO tier của user.

**Tổng số file**: 4 files

---

## 1. Architecture

```
lib/features/home/
└── presentation/
    ├── pages/
    │   └── home_overview_page.dart      # Main page
    └── widgets/
        ├── home_section_header.dart      # Reusable header
        ├── home_news_placeholder.dart    # News card
        └── home_quick_action_card.dart  # Quick action button
```

**Note**: Module này KHÔNG có domain/data layers. Sử dụng `ProfileCubit` từ `profile` feature để lấy dữ liệu user.

---

## 2. Key Classes

### HomeOverviewPage

**Type**: `StatelessWidget`

**Constructor Parameters:**
- `matchmakingCubit` (required) - For matchmaking context
- `onSwitchTab` (optional) - Callback to switch tabs

**Responsibilities:**
- Builds complete home screen layout
- Fetches user profile via `ProfileCubit`
- Displays personalized greeting based on time of day
- Provides quick action navigation to other tabs
- Shows news/events placeholders
- Renders personalized suggestions based on user's ELO tier

**Internal Methods:**
| Method | Purpose |
|--------|---------|
| `build()` | Main build method |
| `_buildHeader()` | Gradient welcome banner |
| `_buildQuickActions()` | 4 quick action cards |
| `_buildSuggestion()` | ELO tier-based tips |
| `_openBookingHistory()` | Opens BookingHistoryPage |
| `_greetingMessage()` | Time-based Vietnamese greeting |

**Internal Class `_SuggestionList`:**
- Displays 3 suggestion tiles based on player's ELO tier:
  - ELO >= 1500: "cao thủ" (expert)
  - ELO >= 1100: "trung cấp" (intermediate)
  - ELO < 1100: "mới chơi" (beginner)

### HomeSectionHeader

**Props**: `title`, `icon`, `actionLabel?`, `onAction?`

### HomeNewsPlaceholder

**Props**: `title`, `description`, `icon`, `color`

### HomeQuickActionCard

**Props**: `icon`, `label`, `color`, `onTap`

---

## 3. Greeting Logic

| Time Range | Vietnamese Greeting |
|------------|---------------------|
| 00:00 - 11:00 | "Chúc bạn buổi sáng vui vẻ" |
| 11:00 - 14:00 | "Buổi trưa nay có trận nào hấp dẫn không?" |
| 14:00 - 18:00 | "Buổi chiều rảnh - ghép phòng chơi ngay" |
| 18:00 - 24:00 | "Buổi tối tuyệt vời để chơi cùng bạn bè!" |

---

## 4. Interactions with Other Features

| Target Feature | Interaction Type | Details |
|----------------|------------------|---------|
| **Profile** | State Dependency | Uses `ProfileCubit` to fetch username, globalElo |
| **Matchmaking** | Dependency Injection | Receives `MatchmakingCubit` via constructor |
| **Booking/Payment** | Navigation | Opens `BookingHistoryPage` via `Navigator.push()` |
| **Navigation (Core)** | Tab Switching | Uses `onSwitchTab` callback |

### Quick Actions Navigation Map

| Action | Icon | Target |
|--------|------|--------|
| "Đặt chỗ" (Book) | `Icons.calendar_today` | Tab 1 (Bookings) |
| "Tìm phòng" (Find Room) | `Icons.groups` | Tab 2 (Discovery) |
| "Lịch sử" (History) | `Icons.history` | `BookingHistoryPage` (push) |
| "Giải đấu" (Tournament) | `Icons.emoji_events` | Tab 3 (Tournament) |

---

## 5. Business Logic Flow

```
App Launch
    │
    ▼
MainScaffold creates HomeOverviewPage
with MatchmakingCubit and onSwitchTab callback
    │
    ▼
HomeOverviewPage.build()
1. BlocProvider<ProfileCubit> created
2. getIt<ProfileCubit>().getProfile() called
    │
    ▼
ProfileCubit fetches user profile
State transitions: Initial → Loading → Loaded/Failure
    │
    ▼
UI renders based on ProfileState:
• Header: Shows avatar + greeting + username
• Quick Actions: 4 cards with tab-switch callbacks
• News Section: Static placeholder cards
• Suggestions: Dynamic tips based on user's globalElo
```

---

## 6. Quick Reference

| Task | File |
|------|------|
| Modify header/greeting | `home_overview_page.dart` |
| Add quick action | `_buildQuickActions()` in `home_overview_page.dart` |
| Change greeting logic | `_greetingMessage()` in `home_overview_page.dart` |
| Add news section | `home_news_placeholder.dart` |
| Modify suggestions | `_buildSuggestion()` in `home_overview_page.dart` |
