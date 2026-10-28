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
    final defined = switch (key) {
      'SUPABASE_URL' => const String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY' => const String.fromEnvironment('SUPABASE_ANON_KEY'),
      'API_BASE_URL' => const String.fromEnvironment('API_BASE_URL'),
      'ENVIRONMENT' => const String.fromEnvironment('ENVIRONMENT'),
      _ => '',
    };
    return (defined.isNotEmpty ? defined : fallback).trim();
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
    const productionApiHost = 'motobikedeliveryservice.com';
    final supabaseHost = Uri.parse(supabaseUrl).host.toLowerCase();
    final apiHost = Uri.tryParse(apiUrl)?.host.toLowerCase() ?? '';
    final isProductionSupabase = supabaseHost == productionSupabaseHost;
    final isProductionApi =
        apiHost == productionApiHost || apiHost == 'www.$productionApiHost';
    if (environment == 'production') {
      if (!isProductionSupabase || !isProductionApi) {
        throw StateError('Production app endpoints do not match production.');
      }
    } else if (environment == 'test') {
      if (isProductionSupabase || isProductionApi || apiHost.isEmpty) {
        throw StateError('Test app cannot use production endpoints.');
      }
    } else {
      throw StateError('Set ENVIRONMENT to production or test.');
    }
  }

  bool _looksLikeSupabaseConfig(String url, String anonKey) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        anonKey.length > 20;
  }
}
