import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:boardverse/features/profile/presentation/pages/setup_profile_page.dart';

/// Gate chặn sau MainScaffold — buộc player hoàn tất hồ sơ trước
/// khi sử dụng bất kỳ tab nào. Kích hoạt ngay khi
/// [ProfileCubit] phát hiện `hasProfile = false` (hoặc
/// [ProfileNotFound]):
///
/// - [SetupProfilePage] được [Navigator.push] full-screen,
///   che toàn bộ MainScaffold + BottomNav.
/// - Player submit form → cubit emit `hasProfile = true`
///   → gate tự động pop route → trở về MainScaffold bình thường.
///
/// Các trạng thái khác (`ProfileInitial`, `ProfileLoading`,
/// `ProfileFailure`) → không push, để player dùng MainScaffold bình
/// thường (có thể retry pull-to-refresh ở tab Profile).
///
/// Lý do chọn pattern push route thay vì in-place widget swap:
/// - Cô lập hoàn toàn SetupProfilePage với MainScaffold, không cần
///   truyền `bottomNavigationBar` qua wrapper.
/// - Tự nhiên ẩn BottomNav vì SetupProfilePage là full-screen.
/// - Hỗ trợ nút "Đăng xuất" ở SetupProfilePage chỉ cần
///   `Navigator.popUntil` mà không đụng vào MainScaffold.
class SetupProfileGate extends StatefulWidget {
  const SetupProfileGate({super.key, required this.child});

  /// MainScaffold body (LazyIndexedStack). Được render khi player
  /// đã hoàn tất hồ sơ (`hasProfile = true`) hoặc trong các trạng
  /// thái không chắc chắn (loading, error).
  final Widget child;

  @override
  State<SetupProfileGate> createState() => _SetupProfileGateState();
}

class _SetupProfileGateState extends State<SetupProfileGate> {
  /// Đánh dấu đã push SetupProfilePage, tránh push chồng khi cubit
  /// emit cùng trạng thái nhiều lần.
  bool _pushed = false;

  void _maybePushSetupPage(BuildContext context, ProfileState state) {
    final mustSetup = state is ProfileLoaded && !state.profile.hasProfile;
    final mustSetupOnNotFound = state is ProfileNotFound;
    final mustSetupNow = mustSetup || mustSetupOnNotFound;

    final nav = Navigator.of(context);

    if (!mustSetupNow) {
      // Profile đã hoàn tất - pop setup route (nếu đang trên đó)
      // để trở về MainScaffold.
      if (_pushed && nav.canPop()) {
        _pushed = false;
        nav.pop();
      }
      return;
    }

    if (_pushed) return;
    _pushed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const SetupProfilePage(),
        ),
      );
      // Khi route pop (user complete form thành công) thì gate
      // tự đóng. Không reset `_pushed` ngay vì có thể cubit chưa
      // kịp emit state mới; nếu cubit vẫn "must setup" thì gate sẽ
      // được kích hoạt lại qua listener.
      _pushed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (prev, curr) {
        final prevHas = prev is ProfileLoaded ? prev.profile.hasProfile : null;
        final currHas = curr is ProfileLoaded ? curr.profile.hasProfile : null;
        final prevNotFound = prev is ProfileNotFound;
        final currNotFound = curr is ProfileNotFound;
        // Listen khi transition giữa has-not-profile ↔ has-profile.
        if (prevHas != currHas) return true;
        // Hoặc khi vào/ra ProfileNotFound.
        if (prevNotFound != currNotFound) return true;
        return false;
      },
      listener: (context, state) => _maybePushSetupPage(context, state),
      child: widget.child,
    );
  }
}
