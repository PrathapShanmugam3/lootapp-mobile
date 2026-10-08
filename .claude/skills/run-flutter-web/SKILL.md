---
name: run-flutter-web
description: Launch and screenshot the loothat_flutter app in headless Chrome to verify a UI change actually renders. Use when asked to run, preview, or check the Flutter app (or specifically its web build) in this repo.
---

# Running loothat_flutter on web

This Flutter app (`loothat_flutter/`) talks to the deployed backend by
default (`https://lootapp-api.vercel.app`), so no local API server is
needed just to preview UI.

## One-time setup (already done as of 2026-10-07)

Web platform support was added via `flutter create . --platforms=web`,
which created `web/`. Without it, `flutter run -d chrome` fails with
"This application is not configured to build on the web."

`lib/core/network/api_client.dart` was patched to skip
`path_provider`/`PersistCookieJar` on web (`kIsWeb`) — the stock code
called `getApplicationDocumentsDirectory()` unconditionally, which has
no web implementation and throws `MissingPluginException` at startup.
On web the browser's own cookie jar carries the httpOnly session
cookie automatically; dio is configured with
`options.extra['withCredentials'] = true` instead.

If these are ever reverted, redo them before trying to run on web.

## Launch

```bash
cd loothat_flutter
flutter run -d chrome --web-port=8765 --web-browser-flag="--headless=new" \
  > /tmp/flutter_run.log 2>&1 &
disown
```

Wait for `Dart VM Service on Chrome` in the log (takes ~15-25s). Watch
for `Exception`/`Error`/`RenderFlex overflow` lines too — a clean run
has none of those.

```bash
until grep -qE "Dart VM Service on Chrome|Error|Exception" /tmp/flutter_run.log; do sleep 1; done
```

The dev server is now serving the compiled app at
`http://localhost:8765` (confirm with `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765` — expect `200`).

## Screenshot it

No browser-automation MCP tool is available in this environment, but
`google-chrome`/`chromium` are installed — drive them directly in
one-shot headless mode:

```bash
google-chrome --headless=new --disable-gpu --no-sandbox \
  --screenshot=/tmp/screenshot.png \
  --window-size=430,932 \
  --virtual-time-budget=25000 \
  --run-all-compositor-stages-before-draw \
  "http://localhost:8765"
```

Key gotcha: Flutter's web engine (CanvasKit) takes several seconds to
boot after the HTML loads. `--virtual-time-budget=8000` (or lower)
screenshots a near-blank frame (just the background color + loading
dot, ~2-3KB file). Use `--virtual-time-budget=20000` or higher —
~60KB+ output is a good sign the UI actually painted. If a run comes
back small/blank, just retry; it's a boot-timing race, not a code bug.

`--window-size=430,932` approximates a phone viewport, matching this
app's mobile-first layouts.

Then view the PNG with the Read tool.

## Cleanup

```bash
pkill -f "web-port=8765"
```

(Headless Chrome windows launched by `flutter run` and by the
screenshot command both exit with this/on their own after the
one-shot screenshot.)
