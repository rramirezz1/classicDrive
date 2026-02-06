import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Classic Drive';

  @override
  String get mapButton => 'Mapa';

  @override
  String get adminPanel => 'Painel de Admin';

  @override
  String get goodMorning => 'Bom dia,';

  @override
  String get goodAfternoon => 'Boa tarde,';

  @override
  String get goodEvening => 'Boa noite,';

  @override
  String get user => 'Utilizador';

  @override
  String get verificationPending => 'Verificação em análise';

  @override
  String get verifyAccount => 'Verificar conta';

  @override
  String get accountVerified => 'Conta Verificada';

  @override
  String trustScore(Object score) {
    return 'Score de confiança: $score';
  }

  @override
  String get recommendedForYou => 'Recomendados para Si';

  @override
  String get myStats => 'As Minhas Estatísticas';

  @override
  String get featuredVehicles => 'Veículos em Destaque';

  @override
  String get exploreByCategory => 'Explorar por Categoria';

  @override
  String get addVehicle => 'Adicionar Veículo';

  @override
  String get myVehicles => 'Meus Veículos';

  @override
  String get bookings => 'Reservas';

  @override
  String get reports => 'Relatórios';

  @override
  String get search => 'Procurar';

  @override
  String get myBookings => 'Minhas Reservas';

  @override
  String get favorites => 'Favoritos';

  @override
  String get myInsurance => 'Meus Seguros';

  @override
  String get active => 'Ativo';

  @override
  String get noVehiclesAvailable => 'Ainda não há veículos disponíveis';

  @override
  String get perDay => '/dia';

  @override
  String get classics => 'Clássicos';

  @override
  String get vintage => 'Vintage';

  @override
  String get luxury => 'Luxo';

  @override
  String get insuranceDialogTitle => 'Meus Seguros';

  @override
  String get featureInDevelopment => 'Funcionalidade em desenvolvimento';

  @override
  String get ok => 'OK';

  @override
  String get navHome => 'Início';

  @override
  String get navVehicles => 'Veículos';

  @override
  String get navBookings => 'Reservas';

  @override
  String get navProfile => 'Perfil';
}
