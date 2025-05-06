import 'package:checkme/ui/screens/add_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checkme/ui/screens/login_screen.dart';
import 'package:checkme/ui/screens/home_screen.dart';
import 'package:checkme/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: CheckMeApp()));
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
      theme: ThemeData(
        primarySwatch: babyBlue,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: babyBlue)
            .copyWith(secondary: babyBlue.shade200),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: babyBlue,
          secondary: babyBlue.shade200,
        ),
      ),
      themeMode: themeMode,
      initialRoute: '/login',
      routes: {
        '/login': (c) => const LoginScreen(),
        '/home':  (c) => const HomeScreen(),
        '/add':   (c) => const AddTodoScreen(),
      },
    );
  }}