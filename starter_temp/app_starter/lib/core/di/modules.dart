import 'package:chuck_interceptor/chuck_interceptor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../databases/cache/cache_helper.dart';

@module
abstract class RegisterModule {
  @singleton
  Chuck chuck() => Chuck();

  @singleton
  Connectivity connectivity() => Connectivity();
  
  @singleton
  Dio dio() => Dio();
  
  @preResolve
  Future<CacheHelper> cacheHelper() async {
    final helper = CacheHelper();
    await helper.init();
    return helper;
  }
}