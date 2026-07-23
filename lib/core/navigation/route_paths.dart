/// Central list of every route path in the app.
///
/// Before the go_router migration only `/personnel` had a name; every other
/// screen was reached through an anonymous `MaterialPageRoute`. These paths
/// give every screen a real URL without changing which screen follows which
/// (see `catographie_v5.md` for the navigation graph this mirrors).
class RoutePaths {
  RoutePaths._();

  static const String root = '/';
  static const String bienvenue = '/bienvenue';
  static const String connexion = '/connexion';
  static const String inscription = '/inscription';

  static const String accueil = '/accueil';
  static const String choixClasse = '/recherche/classe';
  static const String rechercheResultat = '/recherche/resultats';
  static const String choixPlaceEconomie = '/reservation/places-economie';
  static const String choixPlacePrestige = '/reservation/places-prestige';
  static const String recapitulatif = '/reservation/recapitulatif';
  static const String paiement = '/reservation/paiement';
  static const String mesReservations = '/mes-reservations';
  static const String billet = '/billet';
  static const String support = '/support';
  static const String profil = '/profil';
  static const String changePassword = '/profil/mot-de-passe';
  static const String pointsFidelite = '/profil/points-fidelite';

  static const String personnel = '/personnel';
  static const String personnelIncomplet = '/personnel/incomplet';
  static const String personnelHome = '/personnel/home';
}

/// Paths that can be resumed after the forced splash detour (via
/// `SplashScreen` reading a `?from=` query parameter) because their
/// [GoRoute] builder needs no `extra` data. Paths that require a
/// constructed widget via `extra` (recapitulatif, paiement, billet, the
/// two seat-selection screens...) are intentionally excluded: nothing
/// could have supplied that `extra` on a bare direct link anyway, so they
/// fall back to the same default destination they always would have
/// without this mechanism. Shared between `app_router.dart` (which sets
/// `from`) and `splash_screen.dart` (which reads it) to avoid a circular
/// import between the two.
const resumableAfterSplashPaths = {
  RoutePaths.bienvenue,
  RoutePaths.connexion,
  RoutePaths.inscription,
  RoutePaths.accueil,
  RoutePaths.mesReservations,
  RoutePaths.support,
  RoutePaths.profil,
  RoutePaths.changePassword,
  RoutePaths.pointsFidelite,
  RoutePaths.personnelHome,
  RoutePaths.personnelIncomplet,
};
