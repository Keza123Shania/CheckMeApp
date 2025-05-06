import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds current logged-in email
final currentUserProvider = StateProvider<String?>((_) => null);