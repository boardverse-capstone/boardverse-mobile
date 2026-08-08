# [TICKET] in_game_experience — xác định phạm vi sử dụng hoặc xóa

> **Trạng thái**: Open
> **Ngày tạo**: 07/08/2026
> **Người tạo**: Cleanup pass (xóa `profile_neo_brutalism_preview.dart`, `features/match/`)
> **Liên quan**:
> - `.agents/docs/lobby_booking_deposit_business_rules.md` (mục 6.7, 6.8, 12.3)
> - `.agents/docs/apis_docs/active-session.md` (POS API, role Manager/CafeStaff)
> - `lib/features/in_game_experience/` (11 file)
> - `lib/core/di/injection.dart` (block DI lines 263–270)

---

## 1. Tóm tắt vấn đề

Feature `lib/features/in_game_experience/` chứa 11 file với logic nghiệp vụ rõ ràng (check-in session, live timer, inventory check overlay, 3-action session ended notification). Tuy nhiên:

- **Không có file nào trong `lib/` navigate tới `InGameSessionPage`.** Toàn bộ dependency chỉ được `injection.dart` đăng ký (lazy singleton + factory) nhưng không có entry point.
- **`InGameSessionPage` chỉ tự đẩy tới `RatingPage`** ở 4 chỗ (line 47, 57, 63, 69) — chứng tỏ đây là page **trung gian** trước khi vào rating.
- API tương ứng (`active-session.md`) thuộc **POS Web** (role `Manager`, `CafeStaff`), base route `/api/cafes/{cafeId}/sessions` — không có endpoint nào cho mobile player.

## 2. Phân tích theo tài liệu nghiệp vụ

Theo `lobby_booking_deposit_business_rules.md`:

| Mục | Nội dung | Hệ thống thực hiện |
|-----|----------|---------------------|
| 6.7 | Check-in tại quán bằng QR trên POS | **POS Web** (staff) |
| 6.8 | Hoàn thành phiên chơi, đóng session, mở cửa sổ đánh giá Karma | **POS Web** đóng session → gọi API `completed` → **mở Karma rating trên mobile player** |
| 12.3 | App player: `BookingSuccessPage` vẫn giữ nhưng chỉ cho solo booking | Mobile player **không trực tiếp "vào chơi"** |

### Vấn đề phạm vi

- **Timer chạy trong game, inventory check, payment UI** → đều là hành động của **staff tại quán** (POS Web), không phải player.
- **Mobile player chỉ cần**:
  1. Xem trạng thái booking (`confirmed` → `checkedIn` → `completed`).
  2. Sau khi POS báo `completed`, nhận notification mở `RatingPage` (BR-05).
  3. `LobbyRatingPage` đã có sẵn trong `lobby_management` (dùng chung `RatingCubit`).

→ **Mobile player KHÔNG cần `InGameSessionPage`** với timer + inventory check overlay + payment buttons.

## 3. Cần team quyết định

### Lựa chọn A — Xóa toàn bộ `in_game_experience` (khuyến nghị)

**Lý do**: Logic thuộc về POS Web, mobile player không cần page này.

**Việc cần làm**:
1. Xóa thư mục `lib/features/in_game_experience/` (11 file).
2. Xóa 3 dòng import trong `lib/core/di/injection.dart` (lines 50–52):
   ```
   import '../../features/in_game_experience/data/in_game_repository_impl.dart';
   import '../../features/in_game_experience/domain/repositories/in_game_repository.dart';
   import '../../features/in_game_experience/presentation/cubit/in_game_cubit.dart';
   ```
3. Xóa block DI (lines 264–270):
   ```
   // ─── Feature: In Game Experience ───────────────
   sl.registerLazySingleton<InGameRepository>(...);
   sl.registerFactory<InGameCubit>(...);
   ```
4. Cập nhật `.agents/docs/lobby_booking_deposit_business_rules.md` (mục 12.3) để bổ sung: "Mobile player app không có in-game page; POS Web quản lý phiên chơi".

### Lựa chọn B — Giữ lại, refactor thành player-side read-only

**Lý do**: Mobile player có thể cần xem trạng thái phiên chơi (timer, danh sách người chơi) theo thời gian thực.

**Việc cần làm**:
1. Đổi tên `InGameSessionPage` → `ViewActiveSessionPage` (read-only).
2. Xóa 2 button "Yêu cầu tính tiền" và "Mock: Kết thúc phiên (POS)" — staff-only actions.
3. Bỏ `InventoryCheckingOverlay` — staff-only action.
4. Bỏ `SessionEndedNotificationDialog` — thay bằng notification thông thường + navigate sang `RatingPage` qua deep link.
5. Thêm endpoint GET `/api/v1/bookings/{id}/active-session` cho player (nếu backend chưa có).
6. Gắn `ViewActiveSessionPage` vào `BookingSuccessPage` (mở tự động khi `status = checkedIn`).

## 4. File bị ảnh hưởng (nếu xóa theo lựa chọn A)

```
lib/features/in_game_experience/
├── data/
│   ├── datasources/mock_in_game_datasource.dart
│   ├── in_game_repository_impl.dart
│   └── models/in_game_session_model.dart
├── domain/
│   ├── entities/in_game_session_entity.dart
│   └── repositories/in_game_repository.dart
└── presentation/
    ├── cubit/in_game_cubit.dart
    ├── cubit/in_game_state.dart
    ├── pages/in_game_session_page.dart
    └── widgets/
        ├── inventory_checking_overlay.dart
        ├── play_duration_timer.dart
        └── session_ended_notification_dialog.dart
```

```
lib/core/di/injection.dart
- 3 import lines (50–52)
- 1 DI block (lines 264–270)
```

**Tổng**: 11 file feature + 8 dòng DI = ~270 dòng code.

## 5. Sau khi quyết định

- [ ] Team confirm: lựa chọn A (xóa) hay B (refactor).
- [ ] Nếu A: thực hiện xóa + `flutter analyze` sạch.
- [ ] Nếu B: tạo ticket con cho từng task (đổi tên, viết endpoint, gắn navigation).
- [ ] Cập nhật BR docs để đồng bộ với code.

## 6. Bằng chứng tham khảo

- `rg "InGameSessionPage|InGameCubit" lib` → chỉ thấy trong `in_game_experience/` + `injection.dart`. Không có page nào navigate tới.
- `in_game_experience/docs.md` section 5: "External Dependencies — `match_summary_rating` ← `RatingPage` - Navigate after session ends". Không có feature khác reference.
- `lobby_booking_deposit_business_rules.md` section 6.7-6.8: toàn bộ flow check-in/hoàn thành phiên nằm trên POS Web.
- `apis_docs/active-session.md` line 3: "Role: Manager, CafeStaff" — POS-only API.
