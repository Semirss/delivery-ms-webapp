import 'dart:html' as html;
import 'dart:js_interop';

@JS('motobikePwaCanPrompt')
external bool _motobikePwaCanPrompt();

@JS('motobikePwaIsStandalone')
external bool _motobikePwaIsStandalone();

@JS('motobikePwaPromptInstall')
external JSPromise<JSAny?> _motobikePwaPromptInstall();

class PwaInstallState {
  const PwaInstallState({
    this.isWeb = true,
    required this.isStandalone,
    required this.isIos,
    required this.isSafari,
    required this.canPrompt,
  });

  final bool isWeb;
  final bool isStandalone;
  final bool isIos;
  final bool isSafari;
  final bool canPrompt;
}

Future<PwaInstallState> getPwaInstallState() async {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  final platform = html.window.navigator.platform?.toLowerCase() ?? '';
  final maxTouchPoints = html.window.navigator.maxTouchPoints ?? 0;
  final isIos = userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod') ||
      (platform.contains('mac') && maxTouchPoints > 1);
  final isSafari = userAgent.contains('safari') &&
      !userAgent.contains('crios') &&
      !userAgent.contains('fxios') &&
      !userAgent.contains('edgios');

  return PwaInstallState(
    isStandalone: _boolCall('motobikePwaIsStandalone'),
    isIos: isIos,
    isSafari: isSafari,
    canPrompt: _boolCall('motobikePwaCanPrompt'),
  );
}

Future<bool> promptPwaInstall() async {
  await _motobikePwaPromptInstall().toDart;
  return true;
}

bool _boolCall(String name) {
  try {
    return switch (name) {
      'motobikePwaCanPrompt' => _motobikePwaCanPrompt(),
      'motobikePwaIsStandalone' => _motobikePwaIsStandalone(),
      _ => false,
    };
  } catch (_) {
    return false;
  }
}
