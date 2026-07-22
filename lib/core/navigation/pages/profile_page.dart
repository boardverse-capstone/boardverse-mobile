import 'package:flutter/material.dart';

import '../../../features/profile/presentation/pages/home_page.dart';

/// Wrapper for the "Cá nhân" tab.
///
/// Reuses the existing [HomePage] (profile dashboard) but exposes it under
/// a distinct route name so we can wire refresh hooks from the parent
/// scaffold without changing the page's public API.
///
/// IMPORTANT: Does NOT create a new BlocProvider here because ProfileCubit
/// is already provided at the app root in main.dart. Creating a duplicate
/// provider would cause state conflicts and infinite loading loops.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the existing ProfileCubit from the app root.
    // HomePage.initState will trigger getProfile() when first loaded.
    return const HomePage();
  }
}