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
        // BookingResultCubit ở app-level để resume flow khi kill app
        // giữa chừng có thể phát hiện `pendingBookingId` ở secure storage.
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
          home: const LoginPage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainScaffold(),
          },
        ),
      ),
    );
  }

  /// Khi `BookingResultCubit` phát hiện booking pending sau khi mở app:
  /// - ResumeToPayment → mở PaymentPage
  /// - ResumeToSuccess → mở BookingSuccessPage
  /// - ResumeCleared / ResultFailure → không làm gì (đã clear pending id)
  static void _handleResume(BuildContext context, BookingResultState state) {
    // Chỉ áp dụng khi user đã đăng nhập (đang ở MainScaffold).
    // Tránh navigate khi còn ở LoginPage.
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

