import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Google reCAPTCHA v2 site key — same key the Next.js UI uses
/// (lootapp-ui/.env.local NEXT_PUBLIC_RECAPTCHA_SITE_KEY), so tokens verify
/// against the same backend RECAPTCHA_SECRET_KEY.
const _recaptchaSiteKey = '6LeLlIAtAAAAAOYJQ89hodWYdVZLeMdnmS2xIJKt';

@JS('grecaptcha')
external JSObject? get _grecaptcha;

@JS('grecaptcha.render')
external int _grecaptchaRender(String containerId, _RenderOptions options);

@JS('grecaptcha.reset')
external void _grecaptchaReset(int widgetId);

extension type _RenderOptions._(JSObject _) implements JSObject {
  external factory _RenderOptions({
    required String sitekey,
    required JSFunction callback,
    required JSFunction expiredCallback,
  });
}

/// True once the page-level `grecaptcha` global (loaded via api.js in
/// web/index.html) is ready to use.
bool _isGrecaptchaReady() => _grecaptcha != null;

/// On web, the real captcha can render directly in the page (no WebView
/// needed), so callers should prefer [RecaptchaInlineWidget] over popping
/// [showRecaptchaDialog] — avoids a redundant dialog on top of an already
/// visible "I'm not a robot" row.
const kRecaptchaInline = true;

/// Shows the reCAPTCHA checkbox in a dialog and resolves with the verified
/// token once the user completes it, or null if they cancel/dismiss.
///
/// Flutter web has no WebView to host the api.js widget inside (unlike
/// mobile/desktop), but the host page itself already runs inside a real
/// browser — index.html loads https://www.google.com/recaptcha/api.js at
/// page level, and this renders the checkbox directly into an HtmlElementView
/// via grecaptcha.render(), reading the token back through the JS callback.
///
/// Prefer [RecaptchaInlineWidget] on web — this dialog form is kept for any
/// caller that still wants the popup flow (e.g. a bare "verify" button with
/// no inline checkbox row of its own).
Future<String?> showRecaptchaDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _RecaptchaDialog(),
  );
}

/// Renders the real reCAPTCHA widget inline (web only) — no dialog. Calls
/// [onToken] with the verified token, or null when it expires/resets.
class RecaptchaInlineWidget extends StatefulWidget {
  const RecaptchaInlineWidget({super.key, required this.onToken});

  final ValueChanged<String?> onToken;

  @override
  State<RecaptchaInlineWidget> createState() => _RecaptchaInlineWidgetState();
}

class _RecaptchaInlineWidgetState extends State<RecaptchaInlineWidget> {
  static int _instanceCounter = 0;

  late final String _viewType;
  late final String _containerId;
  int? _widgetId;
  Timer? _pollTimer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final id = _instanceCounter++;
    _viewType = 'recaptcha-inline-$id';
    _containerId = 'recaptcha-inline-div-$id';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return web.HTMLDivElement()..id = _containerId;
    });

    _pollForGrecaptcha();
  }

  void _pollForGrecaptcha() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isGrecaptchaReady()) {
        timer.cancel();
        _render();
      }
    });
  }

  void _render() {
    try {
      _widgetId = _grecaptchaRender(
        _containerId,
        _RenderOptions(
          sitekey: _recaptchaSiteKey,
          callback: ((JSString token) {
            if (mounted) widget.onToken(token.toDart);
          }).toJS,
          expiredCallback: (() {
            if (mounted && _widgetId != null) _grecaptchaReset(_widgetId!);
            widget.onToken(null);
          }).toJS,
        ),
      );
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      Future.delayed(const Duration(milliseconds: 150), _render);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 304,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          HtmlElementView(viewType: _viewType),
          if (!_ready) const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    );
  }
}

class _RecaptchaDialog extends StatefulWidget {
  const _RecaptchaDialog();

  @override
  State<_RecaptchaDialog> createState() => _RecaptchaDialogState();
}

class _RecaptchaDialogState extends State<_RecaptchaDialog> {
  static int _instanceCounter = 0;

  late final String _viewType;
  late final String _containerId;
  int? _widgetId;
  Timer? _pollTimer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final id = _instanceCounter++;
    _viewType = 'recaptcha-container-$id';
    _containerId = 'recaptcha-div-$id';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return web.HTMLDivElement()..id = _containerId;
    });

    _pollForGrecaptcha();
  }

  void _pollForGrecaptcha() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isGrecaptchaReady()) {
        timer.cancel();
        _render();
      }
    });
  }

  void _render() {
    try {
      _widgetId = _grecaptchaRender(
        _containerId,
        _RenderOptions(
          sitekey: _recaptchaSiteKey,
          callback: ((JSString token) {
            if (mounted) Navigator.of(context).pop(token.toDart);
          }).toJS,
          expiredCallback: (() {
            if (mounted && _widgetId != null) _grecaptchaReset(_widgetId!);
          }).toJS,
        ),
      );
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Container not attached to the DOM yet — retry on next frame.
      Future.delayed(const Duration(milliseconds: 150), _render);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
            Center(
              child: SizedBox(
                width: 304,
                height: 78,
                child: HtmlElementView(viewType: _viewType),
              ),
            ),
            if (!_ready) const Center(child: CircularProgressIndicator()),
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
