import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/recaptcha_dialog.dart';
import '../../affiliate/presentation/widgets/affiliate_design.dart';
import 'auth_providers.dart';
import 'forgot_password_screen.dart';

/// Sign in / Create account — the "1a Polished Violet" auth screens: a
/// compact violet → magenta header with floating glows, and a white card
/// that fills the rest of the screen (no big hero, no page scroll on a
/// normal phone).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _signInTab = true;

  void _setTab(bool signIn) => setState(() => _signInTab = signIn);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final headerH = top + 26 + 46 + 18 + 31 + 64.0; // design: 26/24/64 padding
    return Scaffold(
      backgroundColor: AffColors.pageBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned(top: 0, left: 0, right: 0, height: headerH, child: _Header(topInset: top)),
              Positioned(
                top: headerH - 36,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.10), blurRadius: 30, offset: const Offset(0, -8))],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(22, 22, 22, 24 + MediaQuery.of(context).padding.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TabSwitcher(signInSelected: _signInTab, onChanged: _setTab),
                          const SizedBox(height: 16),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOut,
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim), child: child),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(_signInTab),
                                child: _signInTab ? _SignInForm(onSwitch: () => _setTab(false)) : _CreateAccountForm(onSwitch: () => _setTab(true)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, -0.7),
          end: Alignment(1, 0.7),
          colors: [AffColors.violetDeep, AffColors.purple, AffColors.magenta],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: DecorativeOrbs()),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 26, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Text('LH', style: AffText.number(17, FontWeight.w800, color: AffColors.purpleEnd)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Loot Hat', style: AffText.jakarta(20, FontWeight.w800, color: Colors.white, letterSpacing: -0.4, height: 1.1)),
                          const SizedBox(height: 2),
                          Text('Affiliate partner portal', style: AffText.jakarta(11.5, FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  index: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulseDot(color: Color(0xFF4ADE80), size: 7),
                        const SizedBox(width: 7),
                        Text('Earn on every verified signup', style: AffText.jakarta(11.5, FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sign In / Create Account switcher with the gradient pill that springs
/// from one side to the other.
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.signInSelected, required this.onChanged});

  final bool signInSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AffColors.hairline, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: const Cubic(0.34, 1.5, 0.5, 1),
              alignment: signInSelected ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AffColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _TabLabel(label: 'Sign In', selected: signInSelected, onTap: () => onChanged(true))),
              Expanded(child: _TabLabel(label: 'Create Account', selected: !signInSelected, onTap: () => onChanged(false))),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: AffText.jakarta(13, FontWeight.w700, color: selected ? Colors.white : AffColors.inkMuted),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

/// Heading + subtitle block used by both forms.
class _FormHeading extends StatelessWidget {
  const _FormHeading(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AffText.jakarta(23, FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
          const SizedBox(height: 4),
          Text(subtitle, style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkMuted)),
        ],
      ),
    );
  }
}

/// Labelled input from the design: 15px radius, 1.5px lilac border, soft
/// lavender fill, and a violet border + 4px glow ring (on white) when focused.
class _AuthField extends StatefulWidget {
  const _AuthField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.inputFormatters,
    this.onSubmitted,
    this.trailingLabel,
    this.index = 0,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailingLabel;
  final int index;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: c, width: 1.5));
    return FadeSlideIn(
      index: widget.index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(widget.label, style: AffText.jakarta(12, FontWeight.w700, color: AffColors.inkLabel)),
              if (widget.trailingLabel != null) widget.trailingLabel!,
            ],
          ),
          const SizedBox(height: 7),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: _focused ? [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.12), spreadRadius: 4, blurRadius: 0)] : const [],
            ),
            child: TextFormField(
              focusNode: _focus,
              controller: widget.controller,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onFieldSubmitted: widget.onSubmitted,
              validator: widget.validator,
              style: AffText.jakarta(14, FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: _focused ? Colors.white : AffColors.fieldBg,
                hintText: widget.hint,
                hintStyle: AffText.jakarta(14, FontWeight.w500, color: AffColors.inkHint),
                prefixIcon: Icon(widget.icon, size: 17, color: AffColors.inkHint),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
                suffixIcon: widget.suffix,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: border(AffColors.fieldBorder),
                enabledBorder: border(AffColors.fieldBorder),
                focusedBorder: border(AffColors.purpleEnd),
                errorBorder: border(AffColors.danger),
                focusedErrorBorder: border(AffColors.danger),
                errorStyle: AffText.jakarta(11.5, FontWeight.w600, color: AffColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowHide extends StatelessWidget {
  const _ShowHide({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          widthFactor: 1,
          child: Text(obscured ? 'SHOW' : 'HIDE', style: AffText.jakarta(11, FontWeight.w800, color: AffColors.purpleEnd, letterSpacing: 0.66)),
        ),
      ),
    );
  }
}

String? _mobileValidator(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Mobile number is required';
  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) return 'Enter a valid 10-digit mobile number';
  return null;
}

final _mobileFormatters = <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)];

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 2), child: Text(message, style: AffText.jakarta(12, FontWeight.w600, color: AffColors.danger)));
}

