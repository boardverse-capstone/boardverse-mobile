import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/injection.dart';
import 'core/navigation/pages/main_scaffold.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file.
  await dotenv.load(fileName: '.env');

  // Register all dependencies via GetIt.
  setupDependencies();

  runApp(const BoardVerseApp());
}

class BoardVerseApp extends StatelessWidget {
  const BoardVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<ProfileCubit>(create: (_) => sl<ProfileCubit>()),
      ],
      child: MaterialApp(
        title: 'BoardVerse',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginPage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const MainScaffold(),
        },
      ),
    );
  }
}

