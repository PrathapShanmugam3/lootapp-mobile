// Google reCAPTCHA v2 checkbox dialog. `webview_flutter` has no web
// platform implementation, so the web build renders the checkbox directly
// via the browser's own grecaptcha script instead of hosting it in a
// WebView — see recaptcha_dialog_web.dart / recaptcha_dialog_io.dart.
export 'recaptcha_dialog_io.dart' if (dart.library.js_util) 'recaptcha_dialog_web.dart';
