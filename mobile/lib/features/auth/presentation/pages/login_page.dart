import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/device/device_id_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_auth_shell.dart';
import '../../../../core/widgets/ms_primary_button.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../widgets/auth_form_field.dart';

class LoginPage extends StatefulWidget {
  final AuthRemoteDataSource? authRemoteDataSource;
  final SecureStorageService? secureStorageService;
  final DeviceIdService? deviceIdService;

  const LoginPage({
    super.key,
    this.authRemoteDataSource,
    this.secureStorageService,
    this.deviceIdService,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final AuthRemoteDataSource _authRemoteDataSource;
  late final SecureStorageService _secureStorageService;
  late final DeviceIdService _deviceIdService;

  @override
  void initState() {
    super.initState();
    _authRemoteDataSource =
        widget.authRemoteDataSource ?? AuthRemoteDataSource();
    _secureStorageService =
        widget.secureStorageService ?? SecureStorageService();
    _deviceIdService = widget.deviceIdService ?? DeviceIdService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceId = await _deviceIdService.getOrCreateDeviceId();
      final deviceName = await _deviceIdService.getDeviceName();

      String deviceType = 'MOBILE';
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        deviceType = 'DESKTOP';
      }

      final tokens = await _authRemoteDataSource.login(
        email: _emailController.text,
        password: _passwordController.text,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      );

      await _secureStorageService.saveAccessToken(tokens.accessToken);
      await _secureStorageService.saveRefreshToken(tokens.refreshToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back — signed in securely.')),
        );
        context.go('/home');
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
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
    return MsAuthShell(
      brandTitle: AppConstants.appName,
      brandSubtitle:
          'A clinical study portal for MBBS & FCPS — materials, timed exams, and clear review.',
      formTitle: 'Welcome back',
      formSubtitle: 'Sign in to continue your medical preparation.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              MsAuthErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            AuthFormField(
              controller: _emailController,
              label: 'Email',
              hint: 'student@medstudy.org',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                color: AppTheme.textSecondaryColor,
                size: 22,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            AuthFormField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.textSecondaryColor,
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondaryColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 22),
            MsPrimaryButton(
              label: 'Sign In',
              isLoading: _isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Secure device-bound session',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),
          ],
        ),
      ),
      footer: MsAuthFooterLink(
        prompt: "Don't have an account?",
        actionLabel: 'Create account',
        onTap: () => context.go('/register'),
      ),
    );
  }
}
