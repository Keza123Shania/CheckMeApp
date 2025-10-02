import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart'; // Import Auth Provider
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // For clear all
import '../../providers/todo_provider.dart'; // For clear all
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart';

// Helper widget to display progress (for overall completion)
class CompletionProgressCard extends ConsumerWidget {
  final double completionRate;
  const CompletionProgressCard({super.key, required this.completionRate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Completion', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            // Circular Progress Indicator for high-impact visual
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: completionRate,
                      strokeWidth: 8,
                      backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    // CRUCIAL FIX: Ensure percentage text is nested inside Stack for proper overlay
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(completionRate * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        Text('Completed', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Task Breakdown', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Embed the Stats Card for more detail
            // Note: TodoStatsCard must be imported or defined in home_screen.dart
            const TodoStatsCard(),
          ],
        ),
      ),
    );
  }
}


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- Password Edit Logic ---

  void _showEditPasswordDialog(String email) {
    final formKey = GlobalKey<FormState>();
    final oldPwdCtl = TextEditingController();
    final newPwdCtl = TextEditingController();
    final confirmPwdCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPwdCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPwdCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password (Min 6 chars)'),
                    validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPwdCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                    validator: (v) {
                      if (v != newPwdCtl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  // Call the provider to update the password
                  await ref.read(authStateProvider.notifier).updatePassword(
                    email,
                    oldPwdCtl.text,
                    newPwdCtl.text,
                  );
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- Name Edit Logic ---

  void _showEditNameDialog(User currentUser) {
    _nameController.text = currentUser.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Name'),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final updatedUser = User(
                    email: currentUser.email,
                    name: _nameController.text.trim(),
                    avatarUrl: currentUser.avatarUrl,
                  );
                  ref.read(userProvider.notifier).updateUser(updatedUser);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // --- Image Picker Logic ---
  Future<void> _pickImage(ImageSource source, User currentUser) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        // In a real app, you would upload this image to storage (like Firebase Storage or S3)
        // and get a public URL back. For this local DB app, we'll just save the path/name
        // or a mock URL to simulate success.

        // Since we cannot rely on local file paths persisting across platforms
        // in a non-production setup, we'll just update the user model with a mock
        // success state related to the pick.
        final mockAvatarUrl = 'assets/avatar_success.png';

        final updatedUser = currentUser.copyWith(
          name: currentUser.name,
          email: currentUser.email,
          avatarUrl: mockAvatarUrl, // Use a fixed mock URL/path for success
        );

        await ref.read(userProvider.notifier).updateUser(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      }
    } catch (e) {
      // Catch platform errors (like permissions denied or unsupported platform)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceActionSheet(User currentUser) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, currentUser);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, currentUser);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Settings/Actions Logic ---

  void _showClearAllTodosConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tasks?'),
        content: const Text('Are you sure you want to delete all your tasks? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(todoListProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All tasks cleared!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final todoState = ref.watch(todoListProvider);
    final totalTodos = todoState.valueOrNull?.length ?? 0;
    final completedTodos = todoState.valueOrNull?.where((t) => t.isDone).length ?? 0;
    final completionRate = totalTodos > 0 ? completedTodos / totalTodos : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        elevation: 0,
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- User Profile Card ---
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showImageSourceActionSheet(user),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        // Display the avatar if a URL exists, otherwise show placeholder
                        child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? const Icon(Icons.check_circle, size: 50, color: Colors.green) // Mock success icon
                            : Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(user.email,
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton.icon(
                      onPressed: () => _showEditNameDialog(user),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Name'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Progress Overview Card ---
              CompletionProgressCard(completionRate: completionRate),

              const SizedBox(height: 24),

              Text('Account Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),

              // --- Change Password Tile ---
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEditPasswordDialog(user.email),
                ),
              ),
              const SizedBox(height: 8),

              // --- Theme Settings Tile ---
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('App Theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeModeProvider.notifier).state = mode;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Danger Zone ---
              Text('Danger Zone', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.red)),
              const SizedBox(height: 8),

              // Clear All Todos
              Card(
                color: cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.clear_all_rounded, color: Colors.red.shade400),
                  title: Text('Clear All Tasks', style: TextStyle(color: Colors.red.shade400)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showClearAllTodosConfirmation,
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: const Icon(Icons.logout),
                label: const Text('LOGOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
