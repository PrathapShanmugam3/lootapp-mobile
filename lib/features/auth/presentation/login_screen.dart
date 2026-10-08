import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/recaptcha_dialog.dart';
import 'auth_providers.dart';
import 'forgot_password_screen.dart';

// Exact text colors from the "1a Polished Violet" design (LootHat Redesign
// .dc.html) — not generic Material greys, which read washed-out against the
// design's warmer, purple-tinted ink.
const _kInkDark = Color(0xFF14112B); // headings, "I'm not a robot"
const _kInkMuted = Color(0xFF6B6285); // subtitles, helper text
const _kInkLabel = Color(0xFF3D3456); // field labels (bold)

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _signInTab = true;

  @override
  Widget build(BuildContext context) {
    // Force the light theme here regardless of system/OS dark mode — this
    // screen's card is always white with dark-ink text per the design, and
    // inheriting a dark ColorScheme made typed input text render light on
    // the light input fill (near-invisible).
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Cap the card's width on tablets/desktop/web so it doesn't
              // stretch edge-to-edge; on phones this is a no-op (maxWidth <
              // 480 already), same single-column layout either way.
              final cardWidth = constraints.maxWidth < 480
                  ? constraints.maxWidth
                  : 440.0;
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: constraints.maxWidth < 480
                              ? BorderRadius.zero
                              : const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                          child: _Header(),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -24),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E1550).withValues(alpha: 0.16),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TabSwitcher(
                                  signInSelected: _signInTab,
                                  onChanged: (v) =>
                                      setState(() => _signInTab = v),
                                ),
                                const SizedBox(height: 24),
                                if (_signInTab)
                                  const _SignInForm()
                                else
                                  const _CreateAccountForm(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: DecorativeOrbs(scale: 1.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE3A3), AppColors.gold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: AppColors.glow(AppColors.gold, 0.8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'LH',
                        style: TextStyle(color: AppColors.midnight, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loot Hat',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23, letterSpacing: -0.6),
                          ),
                          Text(
                            'Affiliate partner portal',
                            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const Text(
                  'Share offers.\nEarn real rewards.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 31, height: 1.1, letterSpacing: -1),
                ),
                const SizedBox(height: 18),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _EarnBadge(icon: Icons.bolt_rounded, text: 'Instant payouts'),
                    _EarnBadge(icon: Icons.verified_rounded, text: 'Verified signups'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnBadge extends StatelessWidget {
  const _EarnBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.signInSelected, required this.onChanged});

  final bool signInSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Sign In',
              selected: signInSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Create Account',
              selected: !signInSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.buttonGradient : null,
          boxShadow: selected ? AppColors.glow(AppColors.violet, 0.55) : null,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.inkMuted,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _recaptchaToken;
  int _recaptchaAttempt = 0;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final recaptchaToken = _recaptchaToken;
    if (recaptchaToken == null || recaptchaToken.isEmpty) {
      setState(() => _error = 'Please verify that you are not a robot');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            mobile: _mobileCtrl.text.trim(),
            password: _passwordCtrl.text,
            recaptchaToken: recaptchaToken,
          );
    } on ApiException catch (e) {
      // reCAPTCHA tokens are single-use and expire quickly — a failed login
      // (wrong password, etc.) still consumes it server-side, so force a
      // fresh captcha for the next attempt instead of leaving the checkbox
      // showing "verified" with a now-dead token.
      setState(() {
        _error = e.message;
        _recaptchaToken = null;
        _recaptchaAttempt++;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server. Please try again.';
        _recaptchaToken = null;
        _recaptchaAttempt++;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: _kInkDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your details to sign in to your dashboard',
            style: const TextStyle(
              color: _kInkMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Mobile Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF6F3FB),
              hintText: 'Enter mobile number',
              prefixIcon: Icon(Icons.phone_outlined),
              counterText: '',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Mobile number is required';
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _FieldLabel('Password'),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                child: const Text('Forgot?'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6F3FB),
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: _ShowHideButton(
                obscured: _obscure,
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          _RecaptchaCheckbox(
            key: ValueKey(_recaptchaAttempt),
            onVerified: (token) => setState(() => _recaptchaToken = token),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          _GradientButton(
            loading: _loading,
            onPressed: _submit,
            label: 'Sign In to Dashboard',
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('New to Loot Hat?', style: const TextStyle(color: _kInkMuted)),
              TextButton(
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<_LoginScreenState>();
                  state?.setState(() => state._signInTab = false);
                },
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateAccountForm extends ConsumerStatefulWidget {
  const _CreateAccountForm();

  @override
  ConsumerState<_CreateAccountForm> createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends ConsumerState<_CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agree = false;
  bool _loading = false;
  String? _error;
  String? _recaptchaToken;
  int _recaptchaAttempt = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Please agree to the Terms & Conditions');
      return;
    }

    final recaptchaToken = _recaptchaToken;
    if (recaptchaToken == null || recaptchaToken.isEmpty) {
      setState(() => _error = 'Please verify that you are not a robot');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signup(
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        recaptchaToken: recaptchaToken,
      );
      await ref
          .read(authControllerProvider.notifier)
          .login(mobile: _mobileCtrl.text.trim(), password: _passwordCtrl.text);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _recaptchaToken = null;
        _recaptchaAttempt++;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not reach the server. Please try again.';
        _recaptchaToken = null;
        _recaptchaAttempt++;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Join Loot Hat',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: _kInkDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your account and start earning today',
            style: const TextStyle(
              color: _kInkMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Full Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF6F3FB),
              hintText: 'Enter full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Full name is required'
                : null,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Mobile Number'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF6F3FB),
              hintText: 'Enter mobile number',
              prefixIcon: Icon(Icons.phone_outlined),
              counterText: '',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Mobile number is required';
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                return 'Enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Email Address'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF6F3FB),
              hintText: 'Enter email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6F3FB),
              hintText: 'Create password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: _ShowHideButton(
                obscured: _obscurePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Confirm Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6F3FB),
              hintText: 'Confirm password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: _ShowHideButton(
                obscured: _obscureConfirm,
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agree,
                onChanged: (v) => setState(() => _agree = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: _kInkDark, fontSize: 13),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RecaptchaCheckbox(
            key: ValueKey(_recaptchaAttempt),
            onVerified: (token) => setState(() => _recaptchaToken = token),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          _GradientButton(
            loading: _loading,
            onPressed: _submit,
            label: 'Create Account',
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account?', style: const TextStyle(color: _kInkMuted)),
              TextButton(
                onPressed: () {
                  final state = context
                      .findAncestorStateOfType<_LoginScreenState>();
                  state?.setState(() => state._signInTab = true);
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        color: _kInkLabel,
      ),
    );
  }
}

/// Compact SHOW/HIDE toggle for password fields. A plain [TextButton] here
/// inherits a wide default tap target/padding that can push narrow fields
/// into overflow — this trims it to just the text.
class _ShowHideButton extends StatelessWidget {
  const _ShowHideButton({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onPressed,
      child: Text(
        obscured ? 'SHOW' : 'HIDE',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// "I'm not a robot" checkbox matching the design.
///
/// On web ([kRecaptchaInline]), the real captcha renders directly in this
/// row — no popup, since the browser can host it inline. On mobile/desktop,
/// tapping opens the real reCAPTCHA widget in a dialog (WebView needs its
/// own screen); [onVerified] fires with the token either way, or null if
/// cancelled/expired.
class _RecaptchaCheckbox extends StatefulWidget {
  const _RecaptchaCheckbox({super.key, required this.onVerified});

  final ValueChanged<String?> onVerified;

  @override
  State<_RecaptchaCheckbox> createState() => _RecaptchaCheckboxState();
}

class _RecaptchaCheckboxState extends State<_RecaptchaCheckbox> {
  bool _verified = false;
  bool _verifying = false;

  Future<void> _handleTap() async {
    if (kRecaptchaInline || _verified || _verifying) return;
    setState(() => _verifying = true);
    final token = await showRecaptchaDialog(context);
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _verified = token != null && token.isNotEmpty;
    });
    widget.onVerified(_verified ? token : null);
  }

  void _handleInlineToken(String? token) {
    setState(() => _verified = token != null && token.isNotEmpty);
    widget.onVerified(token);
  }

  @override
  Widget build(BuildContext context) {
    if (kRecaptchaInline) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2DCF0)),
        ),
        alignment: Alignment.center,
        child: RecaptchaInlineWidget(onToken: _handleInlineToken),
      );
    }
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2DCF0)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: _verifying
                  ? const Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Checkbox(
                      value: _verified,
                      onChanged: (_) => _handleTap(),
                      side: const BorderSide(color: Color(0xFFB9B0CC)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "I'm not a robot",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _kInkDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'reCAPTCHA',
                    style: const TextStyle(
                      color: _kInkMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Privacy · Terms',
                    style: const TextStyle(color: _kInkMuted, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.loading,
    required this.onPressed,
    required this.label,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GradientButton(label: label, loading: loading, onPressed: onPressed);
  }
}
