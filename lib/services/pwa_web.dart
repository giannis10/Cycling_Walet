import 'dart:html' as html;
import 'dart:js_util' as js_util;

dynamic _deferredPrompt;
bool _initialized = false;

void init() {
  if (_initialized) return;
  _initialized = true;
  html.window.addEventListener('beforeinstallprompt', (event) {
    event.preventDefault();
    _deferredPrompt = event;
  });
}

bool isInstalled() {
  final displayMode = html.window.matchMedia('(display-mode: standalone)');
  final isStandalone = displayMode.matches;
  final iosStandalone =
      js_util.getProperty(html.window.navigator, 'standalone') == true;
  return isStandalone || iosStandalone;
}

bool canInstall() => _deferredPrompt != null;

bool isIos() {
  final platform = (html.window.navigator.platform ?? '').toLowerCase();
  final isAppleDevice = platform.contains('iphone') ||
      platform.contains('ipad') ||
      platform.contains('ipod');
  if (isAppleDevice) {
    return true;
  }

  // iPadOS 13+ reports MacIntel, use touch points as fallback.
  final isMac = platform.contains('mac');
  final hasTouch =
      (html.window.navigator.maxTouchPoints ?? 0) > 1;
  return isMac && hasTouch;
}

Future<bool> promptInstall() async {
  if (_deferredPrompt == null) {
    return false;
  }
  final promptEvent = _deferredPrompt!;
  _deferredPrompt = null;
  try {
    js_util.callMethod(promptEvent, 'prompt', []);
    final userChoice =
        await js_util.promiseToFuture(js_util.getProperty(promptEvent, 'userChoice'));
    final outcome = js_util.getProperty(userChoice, 'outcome') as String?;
    return outcome == 'accepted';
  } catch (_) {
    return false;
  }
}
