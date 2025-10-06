import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/todo_provider.dart'; // Needed for clearAll
import 'home_screen.dart'; // Needed for TodoStatsCard

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  // Password controllers for the Change Password dialog
  final _oldPwdCtl = TextEditingController();
  final _newPwdCtl = TextEditingController();
  final _confirmPwdCtl = TextEditingController();
  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPwdCtl.dispose();
    _newPwdCtl.dispose();
    _confirmPwdCtl.dispose();
    super.dispose();
  }

  // --- UI DIALOGS ---

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
                  final updatedUser = currentUser.copyWith(
                    name: _nameController.text,
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

  void _showEditPasswordDialog(BuildContext context, String userEmail) {
    _oldPwdCtl.clear();
    _newPwdCtl.clear();
    _confirmPwdCtl.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            final primaryColor = Theme.of(context).colorScheme.primary;
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _oldPwdCtl,
                      obscureText: _isObscureOld,
                      decoration: InputDecoration(
                        labelText: 'Old Password',
                        suffixIcon: IconButton(
                          icon: Icon(_isObscureOld ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                          onPressed: () => stfSetState(() => _isObscureOld = !_isObscureOld),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _newPwdCtl,
                      obscureText: _isObscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password (min 6 chars)',
                        suffixIcon: IconButton(
                          icon: Icon(_isObscureNew ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                          onPressed: () => stfSetState(() => _isObscureNew = !_isObscureNew),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _confirmPwdCtl,
                      obscureText: _isObscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: IconButton(
                          icon: Icon(_isObscureConfirm ? Icons.visibility : Icons.visibility_off, color: primaryColor),
                          onPressed: () => stfSetState(() => _isObscureConfirm = !_isObscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_newPwdCtl.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters.')));
                      return;
                    }
                    if (_newPwdCtl.text != _confirmPwdCtl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match.')));
                      return;
                    }

                    try {
                      await ref.read(authStateProvider.notifier).changePassword(
                        _oldPwdCtl.text,
                        _newPwdCtl.text,
                      );
                      if (stfContext.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                      }
                    } catch (e) {
                      if (stfContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().contains('incorrect') ? 'Incorrect old password.' : 'Failed to update password.')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- IMAGE PICKING ---

  Future<void> _pickImage(User currentUser) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final updatedUser = currentUser.copyWith(avatarUrl: image.path);
        await ref.read(userProvider.notifier).updateUser(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image picking failed: $e')));
      }
    }
  }

  // --- UI BUILDER METHODS ---

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final todoState = ref.watch(todoListProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

          final totalTasks = todoState.valueOrNull?.length ?? 0;
          final completedTasks = todoState.valueOrNull?.where((t) => t.isDone).length ?? 0;
          final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

          // Determine avatar display
          ImageProvider avatarImage;
          if (user.avatarUrl != null && File(user.avatarUrl!).existsSync()) {
            // Fix: Use FileImage for local file paths
            avatarImage = FileImage(File(user.avatarUrl!));
          } else {
            avatarImage = const AssetImage('assets/login_avatar.png'); // Placeholder/Default
          }


          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Profile Header ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: avatarImage,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: user.avatarUrl == null
                              ? Icon(Icons.person, size: 50, color: primaryColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _pickImage(user),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryColor,
                              child: const Icon(Icons.edit, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(user.name,
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
                    Text(user.email,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey.shade600)),
                    TextButton.icon(
                      onPressed: () => _showEditNameDialog(user),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Name'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Overall Completion Card (FIX APPLIED HERE) ---
              Card(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overall Completion', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),

                      // Fix 1: Use proper alignment to prevent overlap
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress Indicator (Background and foreground arc)
                              SizedBox( // Explicit size for the indicator
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value: completionRate,
                                  strokeWidth: 10,
                                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                ),
                              ),

                              // Text positioned exactly in the center of the stack
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(completionRate * 100).toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 32),
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
                      todoState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : const TodoStatsCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              // --- Settings Section ---
              Text('Account & Security', style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Change Password Tile (New Feature)
              ListTile(
                leading: const Icon(Icons.lock_open_rounded),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showEditPasswordDialog(context, user.email),
              ),

              // Theme Selector Tile
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('App Theme'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Default'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Mode'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Mode'),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).state = mode;
                    }
                  },
                ),
              ),

              // Clear All Todos Tile
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                title: const Text('Clear All Todos', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text('Are you sure you want to delete ALL your todos? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(todoListProvider.notifier).clearAll();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Delete All'),
                        ),
                      ],
                    ),
                  );
                },
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
