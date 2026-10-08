import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
const _recaptchaHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background: transparent;
    }
  </style>
</head>
<body>
  <div class="g-recaptcha"
       data-sitekey="$_recaptchaSiteKey"
       data-callback="onRecaptchaSuccess"
       data-expired-callback="onRecaptchaExpired"></div>
  <script>
    function onRecaptchaSuccess(token) {
      RecaptchaChannel.postMessage(token);
    }
    function onRecaptchaExpired() {
      RecaptchaChannel.postMessage('');
    }
  </script>
</body>
</html>
''';

/// Shows the reCAPTCHA checkbox in a dialog and resolves with the verified
/// token once the user completes it, or null if they cancel/dismiss.
Future<String?> showRecaptchaDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _RecaptchaDialog(),
  );
}

class _RecaptchaDialog extends StatefulWidget {
  const _RecaptchaDialog();

  @override
  State<_RecaptchaDialog> createState() => _RecaptchaDialogState();
}

class _RecaptchaDialogState extends State<_RecaptchaDialog> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'RecaptchaChannel',
        onMessageReceived: (message) {
          if (message.message.isNotEmpty && mounted) {
            Navigator.of(context).pop(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_recaptchaHtml, baseUrl: 'https://lootapp-ui.vercel.app');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 320,
        height: 420,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: WebViewWidget(controller: _controller),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
