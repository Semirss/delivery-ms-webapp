import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

@singleton
class DebugService {
  // late ShakeDetector _detector;

  late File errorLogs, allLogs;
  DebugService() {
    setEnvironment().then((value) async {
      if (!value) {
        // _detector = ShakeDetector.autoStart(
        //   onPhoneShake: () => openDebugSheet(),
        // );
      }
    });
  }
  bool isProduction = true;

  Future<bool> setEnvironment() async {
    isProduction = await PackageInfo.fromPlatform().then((value) {
      return value.packageName.contains('.prod');
    });
    return false;
  }

  // downloadErrorLogs() async {
  //   try {
  //     var directory = await getApplicationDocumentsDirectory();
  //     errorLogs = File("${directory.path}/error_logs.txt");
  //     allLogs = File("${directory.path}/all_logs.txt");
  //     var downloadDirectory = await getDownloadsDirectory();
  //     errorLogs.copySync(
  //         "${downloadDirectory!.path}/${errorLogs.path.getPathSinceLastDirectory()}");
  //     allLogs.copySync(
  //         "${downloadDirectory.path}/${errorLogs.path.getPathSinceLastDirectory()}");
  //     toast("Success", "Logs saved to downloads folder");
  //   } catch (e) {
  //     toast("title", e.toString());
  //     outlog(e);
  //   }
  // }

  String get baseUrl => dotenv.env[isProduction
      ? 'PROD_BASE_URL'
      : const bool.fromEnvironment('dart.vm.product')
          ? 'DEV_BASE_URL'
          : 'DEV_BASE_URL']!;



  List<String> _errorStack = [];
  List<String> get errorStack => _errorStack;
  // Function to add an error to the stream
  void addError(String error) {
    _errorStack.add(error);
  }

  // Close the StreamController when it's no longer needed
  void dispose() {
    _errorStack = [];
    // _detector.stopListening();
  }
}
