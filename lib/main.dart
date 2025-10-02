import 'dart:io';
import 'package:checkme/ui/screens/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checkme/ui/screens/login_screen.dart';
import 'package:checkme/ui/screens/home_screen.dart';
import 'package:checkme/providers/theme_provider.dart';
import 'package:checkme/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'models/todo.dart';
import 'ui/screens/add_todo_screen.dart';
import 'ui/screens/RegisterScreen.dart';
import 'ui/screens/todo_details_screen.dart';
import 'ui/screens/splash_screen.dart'; // NEW: Import the splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Conditionally initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final container = ProviderContainer();
  // Ensure NotificationService is initialized before running the app
  await container.read(notificationServiceProvider).init();
  runApp(UncontrolledProviderScope(container: container, child: const CheckMeApp()));
}

class CheckMeApp extends ConsumerWidget {
  const CheckMeApp({super.key});

  static const int _babyBluePrimaryValue = 0xFF89CFF0;
  static const MaterialColor babyBlue = MaterialColor(
    _babyBluePrimaryValue,
    <int, Color>{
      50:  Color(0xFFF0FAFF),
      100: Color(0xFFDDF7FF),
      200: Color(0xFFBCEFFF),
      300: Color(0xFF9DE7FF),
      400: Color(0xFF7DEFFF),
      500: Color(_babyBluePrimaryValue),
      600: Color(0xFF71CDF0),
      700: Color(0xFF5FAAD0),
      800: Color(0xFF4E88B0),
      900: Color(0xFF3D6690),
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'CheckMe',
      // Ensure the same theme definition is used for consistency
      theme: ThemeData(
        primarySwatch: babyBlue,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: babyBlue)
            .copyWith(secondary: babyBlue.shade200, primary: babyBlue),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent, // Prevents default surface color in latest Flutter versions
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: babyBlue,
          secondary: babyBlue.shade200,
        ),
      ),
      themeMode: themeMode,
      // CRITICAL FIX: Set the home to the new SplashScreen
      home: const SplashScreen(),
      routes: {
        '/register': (c) => const RegisterScreen(),
        '/login': (c) => const LoginScreen(),
        '/home':  (c) => const HomeScreen(),
        '/add':   (c) {
          final args = ModalRoute.of(c)?.settings.arguments;
          final todoToEdit = args is Todo ? args : null;
          return AddTodoScreen(todo: todoToEdit);
        },
        '/details': (c) {
          final todoId = ModalRoute.of(c)!.settings.arguments as String?;
          if (todoId == null) {
            return const Scaffold(body: Center(child: Text('Error: Todo ID missing')));
          }
          return TodoDetailsScreen(todoId: todoId);
        },
      },
    );
  }
}
