import 'package:intl/intl.dart';

/// Validadores de formulário comuns.
class FormValidators {
  /// Valida se o campo não está vazio.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Campo'} é obrigatório';
    }
    return null;
  }

  /// Valida formato de email.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Valida telefone português.
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    final phoneRegex = RegExp(r'^(\+351)?[0-9]{9}$');
    final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'Telefone inválido (9 dígitos)';
    }
    return null;
  }

  /// Valida comprimento mínimo.
  static String? minLength(String? value, int length, {String? fieldName}) {
    if (value == null || value.length < length) {
      return '${fieldName ?? 'Campo'} deve ter pelo menos $length caracteres';
    }
    return null;
  }

  /// Valida comprimento máximo.
  static String? maxLength(String? value, int length, {String? fieldName}) {
    if (value != null && value.length > length) {
      return '${fieldName ?? 'Campo'} não pode ter mais de $length caracteres';
    }
    return null;
  }

  /// Valida se é um número.
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Campo'} deve ser um número';
    }
    return null;
  }

  /// Valida valor mínimo.
  static String? minValue(String? value, double min, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    final numValue = double.tryParse(value);
    if (numValue == null || numValue < min) {
      return '${fieldName ?? 'Valor'} deve ser no mínimo ${min.toStringAsFixed(0)}';
    }
    return null;
  }

  /// Valida NIF português.
  static String? nif(String? value) {
    if (value == null || value.isEmpty) {
      return 'NIF é obrigatório';
    }
    if (value.length != 9 || int.tryParse(value) == null) {
      return 'NIF inválido (9 dígitos)';
    }
    // Validação do dígito de controlo
    final digits = value.split('').map(int.parse).toList();
    var sum = 0;
    for (var i = 0; i < 8; i++) {
      sum += digits[i] * (9 - i);
    }
    final checkDigit = 11 - (sum % 11);
    final expected = checkDigit >= 10 ? 0 : checkDigit;
    if (digits[8] != expected) {
      return 'NIF inválido';
    }
    return null;
  }

  /// Valida password com requisitos.
  static String? password(String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumber = true,
  }) {
    if (value == null || value.isEmpty) {
      return 'Password é obrigatória';
    }
    if (value.length < minLength) {
      return 'Password deve ter pelo menos $minLength caracteres';
    }
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password deve conter pelo menos uma maiúscula';
    }
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password deve conter pelo menos uma minúscula';
    }
    if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password deve conter pelo menos um número';
    }
    return null;
  }

  /// Valida confirmação de password.
  static String? confirmPassword(String? value, String? original) {
    if (value != original) {
      return 'As passwords não coincidem';
    }
    return null;
  }

  /// Combina múltiplos validadores.
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}

/// Formatadores de data.
class DateFormatters {
  static final _ptLocale = 'pt_PT';

  /// Formato completo: 13 de dezembro de 2025
  static String full(DateTime date) {
    return DateFormat.yMMMMd(_ptLocale).format(date);
  }

  /// Formato curto: 13/12/2025
  static String short(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formato com dia da semana: sexta, 13 de dezembro
  static String withWeekday(DateTime date) {
    return DateFormat.MMMMEEEEd(_ptLocale).format(date);
  }

  /// Apenas hora: 14:30
  static String time(DateTime date) {
    return DateFormat.Hm().format(date);
  }

  /// Data e hora: 13/12/2025 14:30
  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formato relativo: há 2 horas, ontem, etc.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dias';
    } else if (diff.inDays < 30) {
      return 'Há ${diff.inDays ~/ 7} semanas';
    } else if (diff.inDays < 365) {
      return 'Há ${diff.inDays ~/ 30} meses';
    } else {
      return 'Há ${diff.inDays ~/ 365} anos';
    }
  }

  /// Range de datas: 13 - 15 de dezembro
  static String range(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day} de ${DateFormat.MMMM(_ptLocale).format(end)}';
    } else if (start.year == end.year) {
      return '${DateFormat.MMMd(_ptLocale).format(start)} - ${DateFormat.MMMd(_ptLocale).format(end)}';
    } else {
      return '${short(start)} - ${short(end)}';
    }
  }

  /// Dias restantes.
  static String daysRemaining(DateTime futureDate) {
    final days = futureDate.difference(DateTime.now()).inDays;
    if (days < 0) {
      return 'Expirado';
    } else if (days == 0) {
      return 'Hoje';
    } else if (days == 1) {
      return 'Amanhã';
    } else {
      return 'Em $days dias';
    }
  }
}

/// Formatadores de moeda.
class MoneyFormatters {
  /// Formato de euro: €1.234,56
  static String euro(double value, {int decimals = 2}) {
    return NumberFormat.currency(
      locale: 'pt_PT',
      symbol: '€',
      decimalDigits: decimals,
    ).format(value);
  }

  /// Formato compacto: €1.2K, €1.5M
  static String compact(double value) {
    return NumberFormat.compactCurrency(
      locale: 'pt_PT',
      symbol: '€',
    ).format(value);
  }

  /// Apenas número com separadores: 1.234,56
  static String number(double value, {int decimals = 2}) {
    return NumberFormat.decimalPatternDigits(
      locale: 'pt_PT',
      decimalDigits: decimals,
    ).format(value);
  }

  /// Percentagem: 15,5%
  static String percent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Preço por dia: €150/dia
  static String pricePerDay(double value) {
    return '${euro(value, decimals: 0)}/dia';
  }
}

/// Helpers para strings.
extension StringHelpers on String {
  /// Primeira letra maiúscula.
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Cada palavra com maiúscula.
  String titleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncar com ellipsis.
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Remover acentos.
  String removeAccents() {
    const withAccents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
    const withoutAccents = 'aaaaaaceeeeiiiinooooouuuuyyAAAAAACEEEEIIIINOOOOOUUUUY';
    
    var result = this;
    for (var i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Verificar se é email válido.
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Verificar se é número.
  bool get isNumeric {
    return double.tryParse(this) != null;
  }
}

/// Helpers para DateTime.
extension DateTimeHelpers on DateTime {
  /// Início do dia.
  DateTime get startOfDay => DateTime(year, month, day);

  /// Fim do dia.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Início do mês.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Fim do mês.
  DateTime get endOfMonth => DateTime(year, month + 1, 0);

  /// Verificar se é hoje.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Verificar se é amanhã.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Verificar se é passado.
  bool get isPast => isBefore(DateTime.now());

  /// Verificar se é fim de semana.
  bool get isWeekend => weekday == DateTime.saturday || weekday == DateTime.sunday;

  /// Adicionar dias úteis.
  DateTime addBusinessDays(int days) {
    var result = this;
    var remaining = days;
    while (remaining > 0) {
      result = result.add(const Duration(days: 1));
      if (!result.isWeekend) remaining--;
    }
    return result;
  }
}

/// Helpers para listas.
extension ListHelpers<T> on List<T> {
  /// Agrupar por propriedade.
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }

  /// Primeiro elemento ou null.
  T? get firstOrNull => isEmpty ? null : first;

  /// Último elemento ou null.
  T? get lastOrNull => isEmpty ? null : last;

  /// Elemento por índice ou null.
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
