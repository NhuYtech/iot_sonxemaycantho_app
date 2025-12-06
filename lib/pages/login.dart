import 'package:flutter/material.dart';
import '../services/auth.dart';
import '../utils/dialog_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _showSetupGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Hướng dẫn cấu hình'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Để Google Sign In hoạt động, cần làm theo các bước:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Thêm SHA-1 vào Firebase Console',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: const SelectableText(
                  'B4:10:84:B3:40:81:FC:D6:02:A8:E3:67:A9:91:92:D1:A1:53:5E:B0',
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text('• Vào Firebase Console → Project Settings'),
              const Text('• Your apps → Android app'),
              const Text('• Add fingerprint → Paste SHA-1 → Save'),
              const SizedBox(height: 16),
              const Text(
                '2. Bật Google Sign-in Provider',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('• Vào Authentication → Sign-in method'),
              const Text('• Google → Enable → Save'),
              const SizedBox(height: 16),
              const Text(
                '3. Tải google-services.json mới',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('• Project Settings → Download google-services.json'),
              const Text('• Thay file cũ trong android/app/'),
              const SizedBox(height: 16),
              const Text(
                '4. Rebuild app',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: const Text(
                  'flutter clean\nflutter pub get\nflutter run',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // Sign in successful - no need to pop, auth state will handle navigation
        DialogHelper.showSuccess(context, 'Đăng nhập thành công!');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Đăng nhập thất bại';

        if (e.toString().contains('ApiException: 10')) {
          errorMessage =
              'Lỗi cấu hình Google Sign In.\n\n'
              'Vui lòng:\n'
              '1. Thêm SHA-1 vào Firebase Console\n'
              '2. Bật Google Sign-in Provider\n'
              '3. Tải google-services.json mới\n'
              '4. Rebuild app\n\n'
              'SHA-1: B4:10:84:B3:40:81:FC:D6:02:A8:E3:67:A9:91:92:D1:A1:53:5E:B0';
        } else if (e.toString().contains('network_error')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
        } else if (e.toString().contains('sign_in_canceled')) {
          errorMessage = 'Bạn đã hủy đăng nhập';
        } else {
          errorMessage =
              'Đăng nhập thất bại: ${e.toString().replaceAll('Exception: ', '')}';
        }

        DialogHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon
                Icon(
                  Icons.home_repair_service,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'IoT Sơn Xe Máy',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cần Thơ',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Đăng nhập để sử dụng hệ thống',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Google Sign In Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.g_mobiledata, size: 24);
                          },
                        ),
                  label: Text(
                    _isLoading ? 'Đang đăng nhập...' : 'Đăng nhập với Google',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Setup Guide Button
                OutlinedButton.icon(
                  onPressed: _showSetupGuide,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.blue[300]!),
                  ),
                  icon: const Icon(Icons.help_outline, size: 20),
                  label: const Text(
                    'Hướng dẫn cấu hình',
                    style: TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 32),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bạn cần đăng nhập để truy cập hệ thống IoT',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
