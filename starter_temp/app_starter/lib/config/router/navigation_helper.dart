import 'package:flutter/material.dart';
import 'package:app_starter/config/router/app_navigator.dart';

extension NavigationHelper on BuildContext {
  AppNavigator get navigator => AppNavigatorImpl(this);
}

