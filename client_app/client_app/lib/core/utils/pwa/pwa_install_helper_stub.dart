class PwaInstallState {
  const PwaInstallState({
    this.isWeb = false,
    this.isStandalone = false,
    this.isIos = false,
    this.isSafari = false,
    this.canPrompt = false,
  });

  final bool isWeb;
  final bool isStandalone;
  final bool isIos;
  final bool isSafari;
  final bool canPrompt;
}

Future<PwaInstallState> getPwaInstallState() async {
  return const PwaInstallState();
}

Future<bool> promptPwaInstall() async {
  return false;
}
