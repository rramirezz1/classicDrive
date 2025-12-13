import 'package:flutter/material.dart';

/// Classe Result para operações que podem falhar.
/// Encapsula sucesso ou erro de forma type-safe.
sealed class Result<T> {
  const Result();

  /// Cria um resultado de sucesso.
  factory Result.success(T data) = Success<T>;

  /// Cria um resultado de erro.
  factory Result.failure(AppException error) = Failure<T>;

  /// Verifica se é sucesso.
  bool get isSuccess => this is Success<T>;

  /// Verifica se é falha.
  bool get isFailure => this is Failure<T>;

  /// Obtém o dado se sucesso, null se falha.
  T? get data => isSuccess ? (this as Success<T>).value : null;

  /// Obtém o erro se falha, null se sucesso.
  AppException? get error => isFailure ? (this as Failure<T>).exception : null;

  /// Aplica função ao sucesso, retorna fallback em falha.
  R fold<R>(R Function(T data) onSuccess, R Function(AppException error) onFailure) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failure<T>).exception);
    }
  }

  /// Transforma o dado de sucesso.
  Result<R> map<R>(R Function(T data) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    } else {
      return Result.failure((this as Failure<T>).exception);
    }
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

/// Exceção personalizada da aplicação.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Erro de rede.
  factory AppException.network([String? details]) => AppException(
        message: 'Erro de ligação à internet${details != null ? ': $details' : ''}',
        code: 'NETWORK_ERROR',
      );

  /// Erro de servidor.
  factory AppException.server([String? details]) => AppException(
        message: 'Erro no servidor${details != null ? ': $details' : ''}',
        code: 'SERVER_ERROR',
      );

  /// Erro de autenticação.
  factory AppException.auth([String? details]) => AppException(
        message: details ?? 'Sessão expirada. Faça login novamente.',
        code: 'AUTH_ERROR',
      );

  /// Erro de validação.
  factory AppException.validation(String field, String reason) => AppException(
        message: '$field: $reason',
        code: 'VALIDATION_ERROR',
      );

  /// Erro de não encontrado.
  factory AppException.notFound([String? resource]) => AppException(
        message: '${resource ?? 'Recurso'} não encontrado',
        code: 'NOT_FOUND',
      );

  /// Erro de permissão.
  factory AppException.unauthorized([String? action]) => AppException(
        message: 'Sem permissão${action != null ? ' para $action' : ''}',
        code: 'UNAUTHORIZED',
      );

  /// Erro de timeout.
  factory AppException.timeout() => const AppException(
        message: 'Tempo de espera excedido',
        code: 'TIMEOUT',
      );

  /// Erro desconhecido.
  factory AppException.unknown([dynamic error]) => AppException(
        message: 'Ocorreu um erro inesperado',
        code: 'UNKNOWN',
        originalError: error,
      );

  @override
  String toString() => message;
}

/// Estado de carregamento para widgets.
enum LoadingState {
  initial,
  loading,
  success,
  error,
}

/// Mixin para gerir estados de loading em StatefulWidgets.
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;

  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isSuccess => _loadingState == LoadingState.success;

  /// Define estado como loading.
  void setLoading() {
    if (mounted) {
      setState(() {
        _loadingState = LoadingState.loading;
        _errorMessage = null;
      });
    }
  }

  /// Define estado como sucesso.
  void setSuccess() {
    if (mounted) {
      setState(() {
        _loadingState = LoadingState.success;
        _errorMessage = null;
      });
    }
  }

  /// Define estado como erro.
  void setError(String message) {
    if (mounted) {
      setState(() {
        _loadingState = LoadingState.error;
        _errorMessage = message;
      });
    }
  }

  /// Reseta para estado inicial.
  void resetState() {
    if (mounted) {
      setState(() {
        _loadingState = LoadingState.initial;
        _errorMessage = null;
      });
    }
  }

  /// Executa operação async com loading automático.
  Future<void> runAsync(Future<void> Function() operation) async {
    setLoading();
    try {
      await operation();
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Executa operação com Result e loading automático.
  Future<Result<R>> runWithResult<R>(Future<Result<R>> Function() operation) async {
    setLoading();
    try {
      final result = await operation();
      result.fold(
        (data) => setSuccess(),
        (error) => setError(error.message),
      );
      return result;
    } catch (e) {
      final exception = AppException.unknown(e);
      setError(exception.message);
      return Result.failure(exception);
    }
  }
}

/// Controller para formulários com validação.
class FormController extends ChangeNotifier {
  final Map<String, String?> _errors = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;
  bool _isValid = false;

  bool get isSubmitting => _isSubmitting;
  bool get isValid => _isValid && _errors.values.every((e) => e == null);
  Map<String, String?> get errors => Map.unmodifiable(_errors);

  /// Regista um campo.
  TextEditingController registerField(String name, {String? initialValue}) {
    if (!_controllers.containsKey(name)) {
      _controllers[name] = TextEditingController(text: initialValue);
    }
    return _controllers[name]!;
  }

  /// Obtém o valor de um campo.
  String getValue(String name) => _controllers[name]?.text ?? '';

  /// Define valor de um campo.
  void setValue(String name, String value) {
    _controllers[name]?.text = value;
    notifyListeners();
  }

  /// Define erro de um campo.
  void setFieldError(String name, String? error) {
    _errors[name] = error;
    notifyListeners();
  }

  /// Obtém erro de um campo.
  String? getFieldError(String name) => _errors[name];

  /// Limpa erros.
  void clearErrors() {
    _errors.clear();
    notifyListeners();
  }

  /// Valida todos os campos com validadores fornecidos.
  bool validate(Map<String, String? Function(String?)> validators) {
    _errors.clear();
    for (final entry in validators.entries) {
      final error = entry.value(getValue(entry.key));
      if (error != null) {
        _errors[entry.key] = error;
      }
    }
    _isValid = _errors.isEmpty;
    notifyListeners();
    return _isValid;
  }

  /// Obtém todos os valores como Map.
  Map<String, String> get values {
    return _controllers.map((key, controller) => MapEntry(key, controller.text));
  }

  /// Define estado de submissão.
  void setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  /// Reseta o formulário.
  void reset() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _errors.clear();
    _isSubmitting = false;
    _isValid = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

/// Debouncer para operações como pesquisa.
class Debouncer {
  final Duration delay;
  VoidCallback? _action;
  bool _isDebouncing = false;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _action = action;
    if (!_isDebouncing) {
      _isDebouncing = true;
      Future.delayed(delay, () {
        _action?.call();
        _isDebouncing = false;
      });
    }
  }

  void cancel() {
    _action = null;
  }
}

/// Throttler para limitar frequência de chamadas.
class Throttler {
  final Duration interval;
  DateTime? _lastRun;

  Throttler({this.interval = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) >= interval) {
      _lastRun = now;
      action();
    }
  }
}
