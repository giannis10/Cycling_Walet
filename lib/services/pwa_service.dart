import 'package:flutter/foundation.dart';

import 'pwa_web_stub.dart' if (dart.library.html) 'pwa_web.dart' as web;

class PwaService {
  PwaService._();

  static final PwaService instance = PwaService._();

  void init() {
    if (kIsWeb) {
      web.init();
    }
  }

  bool get isInstalled {
    if (!kIsWeb) {
      return true;
    }
    return web.isInstalled();
  }

  bool get canInstall {
    if (!kIsWeb) {
      return false;
    }
    return web.canInstall();
  }

  bool get isIos {
    if (!kIsWeb) {
      return false;
    }
    return web.isIos();
  }

  Future<bool> promptInstall() async {
    if (!kIsWeb) {
      return false;
    }
    return web.promptInstall();
  }
}
