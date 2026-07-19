import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection.dart';
import '../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../features/profile/presentation/pages/home_page.dart';

/// Wrapper for the "Cá nhân" tab.
///
/// Reuses the existing [HomePage] (profile dashboard) but exposes it under
/// a distinct route name so we can wire refresh hooks from the parent
/// scaffold without changing the page's public API.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) => getIt<ProfileCubit>()..getProfile(),
      child: const HomePage(),
    );
  }
}