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

class RegisterPage extends StatefulWidget {
  final AuthRemoteDataSource? authRemoteDataSource;
  final SecureStorageService? secureStorageService;
  final DeviceIdService? deviceIdService;

  const RegisterPage({
    super.key,
    this.authRemoteDataSource,
    this.secureStorageService,
    this.deviceIdService,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
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

      final fullName = _fullNameController.text.trim().isNotEmpty
          ? _fullNameController.text.trim()
          : 'Medical Student';

      final tokens = await _authRemoteDataSource.register(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: fullName,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      );

      await _secureStorageService.saveAccessToken(tokens.accessToken);
      await _secureStorageService.saveRefreshToken(tokens.refreshToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account created — welcome to MedStudy.')),
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
          'Create your student account and unlock structured medical study + exams.',
      formTitle: 'Create account',
      formSubtitle: 'Join the clinical learning portal in under a minute.',
      trustLabels: const ['Free to register', 'MBBS & FCPS', 'Device secure'],
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
              controller: _fullNameController,
              label: 'Full name',
              hint: 'Ali Khan',
              keyboardType: TextInputType.name,
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: AppTheme.textSecondaryColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            AuthFormField(
              controller: _passwordController,
              label: 'Password',
              hint: 'At least 8 characters',
              obscureText: !_isPasswordVisible,
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
            const SizedBox(height: 14),
            AuthFormField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Re-enter password',
              obscureText: !_isConfirmPasswordVisible,
              textInputAction: TextInputAction.done,
              prefixIcon: Icon(
                Icons.verified_user_outlined,
                color: AppTheme.textSecondaryColor,
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textSecondaryColor,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 22),
            MsPrimaryButton(
              label: 'Create Account',
              isLoading: _isLoading,
              onPressed: _handleRegister,
            ),
          ],
        ),
      ),
      footer: MsAuthFooterLink(
        prompt: 'Already have an account?',
        actionLabel: 'Sign in',
        onTap: () => context.go('/login'),
      ),
    );
  }
}
