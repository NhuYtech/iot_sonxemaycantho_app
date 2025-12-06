import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.dart';
import '../utils/dialog_helper.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService _authService = AuthService();

  DateTime accountCreatedDate = DateTime(2024, 1, 15);

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (mounted) {
                  Navigator.pop(context); // Close confirm dialog first
                }
                await _authService.signOut();
                // No need to show success dialog, user will be redirected to login
              } catch (e) {
                if (mounted) {
                  DialogHelper.showError(context, 'Lỗi đăng xuất: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _logoutAllDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất tất cả thiết bị'),
        content: const Text(
          'Bạn sẽ bị đăng xuất khỏi tất cả các thiết bị đang đăng nhập.\n\n'
          'Bạn có chắc muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (mounted) {
                  Navigator.pop(context); // Close confirm dialog first
                }
                await _authService.signOut();
                // No need to show success dialog, user will be redirected to login
              } catch (e) {
                if (mounted) {
                  DialogHelper.showError(context, 'Lỗi: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất tất cả'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final User? currentUser = _authService.currentUser;

    // User must be logged in to access the app
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // User is logged in
    final String userName = currentUser.displayName ?? 'Người dùng';
    final String userEmail = currentUser.email ?? '';
    final String? avatarUrl = currentUser.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorScheme.inversePrimary, Colors.white],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _getInitials(userName),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(userName),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Account Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin tài khoản',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.person_outline,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Tên hiển thị'),
                          subtitle: Text(userName),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.email_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Email'),
                          subtitle: Text(userEmail),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Ngày tạo tài khoản'),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(accountCreatedDate),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.shield_outlined,
                            color: Colors.green,
                          ),
                          title: const Text('Đăng nhập bằng'),
                          subtitle: Row(
                            children: [
                              Image.network(
                                'https://www.google.com/favicon.ico',
                                width: 16,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.g_mobiledata,
                                    size: 16,
                                  );
                                },
                              ),
                              const SizedBox(width: 6),
                              const Text('Google'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Account Actions
                  const Text(
                    'Hành động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Colors.orange,
                          ),
                          title: const Text('Đăng xuất'),
                          subtitle: const Text('Đăng xuất khỏi thiết bị này'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _logout,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.devices_other,
                            color: Colors.red,
                          ),
                          title: const Text('Đăng xuất tất cả thiết bị'),
                          subtitle: const Text(
                            'Đăng xuất khỏi mọi thiết bị đang đăng nhập',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _logoutAllDevices,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'IoT Sơn Xe Máy Cần Thơ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phiên bản 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
