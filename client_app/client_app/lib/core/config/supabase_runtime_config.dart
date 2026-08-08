import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    if (kIsWeb) {
      final webConfig = await _webRuntimeConfig();
      if (webConfig != null) return webConfig;
    }

    final masterUrl = _env('MASTER_SUPABASE_URL');
    final masterAnonKey = _env('MASTER_SUPABASE_ANON_KEY');

    if (masterUrl.isEmpty || masterAnonKey.isEmpty) {
      return _fallbackConfig();
    }

    try {
      final configView = _env(
        'MASTER_BACKEND_CONFIG_VIEW',
        fallback: 'public_backend_runtime_config',
      );
      final normalizedMasterUrl = _withoutTrailingSlash(masterUrl);
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
          headers: {
            'apikey': masterAnonKey,
            'Authorization': 'Bearer $masterAnonKey',
            'Accept': 'application/json',
          },
        ),
      ).get<List<dynamic>>(
        '$normalizedMasterUrl/rest/v1/$configView'
        '?select=supabase_url,supabase_anon_key,updated_at'
        '&limit=1',
      );

      final rows = response.data ?? const [];
      if (rows.isEmpty || rows.first is! Map) return _fallbackConfig();

      final row = Map<String, dynamic>.from(rows.first as Map);
      final url = row['supabase_url']?.toString().trim() ?? '';
      final anonKey = row['supabase_anon_key']?.toString().trim() ?? '';
      if (!_looksLikeSupabaseConfig(url, anonKey)) return _fallbackConfig();

      return SupabaseRuntimeConfig(
        url: url,
        anonKey: anonKey,
        source: 'master',
        updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
      );
    } catch (_) {
      return _fallbackConfig();
    }
  }

  Future<SupabaseRuntimeConfig?> _webRuntimeConfig() async {
    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      ).get<dynamic>('/api/public/backend-config');

      final data = response.data;
      if (data is! Map) return null;

      final url = data['supabaseUrl']?.toString().trim() ?? '';
      final anonKey = data['supabaseAnonKey']?.toString().trim() ?? '';
      if (!_looksLikeSupabaseConfig(url, anonKey)) return null;
      final source = data['source']?.toString().trim();

      return SupabaseRuntimeConfig(
        url: url,
        anonKey: anonKey,
        source: (source?.isNotEmpty ?? false) ? 'web-$source' : 'web',
        updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
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

    return SupabaseRuntimeConfig(
      url: url,
      anonKey: anonKey,
      source: 'env',
    );
  }

  String _env(String key, {String fallback = ''}) {
    final dartDefine = _dartDefine(key);
    final effectiveFallback = dartDefine.isNotEmpty ? dartDefine : fallback;
    try {
      return (dotenv.env[key] ?? effectiveFallback).trim();
    } catch (_) {
      return effectiveFallback.trim();
    }
  }

  String _dartDefine(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment('SUPABASE_ANON_KEY');
      case 'MASTER_SUPABASE_URL':
        return const String.fromEnvironment('MASTER_SUPABASE_URL');
      case 'MASTER_SUPABASE_ANON_KEY':
        return const String.fromEnvironment('MASTER_SUPABASE_ANON_KEY');
      case 'MASTER_BACKEND_CONFIG_VIEW':
        return const String.fromEnvironment('MASTER_BACKEND_CONFIG_VIEW');
    }
    return '';
  }

  String _withoutTrailingSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  bool _looksLikeSupabaseConfig(String url, String anonKey) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        anonKey.length > 20;
  }
}
