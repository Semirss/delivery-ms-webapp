import 'package:flutter/material.dart';
import 'package:client_app/config/router/app_navigator.dart';

extension NavigationHelper on BuildContext {
  AppNavigator get navigator => AppNavigatorImpl(this);
}

