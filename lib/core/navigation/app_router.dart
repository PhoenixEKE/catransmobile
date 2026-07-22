import 'package:go_router/go_router.dart';

import 'package:catrans_app/core/navigation/route_paths.dart';
import 'package:catrans_app/services/auth_service.dart';
import 'package:catrans_app/services/auth_redirect_service.dart';

import 'package:catrans_app/screens/client/auth/splash_screen.dart';
import 'package:catrans_app/screens/client/auth/login_screen.dart';
import 'package:catrans_app/screens/client/auth/register_screen.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';
import 'package:catrans_app/screens/client/search/choix_classe_screen.dart';
import 'package:catrans_app/screens/client/search/recherche_resultat_screen.dart';
import 'package:catrans_app/screens/client/booking/choix_place_economie_screen.dart';
import 'package:catrans_app/screens/client/booking/choix_place_prestige_screen.dart';
import 'package:catrans_app/screens/client/booking/recapitulatif_screen.dart';
import 'package:catrans_app/screens/client/booking/paiement_screen.dart';
import 'package:catrans_app/screens/client/tickets/mes_reservations_screen.dart';
import 'package:catrans_app/screens/client/tickets/billet_screen.dart';
import 'package:catrans_app/screens/client/support/support_screen.dart';
import 'package:catrans_app/screens/client/profile/profil_screen.dart';
import 'package:catrans_app/screens/client/profile/change_password_screen.dart';

import 'package:catrans_app/screens/staff/auth/personnel_entry_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_profile_incomplete_page.dart';
import 'package:catrans_app/screens/staff/shell/staff_shell_screen.dart';

/// Builds the single [GoRouter] instance for the app.
///
/// `redirect` is the one place that now enforces the auth-based routing
/// rules that used to be duplicated across `SplashScreen._navigateToAuth`,
/// `AuthRedirectService.homeForUser` and `PersonnelEntryScreen._resolve`.
/// It relies on `refreshListenable: authService` to re-run automatically
/// whenever `AuthService.notifyListeners()` fires (login, logout, loadUser).
///
/// `/` (the splash screen) is deliberately left out of the guard below: it
/// runs its own one-time resolution (minimum display time + `loadUser()` +
/// the pending-reservation resume check) and calls `context.go(...)` itself
/// once done, exactly as it decided its own destination before this
/// migration. `/personnel` is left out for the same reason: it keeps
/// deciding, in place, between its login form and its "customer blocked"
/// view, exactly as before.
///
/// Every other route that requires an authenticated user only became
/// reachable by direct URL as a side effect of giving it a real path in
/// this migration (previously there was no named route for it at all, so a
/// stray direct link was simply impossible). The guards below are the
/// necessary consequence of that, not a behavior change for users who
/// navigate the app normally.
GoRouter buildAppRouter(AuthService authService) {
  return GoRouter(
    initialLocation: RoutePaths.root,
    refreshListenable: authService,
    redirect: (context, state) => _guard(state, authService),
    routes: [
      GoRoute(
        path: RoutePaths.root,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.bienvenue,
        builder: (context, state) => const AuthChoiceScreen(),
      ),
      GoRoute(
        path: RoutePaths.connexion,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.inscription,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.accueil,
        builder: (context, state) => const AccueilScreen(),
      ),
      GoRoute(
        path: RoutePaths.choixClasse,
        builder: (context, state) => state.extra as ChoixClasseScreen,
      ),
      GoRoute(
        path: RoutePaths.rechercheResultat,
        builder: (context, state) => state.extra as RechercheResultatScreen,
      ),
      GoRoute(
        path: RoutePaths.choixPlaceEconomie,
        builder: (context, state) => state.extra as ChoixPlaceEconomieScreen,
      ),
      GoRoute(
        path: RoutePaths.choixPlacePrestige,
        builder: (context, state) => state.extra as ChoixPlacePrestigeScreen,
      ),
      GoRoute(
        path: RoutePaths.recapitulatif,
        builder: (context, state) => state.extra as RecapitulatifScreen,
      ),
      GoRoute(
        path: RoutePaths.paiement,
        builder: (context, state) => state.extra as PaiementScreen,
      ),
      GoRoute(
        path: RoutePaths.mesReservations,
        builder: (context, state) => const MesReservationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.billet,
        builder: (context, state) => state.extra as BilletScreen,
      ),
      GoRoute(
        path: RoutePaths.support,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: RoutePaths.profil,
        builder: (context, state) => const ProfilScreen(),
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.personnel,
        builder: (context, state) => const PersonnelEntryScreen(),
      ),
      GoRoute(
        path: RoutePaths.personnelIncomplet,
        builder: (context, state) => const StaffProfileIncompletePage(),
      ),
      GoRoute(
        path: RoutePaths.personnelHome,
        builder: (context, state) => const StaffShellScreen(),
      ),
    ],
  );
}

const _clientProtectedPaths = {
  RoutePaths.accueil,
  RoutePaths.choixClasse,
  RoutePaths.rechercheResultat,
  RoutePaths.choixPlaceEconomie,
  RoutePaths.choixPlacePrestige,
  RoutePaths.recapitulatif,
  RoutePaths.paiement,
  RoutePaths.mesReservations,
  RoutePaths.billet,
  RoutePaths.support,
  RoutePaths.profil,
  RoutePaths.changePassword,
};

const _guestOnlyPaths = {
  RoutePaths.bienvenue,
  RoutePaths.connexion,
  RoutePaths.inscription,
};

const _personnelProtectedPaths = {
  RoutePaths.personnelHome,
  RoutePaths.personnelIncomplet,
};

String? _guard(GoRouterState state, AuthService authService) {
  final location = state.matchedLocation;

  // The splash screen and the personnel entry point each run their own
  // one-time resolution and navigate themselves once done (see the
  // doc-comment on buildAppRouter above).
  if (location == RoutePaths.root || location == RoutePaths.personnel) {
    return null;
  }

  if (!authService.isInitialized) {
    // A direct link to a protected path loaded before auth state is known:
    // send it through the splash screen first. SplashScreen reads `from`
    // once `loadUser()` resolves and, if it's in resumableAfterSplashPaths,
    // tries to go back there instead of the generic default destination.
    if (resumableAfterSplashPaths.contains(location)) {
      return Uri(
        path: RoutePaths.root,
        queryParameters: {'from': location},
      ).toString();
    }
    return RoutePaths.root;
  }

  final user = authService.currentUser;

  if (_clientProtectedPaths.contains(location) && user == null) {
    return RoutePaths.bienvenue;
  }

  if (_guestOnlyPaths.contains(location) &&
      user != null &&
      user.isCustomer) {
    return RoutePaths.accueil;
  }

  if (_personnelProtectedPaths.contains(location)) {
    if (user == null || user.isCustomer) {
      return RoutePaths.personnel;
    }
    final expected = AuthRedirectService.pathForUser(user);
    if (expected != location) {
      return expected;
    }
  }

  return null;
}
