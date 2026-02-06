import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';


class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Classic Drive';

  @override
  String get mapButton => 'Map';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get goodMorning => 'Good morning,';

  @override
  String get goodAfternoon => 'Good afternoon,';

  @override
  String get goodEvening => 'Good evening,';

  @override
  String get user => 'User';

  @override
  String get verificationPending => 'Verification pending';

  @override
  String get verifyAccount => 'Verify account';

  @override
  String get accountVerified => 'Verified Account';

  @override
  String trustScore(Object score) {
    return 'Trust Score: $score';
  }

  @override
  String get recommendedForYou => 'Recommended for You';

  @override
  String get myStats => 'My Stats';

  @override
  String get featuredVehicles => 'Featured Vehicles';

  @override
  String get exploreByCategory => 'Explore by Category';

  @override
  String get addVehicle => 'Add Vehicle';

  @override
  String get myVehicles => 'My Vehicles';

  @override
  String get bookings => 'Bookings';

  @override
  String get reports => 'Reports';

  @override
  String get search => 'Search';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get favorites => 'Favorites';

  @override
  String get myInsurance => 'My Insurance';

  @override
  String get active => 'Active';

  @override
  String get noVehiclesAvailable => 'No vehicles available yet';

  @override
  String get perDay => '/day';

  @override
  String get classics => 'Classics';

  @override
  String get vintage => 'Vintage';

  @override
  String get luxury => 'Luxury';

  @override
  String get insuranceDialogTitle => 'My Insurance';

  @override
  String get featureInDevelopment => 'Feature in development';

  @override
  String get ok => 'OK';

  @override
  String get navHome => 'Home';

  @override
  String get navVehicles => 'Vehicles';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navProfile => 'Profile';
}