class _FootLink extends StatelessWidget {
  const _FootLink({required this.question, required this.action, required this.onTap});

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      index: 6,
      child: Center(
        child: Text.rich(
          TextSpan(
            style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkMuted),
            children: [
              TextSpan(text: '$question '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(onTap: onTap, child: Text(action, style: AffText.jakarta(12.5, FontWeight.w800, color: AffColors.purpleEnd))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({required this.onSwitch});

  final VoidCallback onSwitch;

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
          const _FormHeading('Welcome back', 'Enter your details to sign in to your dashboard'),
          const SizedBox(height: 16),
          _AuthField(
            index: 1,
            label: 'Mobile Number',
            hint: 'Enter mobile number',
            icon: Icons.phone_outlined,
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: _mobileFormatters,
            validator: _mobileValidator,
          ),
          const SizedBox(height: 16),
          _AuthField(
            index: 2,
            label: 'Password',
            hint: 'Enter password',
            icon: Icons.lock_outline,
            controller: _passwordCtrl,
            obscure: _obscure,
            trailingLabel: GestureDetector(
              onTap: _loading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: Text('Forgot?', style: AffText.jakarta(12, FontWeight.w700, color: AffColors.purpleEnd)),
            ),
            suffix: _ShowHide(obscured: _obscure, onPressed: () => setState(() => _obscure = !_obscure)),
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            index: 3,
            child: _RecaptchaCheckbox(key: ValueKey(_recaptchaAttempt), onVerified: (token) => setState(() => _recaptchaToken = token)),
          ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 16),
          FadeSlideIn(index: 4, child: GradientButton(loading: _loading, onPressed: _submit, label: 'Sign In to Dashboard')),
          const SizedBox(height: 16),
          _FootLink(question: 'New to Loot Hat?', action: 'Create account', onTap: widget.onSwitch),
        ],
      ),
    );
  }
}

class _CreateAccountForm extends ConsumerStatefulWidget {
  const _CreateAccountForm({required this.onSwitch});

  final VoidCallback onSwitch;

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
          const _FormHeading('Join Loot Hat', 'Create your account and start earning today'),
          const SizedBox(height: 14),
          _AuthField(
            index: 1,
            label: 'Full Name',
            hint: 'Enter full name',
            icon: Icons.person_outline,
            controller: _nameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 14),
          _AuthField(
            index: 2,
            label: 'Mobile Number',
            hint: 'Enter mobile number',
            icon: Icons.phone_outlined,
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: _mobileFormatters,
            validator: _mobileValidator,
          ),
          const SizedBox(height: 14),
          _AuthField(
            index: 3,
            label: 'Email Address',
            hint: 'Enter email address',
            icon: Icons.mail_outline,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _AuthField(
            index: 4,
            label: 'Password',
            hint: 'Create password',
            icon: Icons.lock_outline,
            controller: _passwordCtrl,
            obscure: _obscurePassword,
            suffix: _ShowHide(obscured: _obscurePassword, onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _AuthField(
            index: 5,
            label: 'Confirm Password',
            hint: 'Confirm password',
            icon: Icons.lock_outline,
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            suffix: _ShowHide(obscured: _obscureConfirm, onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _agree = !_agree),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _agree ? AffColors.purpleEnd : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _agree ? AffColors.purpleEnd : const Color(0xFFCFC6EA), width: 1.5),
                    ),
                    child: _agree ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkLabel),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(text: 'Terms & Conditions', style: AffText.jakarta(12.5, FontWeight.w700, color: AffColors.purpleEnd)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 7,
            child: _RecaptchaCheckbox(key: ValueKey(_recaptchaAttempt), onVerified: (token) => setState(() => _recaptchaToken = token)),
          ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 14),
          FadeSlideIn(index: 8, child: GradientButton(loading: _loading, onPressed: _submit, label: 'Create Account')),
          const SizedBox(height: 14),
          _FootLink(question: 'Already have an account?', action: 'Sign in', onTap: widget.onSwitch),
        ],
      ),
    );
  }
}

/// "I'm not a robot" row from the design (26px box, reCAPTCHA caption).
///
/// On web ([kRecaptchaInline]) the real captcha renders in this row; on
/// mobile, tapping opens the real reCAPTCHA in a dialog. [onVerified] fires
/// with the token, or null if cancelled/expired.
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

  BoxDecoration get _box => BoxDecoration(
        color: AffColors.fieldBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AffColors.fieldBorder, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    if (kRecaptchaInline) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: _box,
        alignment: Alignment.center,
        child: RecaptchaInlineWidget(onToken: _handleInlineToken),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _box,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _verified ? AffColors.success : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _verified ? AffColors.success : const Color(0xFFCFC6EA), width: 2),
              ),
              child: _verifying
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2.5, color: AffColors.purpleEnd))
                  : (_verified ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text("I'm not a robot", style: AffText.jakarta(13.5, FontWeight.w600), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('reCAPTCHA', style: AffText.jakarta(9, FontWeight.w600, color: AffColors.inkHint, height: 1.3)),
                Text('Privacy · Terms', style: AffText.jakarta(9, FontWeight.w600, color: AffColors.inkHint, height: 1.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
