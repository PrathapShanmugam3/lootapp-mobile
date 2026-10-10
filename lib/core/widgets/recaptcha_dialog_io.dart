import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import 'common.dart' show BrandSpinner;

/// On mobile/desktop the captcha always needs the popup dialog (WebView
/// can't render inline in the normal widget tree the way HtmlElementView
/// can on web) — see recaptcha_dialog_web.dart's kRecaptchaInline for why
/// web differs.
const kRecaptchaInline = false;

/// Unused on mobile/desktop (`kRecaptchaInline` is false here, so callers
/// never build this) — exists only so the conditional export in
/// recaptcha_dialog.dart resolves on every platform.
class RecaptchaInlineWidget extends StatelessWidget {
  const RecaptchaInlineWidget({super.key, required this.onToken});

  final ValueChanged<String?> onToken;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Google reCAPTCHA v2 site key — same key the Next.js UI uses
/// (lootapp-ui/.env.local NEXT_PUBLIC_RECAPTCHA_SITE_KEY), so tokens verify
/// against the same backend RECAPTCHA_SECRET_KEY.
const _recaptchaSiteKey = '6LeLlIAtAAAAAOYJQ89hodWYdVZLeMdnmS2xIJKt';

/// Minimal page hosting the real reCAPTCHA v2 checkbox widget. There's no
/// native Flutter equivalent for v2 (it's a browser-rendered widget), so we
/// load this in a WebView and read the token back over a JS channel —
/// mirrors the Next.js login page's explicit grecaptcha.render() call.
///
/// Besides the token, the page reports `challenge:open` / `challenge:closed`
/// when Google pops up its image challenge, so the dialog can stay compact
/// (just the checkbox) and only grow while the challenge is showing.
String _recaptchaHtml(bool dark) =>
    '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <style>
    html, body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
    body { display: flex; justify-content: center; padding-top: 2px; }
  </style>
</head>
<body>
  <div class="g-recaptcha"
       data-sitekey="$_recaptchaSiteKey"
       data-theme="${dark ? 'dark' : 'light'}"
       data-callback="onRecaptchaSuccess"
       data-expired-callback="onRecaptchaExpired"></div>
  <script>
    function onRecaptchaSuccess(token) { RecaptchaChannel.postMessage(token); }
    function onRecaptchaExpired() { RecaptchaChannel.postMessage(''); }

    // The image challenge lives in a "bframe" iframe whose wrapper Google
    // toggles between visibility hidden/visible.
    var challengeOpen = false;
    setInterval(function () {
      var frame = document.querySelector('iframe[src*="bframe"]');
      var wrapper = frame && frame.parentNode && frame.parentNode.parentNode;
      var open = !!wrapper && getComputedStyle(wrapper).visibility !== 'hidden' && wrapper.style.opacity !== '0';
      if (open !== challengeOpen) {
        challengeOpen = open;
        RecaptchaChannel.postMessage(open ? 'challenge:open' : 'challenge:closed');
      }
    }, 250);
  </script>
</body>
</html>
''';

/// Shows the reCAPTCHA checkbox in a dialog and resolves with the verified
/// token once the user completes it, or null if they cancel/dismiss.
Future<String?> showRecaptchaDialog(BuildContext context) {
  return showDialog<String>(context: context, barrierDismissible: true, builder: (context) => const _RecaptchaDialog());
}

class _RecaptchaDialog extends StatefulWidget {
  const _RecaptchaDialog();

  @override
  State<_RecaptchaDialog> createState() => _RecaptchaDialogState();
}

class _RecaptchaDialogState extends State<_RecaptchaDialog> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _challenge = false;

  /// The checkbox widget is 304×78; a little extra for its shadow.
  static const _checkboxHeight = 84.0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'RecaptchaChannel',
        onMessageReceived: (message) {
          if (!mounted) return;
          final m = message.message;
          if (m == 'challenge:open' || m == 'challenge:closed') {
            setState(() => _challenge = m == 'challenge:open');
          } else if (m.isNotEmpty) {
            Navigator.of(context).pop(m);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // api.js still needs a moment to draw the checkbox after load.
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) setState(() => _loading = false);
            });
          },
        ),
      )
      ..loadHtmlString(_recaptchaHtml(Palette.dark), baseUrl: 'https://lootapp-ui.vercel.app');
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    // Google's image challenge needs roughly 400×580; cap to the screen.
    final challengeHeight = (screenH * 0.72).clamp(420.0, 600.0);

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 6, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick security check',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text("Tick the box to confirm you're not a robot.", style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted, height: 1.35)),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, color: AppColors.inkFaint),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                height: _challenge ? challengeHeight : _checkboxHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: WebViewWidget(controller: _controller)),
                    if (_loading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: const BrandSpinner(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 12, color: AppColors.inkFaint),
                    const SizedBox(width: 4),
                    Text('Keeps your account safe from bots', style: TextStyle(fontSize: 11, color: AppColors.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
