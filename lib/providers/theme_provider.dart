import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Controls the app’s ThemeMode
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);