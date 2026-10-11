import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The real reCAPTCHA checkbox renders inside the Sign In / Create Account
/// box on mobile too (in a small WebView), same as web — no popup.
/// [showRecaptchaDialog] below stays for screens without an inline row
/// (Forgot password, Delete account).
const kRecaptchaInline = true;

/// Real reCAPTCHA v2 checkbox, inline. The WebView is just checkbox-sized
/// (78px); when Google opens its picture challenge it's given its full size,
/// scaled to the box width and pinned to the top, and the WebView grows to
/// exactly that height, so it's never squashed or clipped. [onToken] gets the token, or null when it expires.
class RecaptchaInlineWidget extends StatefulWidget {
  const RecaptchaInlineWidget({super.key, required this.onToken});

  final ValueChanged<String?> onToken;

  @override
  State<RecaptchaInlineWidget> createState() => _RecaptchaInlineWidgetState();
}

class _RecaptchaInlineWidgetState extends State<RecaptchaInlineWidget> {
  late final WebViewController _controller;
  bool _loading = true;

  /// Height the open picture challenge needs (reported by the page), or
  /// null while only the checkbox is showing.
  double? _challengeHeight;

  static const _checkboxHeight = 78.0;

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
          if (m.startsWith('challenge:')) {
            setState(() => _challengeHeight = m.startsWith('challenge:open:') ? double.tryParse(m.substring(15)) : null);
          } else {
            widget.onToken(m.isEmpty ? null : m);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _loading = false);
          }),
        ),
      )
      ..loadHtmlString(_inlineHtml, baseUrl: 'https://lootapp-ui.vercel.app');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: _challengeHeight ?? _checkboxHeight,
      child: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _controller)),
          if (_loading) const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
        ],
      ),
    );
  }
}

/// Inline page: the checkbox top-left, scaled down if the box is narrower
/// than Google's fixed 304px widget, plus a watcher that reports the picture
/// challenge opening/closing and keeps it pinned at the top of the view.
const _inlineHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <style>
    html, body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
    #box { transform-origin: left top; display: inline-block; }
  </style>
</head>
<body>
  <div id="box">
    <div class="g-recaptcha"
         data-sitekey="$_recaptchaSiteKey"
         data-callback="onRecaptchaSuccess"
         data-expired-callback="onRecaptchaExpired"></div>
  </div>
  <script>
    function onRecaptchaSuccess(token) { RecaptchaChannel.postMessage(token); }
    function onRecaptchaExpired() { RecaptchaChannel.postMessage(''); }

    function fit() {
      var s = Math.min(1, window.innerWidth / 304);
      document.getElementById('box').style.transform = 'scale(' + s + ')';
    }
    window.addEventListener('load', fit);
    window.addEventListener('resize', fit);
    fit();

    // Google sizes the picture challenge to the view it opens in — here
    // only the 78px checkbox — which squashes it to just its header. So
    // while it's open: give it its normal 400x580 size (or larger, if
    // Google asks for more), scale it to the view's width, pin it top-left,
    // and tell Flutter how tall to make the view.
    var reported = -1;
    setInterval(function () {
      var frame = document.querySelector('iframe[src*="bframe"]');
      var inner = frame && frame.parentNode;
      var wrapper = inner && inner.parentNode;
      var isOpen = !!wrapper && getComputedStyle(wrapper).visibility !== 'hidden';
      var height = 0;
      if (isOpen) {
        var w = 400;
        var h = Math.max(580, parseInt(frame.style.height || '0', 10) || 0);
        frame.style.width = w + 'px';
        frame.style.height = h + 'px';
        inner.style.width = w + 'px';
        inner.style.height = h + 'px';
        var scale = Math.min(1, window.innerWidth / w);
        wrapper.style.position = 'fixed';
        wrapper.style.top = '0px';
        wrapper.style.left = '0px';
        wrapper.style.transformOrigin = '0 0';
        wrapper.style.transform = 'scale(' + scale + ')';
        height = Math.ceil(h * scale);
      }
      if (height !== reported) {
        reported = height;
        RecaptchaChannel.postMessage(height > 0 ? 'challenge:open:' + height : 'challenge:closed');
      }
    }, 100);
  </script>
</body>
</html>
''';

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
