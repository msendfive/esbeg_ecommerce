import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/register_screen.dart';
import '../utilities/constants.dart';

// ---------------------------------------------------------------------------
// LoginScreen — full-screen login page (also usable as a bottom sheet via
// showLoginSheet helper).
// Replaces: login_sheet.dart  →  screens/login_screen.dart
// ---------------------------------------------------------------------------

void showLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const LoginScreen(),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ─── CONTROLLERS & KEYS ────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ─── ANIMATION ─────────────────────────────────────────────────────────────

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── STATE ─────────────────────────────────────────────────────────────────

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _globalError;

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ─── VALIDATION ────────────────────────────────────────────────────────────

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email, username, or phone is required';
    }
    if (value.length < 3) return 'Input too short';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ─── LOGIN ACTION ──────────────────────────────────────────────────────────

  Future<void> _login() async {
    setState(() => _globalError = null);
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'login': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Invalid server response');
      }

      if (response.statusCode == 200) {
        final token = data['token']?.toString() ?? '';
        final user = data['user'] ?? {};

        if (!mounted) return;

        context.read<AuthProvider>().login(
          token: token,
          user: {
            'name': user['full_name'],
            'email': user['email'],
            'phone': user['phone'],
            'role': user['role'],
          },
        );

        await _successAndNavigate();
      } else {
        setState(() => _globalError = data['message'] ?? 'Login failed');
      }
    } catch (e, stack) {
      debugPrint('LOGIN ERROR: $e\n$stack');
      setState(() => _globalError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _successAndNavigate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: kSpaceMD),
            Text('Login successful!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD - 2),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    Navigator.of(context).pop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: kScaffoldBgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
        ),
        child: Column(
          children: [
            _DragHandle(),
            _SheetHeader(
              title: 'Welcome Back',
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: kSpace2XL,
                      right: kSpace2XL,
                      bottom:
                          MediaQuery.of(context).viewInsets.bottom + kSpace3XL,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: kSpaceSM),
                          _LogoBadge(),
                          const SizedBox(height: kSpace3XL),
                          _WelcomeText(
                            title: 'Sign in to continue',
                            subtitle:
                                'Enter your email and password to access your account',
                          ),
                          const SizedBox(height: kSpace3XL),

                          // Email field
                          _FieldLabel(label: 'Email / Username / Phone'),
                          const SizedBox(height: kSpaceSM),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateLogin,
                            onFieldSubmitted: (_) {
                              _emailFocus.unfocus();
                              _passwordFocus.requestFocus();
                            },
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 22),
                            ),
                          ),
                          const SizedBox(height: kSpaceXL),

                          // Password field
                          _FieldLabel(label: 'Password'),
                          const SizedBox(height: kSpaceSM),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                size: 22,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 22,
                                  color: kTextSecondaryColor,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: kSpaceLG),

                          // Remember me + forgot
                          _RememberRow(
                            rememberMe: _rememberMe,
                            onToggle: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            onForgot: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Forgot password coming soon!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                ),
                          ),
                          const SizedBox(height: kSpace2XL),

                          // Error banner
                          if (_globalError != null) ...[
                            _ErrorBanner(
                              message: _globalError!,
                              onDismiss: () =>
                                  setState(() => _globalError = null),
                            ),
                            const SizedBox(height: kSpaceLG),
                          ],

                          // Login button
                          _LoadingButton(
                            isLoading: _isLoading,
                            label: 'Sign In',
                            onPressed: _login,
                          ),
                          const SizedBox(height: kSpace2XL),

                          _Divider(),
                          const SizedBox(height: kSpace2XL),

                          // Google button
                          _GoogleButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Google sign-in coming soon!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                ),
                          ),
                          const SizedBox(height: kSpace2XL),

                          // Sign up prompt
                          _SignupPrompt(
                            onSignup: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const RegisterScreen(),
                              );
                            },
                          ),
                          const SizedBox(height: kSpace3XL),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets (shared with RegisterScreen via same file scope)
// ---------------------------------------------------------------------------

// ─── Drag handle ────────────────────────────────────────────────────────────

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

// ─── Sheet header (title + close) ────────────────────────────────────────────

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

// ─── Logo badge ──────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(kSpaceLG),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kSpaceXL),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        kEsbegLogo,
        height: 56,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.shopping_bag, size: 56, color: kPrimaryColor),
      ),
    ),
  );
}

// ─── Welcome text block ──────────────────────────────────────────────────────

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

// ─── Field label ─────────────────────────────────────────────────────────────

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

// ─── Remember me + forgot password row ──────────────────────────────────────

class _RememberRow extends StatelessWidget {
  const _RememberRow({
    required this.rememberMe,
    required this.onToggle,
    required this.onForgot,
  });

  final bool rememberMe;
  final VoidCallback onToggle;
  final VoidCallback onForgot;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(kSpaceSM),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kSpaceXS),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: rememberMe ? kPrimaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(kSpaceXS),
                  border: Border.all(
                    color: rememberMe ? kPrimaryColor : kBorderColor,
                    width: 2,
                  ),
                ),
                child: rememberMe
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: kSpaceSM),
              Text(
                'Remember me',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
              ),
            ],
          ),
        ),
      ),
      TextButton(
        onPressed: onForgot,
        style: TextButton.styleFrom(
          foregroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceSM,
            vertical: kSpaceXS,
          ),
        ),
        child: const Text(
          'Forgot Password?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

// ─── Error banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
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
      ),
    ); // Material
  }
}

// ─── Primary loading button ──────────────────────────────────────────────────

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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );
}

// ─── OR divider ──────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(color: kBorderColor, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
        child: Text(
          'OR',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: kTextSecondaryColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
      Expanded(child: Divider(color: kBorderColor, thickness: 1)),
    ],
  );
}

// ─── Google sign-in button ───────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kTextPrimaryColor,
        backgroundColor: kSurfaceColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            kGoogleLogo,
            height: 24,
            errorBuilder: (_, _, _) =>
                Icon(Icons.g_mobiledata, size: 28, color: kTextSecondaryColor),
          ),
          const SizedBox(width: kSpaceMD),
          const Text(
            'Continue with Google',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

// ─── Sign-up prompt ──────────────────────────────────────────────────────────

class _SignupPrompt extends StatelessWidget {
  const _SignupPrompt({required this.onSignup});

  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: kTextSecondaryColor),
        ),
        TextButton(
          onPressed: onSignup,
          style: TextButton.styleFrom(
            foregroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(horizontal: kSpaceXS),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
