import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/device/device_id_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
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
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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

      final fullName = _fullNameController.text.trim().isNotEmpty
          ? _fullNameController.text.trim()
          : 'Medical Student';

      final tokens = await _authRemoteDataSource.register(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: fullName,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      await _secureStorageService.saveAccessToken(tokens.accessToken);
      await _secureStorageService.saveRefreshToken(tokens.refreshToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Credentials secured.'),
            backgroundColor: AppTheme.secondaryColor,
          ),
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.app_registration_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Join ${AppConstants.appName} for medical study and exams',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSm),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 20),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                  ],
                  AuthFormField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'Ali Khan',
                    keyboardType: TextInputType.name,
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  AuthFormField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'student@medstudy.org',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppTheme.textSecondaryColor),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  AuthFormField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    obscureText: !_isPasswordVisible,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  AuthFormField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: '••••••••',
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSm),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                            color: AppTheme.textSecondaryColor, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
