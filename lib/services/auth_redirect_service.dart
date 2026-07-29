import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';

/// The single place that decides which route a given authenticated [User]
/// belongs on. Used both by the go_router redirect guard (as an
/// enforcement rule) and by `SplashScreen`/`PersonnelEntryScreen` (to
/// compute where to `context.go` once their own one-time resolution is
/// done). Before the go_router migration this returned a `Widget` and was
/// duplicated by hand in three places; it now returns a route path.
class AuthRedirectService {
  const AuthRedirectService._();

  static String pathForUser(User user) {
    if (user.isCustomer) {
      return RoutePaths.accueil;
    }

    if (user.internalProfile?.role == InternalRole.legacy_unknown ||
        user.internalProfile == null) {
      return RoutePaths.personnelIncomplet;
    }

    return RoutePaths.personnelHome;
  }
}
