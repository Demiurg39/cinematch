import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_state.dart';
import 'providers/auth_provider.dart';
import 'widgets/social_button.dart';
import '../../../core/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  String _errorMessage = '';

  late final AnimationController _bgController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _clearError() {
    setState(() => _errorMessage = '');
    ref.read(authNotifierProvider.notifier).resetError();
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() => _errorMessage = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          _setError(_humanizeError(e));
        },
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _GradientBackground(animation: _fadeAnimation),

          // Decorative film reel circles
          Positioned(
            top: -80,
            right: -80,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentPurple.withValues(alpha: 0.06),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Logo with glow
                      _LogoSection(isSignUp: _isSignUp),

                      const SizedBox(height: 48),

                      // Error banner
                      if (_errorMessage.isNotEmpty) ...[
                        _ErrorBanner(
                          message: _errorMessage,
                          onDismiss: _clearError,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Form card
                      _FormCard(
                        isSignUp: _isSignUp,
                        authState: authState,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        usernameController: _usernameController,
                        onSubmit: _onSubmit,
                        onToggleMode: _toggleMode,
                      ),

                      const SizedBox(height: 32),

                      // Divider with "or"
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.textMuted.withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.textMuted.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Google button
                      SizedBox(
                        width: double.infinity,
                        child: SocialButton(
                          text: 'Continue with Google',
                          icon: Icons.g_mobiledata,
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).signInWithGoogle();
                          },
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() => _isSignUp = !_isSignUp);
    _clearError();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    _clearError();

    final notifier = ref.read(authNotifierProvider.notifier);

    if (_isSignUp) {
      notifier.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );
    } else {
      notifier.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  String _humanizeError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('email already registered') || msg.contains('already been registered')) {
      return 'Email already registered. Try signing in.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'Wrong email or password.';
    }
    if (msg.contains('user not found') || msg.contains('no user')) {
      return 'No account found with this email.';
    }
    if (msg.contains('weak password') || msg.contains('password should be')) {
      return 'Password is too weak. Use 6+ characters.';
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Wait and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  final Animation<double> animation;
  const _GradientBackground({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F1A),
                Color(0xFF0A0A12),
                Color(0xFF12101F),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Subtle radial glow top-right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Subtle radial glow bottom-left
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final bool isSignUp;
  const _LogoSection({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon with glow
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPink.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.movie_filter,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'CINEMATCH',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryPink,
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your next favorite movie awaits',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error.withValues(alpha: 0.9),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              color: AppColors.error.withValues(alpha: 0.7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isSignUp;
  final AsyncValue<AuthState> authState;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const _FormCard({
    required this.isSignUp,
    required this.authState,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
    required this.onSubmit,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
        children: [
          Text(
            isSignUp ? 'Create Account' : 'Welcome Back',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSignUp
                ? 'Join Cinematch and find movies together'
                : 'Sign in to continue swiping',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Username (sign up only)
          if (isSignUp) ...[
            _StyledTextField(
              controller: usernameController,
              hintText: 'Username',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),
          ],

          // Email
          _StyledTextField(
            controller: emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          _StyledTextField(
            controller: passwordController,
            hintText: 'Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isSignUp ? 'Get Started' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Toggle mode
          GestureDetector(
            onTap: onToggleMode,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: isSignUp
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: isSignUp ? 'Sign In' : 'Sign Up',
                    style: const TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
      ),
    );
  }
}
