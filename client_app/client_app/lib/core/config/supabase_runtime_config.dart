import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig({
    required this.url,
    required this.anonKey,
    required this.source,
    this.updatedAt,
  });

  final String url;
  final String anonKey;
  final String source;
  final DateTime? updatedAt;
}

class SupabaseRuntimeConfigResolver {
  const SupabaseRuntimeConfigResolver();

  Future<SupabaseRuntimeConfig> resolve() async {
    return _fallbackConfig();
  }

  SupabaseRuntimeConfig _fallbackConfig() {
    final url = _env('SUPABASE_URL');
    final anonKey = _env('SUPABASE_ANON_KEY');
    if (!_looksLikeSupabaseConfig(url, anonKey)) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Create .env from '
        '.env.example and use the same Supabase project as the webapp.',
      );
    }
    _assertEnvironment(url, _env('API_BASE_URL'), _env('ENVIRONMENT'));

    return SupabaseRuntimeConfig(url: url, anonKey: anonKey, source: 'env');
  }

  String _env(String key, {String fallback = ''}) {
    final dartDefine = _dartDefine(key);
    return dartDefine.isNotEmpty ? dartDefine.trim() : fallback.trim();
  }

  String _dartDefine(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment('SUPABASE_ANON_KEY');
      case 'API_BASE_URL':
        return const String.fromEnvironment('API_BASE_URL');
      case 'ENVIRONMENT':
        return const String.fromEnvironment('ENVIRONMENT');
    }
    return '';
  }

  void _assertEnvironment(
    String supabaseUrl,
    String apiUrl,
    String environment,
  ) {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        appFlavor != (environment == 'test' ? 'staging' : environment)) {
      throw StateError('Android flavor and ENVIRONMENT must match.');
    }
    const productionSupabaseHost = 'smkfvvblyudecimcfman.supabase.co';
    const testSupabaseHost = 'mtbqqharhxijulpaqdrm.supabase.co';
    const productionApiHost = 'motobikedeliveryservice.com';
    const testApiHost = 'moto-bike-test.vercel.app';
    final supabaseHost = Uri.parse(supabaseUrl).host.toLowerCase();
    final apiUri = Uri.tryParse(apiUrl);
    final apiHost = apiUri?.host.toLowerCase() ?? '';
    if (apiUri?.scheme != 'https') {
      throw StateError('API endpoint must use HTTPS.');
    }
    final isProductionSupabase = supabaseHost == productionSupabaseHost;
    final isTestSupabase = supabaseHost == testSupabaseHost;
    final isProductionApi =
        apiHost == productionApiHost || apiHost == 'www.$productionApiHost';
    if (environment == 'production') {
      if (!isProductionSupabase || !isProductionApi) {
        throw StateError('Production app endpoints do not match production.');
      }
    } else if (environment == 'test') {
      if (!isTestSupabase || apiHost != testApiHost) {
        throw StateError('Test app endpoints do not match test.');
      }
    } else {
      throw StateError('Set ENVIRONMENT to production or test.');
    }
  }

  bool _looksLikeSupabaseConfig(String url, String anonKey) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        anonKey.length > 20;
  }
}
