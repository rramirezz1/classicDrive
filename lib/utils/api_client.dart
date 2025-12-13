import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'result.dart';

/// Cliente HTTP simplificado com tratamento de erros.
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  String? _authToken;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Define token de autenticação.
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Obtém headers com autenticação.
  Map<String, String> get _headers {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// GET request.
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return Result.failure(AppException.timeout());
    } catch (e) {
      return Result.failure(AppException.network(e.toString()));
    }
  }

  /// POST request.
  Future<Result<T>> post<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return Result.failure(AppException.timeout());
    } catch (e) {
      return Result.failure(AppException.network(e.toString()));
    }
  }

  /// PUT request.
  Future<Result<T>> put<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return Result.failure(AppException.timeout());
    } catch (e) {
      return Result.failure(AppException.network(e.toString()));
    }
  }

  /// DELETE request.
  Future<Result<T>> delete<T>(
    String endpoint, {
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response =
          await http.delete(uri, headers: _headers).timeout(timeout);
      return _handleResponse(response, fromJson);
    } on TimeoutException {
      return Result.failure(AppException.timeout());
    } catch (e) {
      return Result.failure(AppException.network(e.toString()));
    }
  }

  /// Processa resposta HTTP.
  Result<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJson,
  ) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (fromJson != null) {
          final jsonData = json.decode(response.body);
          return Result.success(fromJson(jsonData));
        }
        return Result.success(json.decode(response.body) as T);
      case 204:
        return Result.success(null as T);
      case 400:
        return Result.failure(
          AppException.validation('Pedido', 'Dados inválidos'),
        );
      case 401:
        return Result.failure(AppException.auth());
      case 403:
        return Result.failure(AppException.unauthorized());
      case 404:
        return Result.failure(AppException.notFound());
      case 500:
      case 502:
      case 503:
        return Result.failure(AppException.server());
      default:
        return Result.failure(
          AppException(
            message: 'Erro HTTP ${response.statusCode}',
            code: 'HTTP_${response.statusCode}',
          ),
        );
    }
  }
}

/// Cache simples em memória.
class MemoryCache<T> {
  final Duration expiry;
  final Map<String, _CacheEntry<T>> _cache = {};

  MemoryCache({this.expiry = const Duration(minutes: 5)});

  /// Obtém valor do cache.
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiryTime)) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Guarda valor no cache.
  void set(String key, T value, {Duration? customExpiry}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiryTime: DateTime.now().add(customExpiry ?? expiry),
    );
  }

  /// Remove valor do cache.
  void remove(String key) {
    _cache.remove(key);
  }

  /// Limpa todo o cache.
  void clear() {
    _cache.clear();
  }

  /// Verifica se chave existe e não expirou.
  bool has(String key) {
    return get(key) != null;
  }

  /// Obtém ou calcula valor.
  Future<T> getOrCompute(String key, Future<T> Function() compute) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await compute();
    set(key, value);
    return value;
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiryTime;

  _CacheEntry({required this.value, required this.expiryTime});
}

/// Retry helper para operações que podem falhar.
class RetryHelper {
  /// Executa operação com retry automático.
  static Future<Result<T>> withRetry<T>(
    Future<Result<T>> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(AppException)? shouldRetry,
  }) async {
    var attempts = 0;
    Result<T>? lastResult;

    while (attempts < maxAttempts) {
      attempts++;
      lastResult = await operation();

      if (lastResult.isSuccess) {
        return lastResult;
      }

      final error = lastResult.error!;
      final canRetry = shouldRetry?.call(error) ?? 
          (error.code == 'NETWORK_ERROR' || error.code == 'TIMEOUT');

      if (!canRetry || attempts >= maxAttempts) {
        break;
      }

      await Future.delayed(delay * attempts);
    }

    return lastResult!;
  }
}

/// Connectivity checker.
class ConnectivityHelper {
  static Future<bool> hasInternet() async {
    try {
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
