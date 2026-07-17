import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/injection.dart';
import 'core/navigation/pages/main_scaffold.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/booking_payment/presentation/cubit/booking_result_cubit.dart';
import 'features/booking_payment/presentation/cubit/booking_result_state.dart';
import 'features/booking_payment/presentation/pages/booking_success_page.dart';
import 'features/booking_payment/presentation/pages/payment_page.dart';
import 'features/profile/presentation/cubit/profile_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  setupDependencies();

  runApp(const BoardVerseApp());
}

class BoardVerseApp extends StatelessWidget {
  const BoardVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()..checkAuthStatus()),
        BlocProvider<ProfileCubit>(create: (_) => sl<ProfileCubit>()),
        BlocProvider<BookingResultCubit>(
          create: (_) => sl<BookingResultCubit>()..tryRestorePending(),
        ),
      ],
      child: BlocListener<BookingResultCubit, BookingResultState>(
        listenWhen: (prev, curr) => prev != curr,
        listener: _handleResume,
        child: MaterialApp(
          title: 'BoardVerse',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainScaffold(),
          },
        ),
      ),
    );
  }

  static void _handleResume(BuildContext context, BookingResultState state) {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthSuccess) return;

    if (state is ResumeToPayment) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            bookingId: state.bookingId,
            cafeId: '',
            depositAmount: 0,
            deadline: DateTime.now().add(const Duration(minutes: 15)),
            config: null,
          ),
        ),
        (route) => false,
      );
    }
    if (state is ResumeToSuccess) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(bookingId: state.bookingId),
        ),
        (route) => false,
      );
    }
  }
}

/// Wrapper widget that handles initial auth state check and displays
/// the appropriate screen (Login or MainScaffold) based on auth status.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthSuccess) {
          return const MainScaffold();
        }

        return const LoginPage();
      },
    );
  }
}
