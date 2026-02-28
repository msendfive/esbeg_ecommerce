import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

import '../screens/login_screen.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// RegisterScreen — sign-up sheet with CSRF + Dio flow.
// ---------------------------------------------------------------------------

// ─── Dio singleton ───────────────────────────────────────────────────────────

final _dio = Dio();
final _cookieJar = CookieJar();
bool _dioReady = false;

void _setupDio() {
  // FIX 1: guard MUST be first — previous code reset BaseOptions on every call
  if (_dioReady) return;

  _dio.options = BaseOptions(
    baseUrl: kBaseUrl,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    followRedirects: true,
    // FIX 2: removed validateStatus override — it was swallowing 419 as
    // "success" so DioException was never thrown and the error never surfaced.
    // Default behaviour (throw on 4xx/5xx) is what we want.
  );

  if (!kIsWeb) _dio.interceptors.add(CookieManager(_cookieJar));

  _dioReady = true;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ─── CONTROLLERS ───────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ─── STATE ─────────────────────────────────────────────────────────────────

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── VALIDATION ────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (value.length < 10) return 'Enter a valid phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  // ─── REGISTER ACTION ───────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      setState(() => _errorMessage = 'Please agree to Terms & Privacy Policy');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _setupDio();

      // Step 1: CSRF handshake — Laravel sets XSRF-TOKEN cookie here.
      // Use full URI so CookieManager stores cookies under the correct key.
      final csrfUri = Uri.parse('$kBaseUrl/sanctum/csrf-cookie');
      await _dio.getUri(csrfUri);

      // Step 2: Extract CSRF token.
      // FIX 3: load cookies from the CSRF endpoint URI, not just kBaseUrl.
      // CookieJar keys by request URI — base-URL lookup returned [] because
      // cookies were stored under /sanctum/csrf-cookie path.
      String? csrfToken;
      if (!kIsWeb) {
        // Try sanctum URI first, then fall back to base URL root.
        var cookies = await _cookieJar.loadForRequest(csrfUri);
        if (cookies.isEmpty) {
          cookies = await _cookieJar.loadForRequest(Uri.parse(kBaseUrl));
        }
        debugPrint('All cookies: $cookies');
        for (final c in cookies) {
          if (c.name == 'XSRF-TOKEN') {
            csrfToken = Uri.decodeComponent(c.value);
            break;
          }
        }
        debugPrint('CSRF token: $csrfToken');
      }

      // Step 3: Registration request.
      final response = await _dio.post(
        '/api/register',
        data: {
          'full_name': _fullnameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
        options: Options(
          headers: {if (csrfToken != null) 'X-XSRF-TOKEN': csrfToken},
        ),
      );

      debugPrint('Register success: ${response.statusCode}');
      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: kSpaceMD),
              Expanded(
                child: Text(
                  'Account created! Please check your email.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;

      debugPrint('Register error $statusCode: $data');

      String msg;
      if (statusCode == 404) {
        msg = 'API endpoint not found. Check backend configuration.';
      } else if (statusCode == 419) {
        msg = 'CSRF token missing or expired. Please try again.';
      } else if (statusCode == 422) {
        if (data is Map && data['errors'] != null) {
          msg = (data['errors'] as Map).values.first[0] ?? 'Validation failed';
        } else {
          msg = (data is Map ? data['message'] : null) ?? 'Validation failed';
        }
      } else if (statusCode == 500) {
        msg = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = 'Connection timeout. Check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'Cannot connect to server. Check your connection.';
      } else {
        msg = (data is Map ? data['message'] : null) ?? 'Registration failed';
      }

      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: const BoxDecoration(
              color: kScaffoldBgColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(kRadiusXL + 8),
              ),
            ),
            child: Column(
              children: [
                _DragHandle(),
                _SheetHeader(
                  title: 'Sign Up',
                  onClose: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpace2XL,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: kSpaceSM),
                          _WelcomeText(
                            title: 'Create Account',
                            subtitle: 'Fill in your details to get started',
                          ),
                          const SizedBox(height: kSpace3XL),

                          if (_errorMessage != null) ...[
                            _ErrorBanner(
                              message: _errorMessage!,
                              onDismiss: () =>
                                  setState(() => _errorMessage = null),
                            ),
                            const SizedBox(height: kSpaceXL),
                          ],

                          _LabeledField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            controller: _fullnameController,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: kSpaceXL),

                          _LabeledField(
                            label: 'Email Address',
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: kSpaceXL),

                          _LabeledField(
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: kSpaceXL),

                          _LabeledPasswordField(
                            label: 'Password',
                            hint: 'Create a password',
                            controller: _passwordController,
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: kSpaceXL),

                          _LabeledPasswordField(
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            controller: _confirmPasswordController,
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Confirm password is required'
                                : null,
                          ),
                          const SizedBox(height: kSpace2XL),

                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _agreeToTerms,
                            onChanged: (v) =>
                                setState(() => _agreeToTerms = v ?? false),
                            title: Text(
                              'I agree to the Terms & Privacy Policy',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            activeColor: kPrimaryColor,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: kSpaceLG),

                          _LoadingButton(
                            isLoading: _isLoading,
                            label: 'Create Account',
                            onPressed: _register,
                          ),
                          const SizedBox(height: kSpace2XL),

                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: kTextSecondaryColor),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                          showLoginSheet(context);
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: kPrimaryColor,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: kSpace3XL),
                        ],
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: kSpaceMD, bottom: kSpaceSM),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: kBorderColor,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(kSpace2XL, kSpaceSM, kSpaceLG, kSpaceLG),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusMD - 2),
            ),
          ),
        ),
      ],
    ),
  );
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: kSpaceSM),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: kTextSecondaryColor,
          height: 1.4,
        ),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: kTextPrimaryColor,
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(kSpaceLG),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(kRadiusMD - 2),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: kErrorColor, size: 22),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kErrorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: kErrorColor, size: 20),
          onPressed: onDismiss,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}

class _LoadingButton extends StatelessWidget {
  const _LoadingButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label: label),
      const SizedBox(height: kSpaceSM),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 22),
        ),
      ),
    ],
  );
}

class _LabeledPasswordField extends StatelessWidget {
  const _LabeledPasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FieldLabel(label: label),
      const SizedBox(height: kSpaceSM),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline, size: 22),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 22,
              color: kTextSecondaryColor,
            ),
          ),
        ),
      ),
    ],
  );
}
