import 'package:flutter/material.dart';
import 'package:checkme/ui/screens/login_screen.dart';

void main() => runApp(const CheckMeApp());

class CheckMeApp extends StatelessWidget {
  const CheckMeApp({Key? key}) : super(key: key);

  // 1️⃣ Define your baby-blue swatch:
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckMe',
      theme: ThemeData(

        primarySwatch: babyBlue,

        colorScheme: ColorScheme.fromSwatch(primarySwatch: babyBlue)
            .copyWith(secondary: babyBlue.shade200),
      ),
      home: const LoginScreen(),
    );
  }
}
