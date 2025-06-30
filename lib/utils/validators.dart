class Validators {
  // Validar email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o email';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, insira um email válido';
    }

    return null;
  }

  // Validar password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira a palavra-passe';
    }

    if (value.length < 6) {
      return 'A palavra-passe deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  // Validar confirmação de password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirme a palavra-passe';
    }

    if (value != password) {
      return 'As palavras-passe não correspondem';
    }

    return null;
  }

  // Validar nome
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o nome';
    }

    if (value.length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres';
    }

    return null;
  }

  // Validar telefone (formato português)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o número de telefone';
    }

    // Remove espaços e hífens
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');

    // Verifica se é um número português válido
    final phoneRegex = RegExp(r'^(\+351)?[239]\d{8}$');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Por favor, insira um número válido';
    }

    return null;
  }

  // Validar campo obrigatório genérico
  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  // Validar número
  static String? number(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira um número';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Por favor, insira um número válido';
    }

    if (min != null && number < min) {
      return 'O valor mínimo é $min';
    }

    if (max != null && number > max) {
      return 'O valor máximo é $max';
    }

    return null;
  }

  // Validar ano do veículo
  static String? vehicleYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o ano do veículo';
    }

    final year = int.tryParse(value);
    if (year == null) {
      return 'Por favor, insira um ano válido';
    }

    final currentYear = DateTime.now().year;

    if (year < 1900) {
      return 'O ano deve ser posterior a 1900';
    }

    if (year > currentYear) {
      return 'O ano não pode ser futuro';
    }

    return null;
  }

  // Validar preço
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o preço';
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Por favor, insira um preço válido';
    }

    return null;
  }

  // Validar descrição
  static String? description(
    String? value, {
    int minLength = 20,
    int maxLength = 500,
  }) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira uma descrição';
    }

    if (value.length < minLength) {
      return 'A descrição deve ter pelo menos $minLength caracteres';
    }

    if (value.length > maxLength) {
      return 'A descrição não pode exceder $maxLength caracteres';
    }

    return null;
  }

  // Validar seleção de lista
  static String? selection(dynamic value, String fieldName) {
    if (value == null) {
      return 'Por favor, selecione $fieldName';
    }
    return null;
  }

  // Validar lista não vazia
  static String? listNotEmpty(List? list, String fieldName) {
    if (list == null || list.isEmpty) {
      return 'Por favor, selecione pelo menos um $fieldName';
    }
    return null;
  }

  // Validar datas de reserva
  static String? bookingDates(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Por favor, selecione as datas';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (startDate.isBefore(today)) {
      return 'A data de início não pode ser no passado';
    }

    if (endDate.isBefore(startDate)) {
      return 'A data de fim deve ser posterior à data de início';
    }

    return null;
  }
}
