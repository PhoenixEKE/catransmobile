/// Design foundation for the CA TRANS **personnel** (staff) portal only.
///
/// Scope: everything reachable from `/personnel` (login, shell, sidebar,
/// topbar, module header, system pages). This file intentionally does not
/// touch `lib/main.dart`'s `ThemeData`, which remains dedicated to the public
/// traveller experience.
library;

import 'package:flutter/material.dart';

/// Brand and semantic colors shared by the personnel portal widgets.
class PersonnelColors {
  const PersonnelColors._();

  /// CA TRANS brand primary (also used by the public app's theme, kept in
  /// sync intentionally so both experiences read as the same product).
  static const Color brandPrimary = Color(0xFF0F056B);
  static const Color brandAccent = Color(0xFFEFD807);

  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE6E8F0);

  static const Color textPrimary = Color(0xFF15112D);
  static const Color textSecondary = Color(0xFF5F6270);
  static const Color textMuted = Colors.black54;

  static const Color success = Color(0xFF12793B);
  static const Color successSurface = Color(0xFFEAF7EF);
  static const Color warning = Color(0xFF7A3E00);
  static const Color warningSurface = Color(0xFFFFF3DD);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerSurface = Color(0xFFFFF2F2);
}

/// Spacing scale for the personnel portal.
class PersonnelSpacing {
  const PersonnelSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radius scale for the personnel portal.
class PersonnelRadius {
  const PersonnelRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

/// Shared responsive breakpoints for the personnel portal shell.
///
/// - mobile: width < 600
/// - tablet: 600 <= width < 900
/// - desktop: width >= 900 (permanent sidebar threshold)
/// - large: width >= 1200 (extra breathing room on very wide monitors)
class PersonnelBreakpoints {
  const PersonnelBreakpoints._();

  static const double mobile = 600;
  static const double desktop = 900;
  static const double large = 1200;

  /// Generous max content width applied only above [large], so ultra-wide
  /// monitors don't stretch tables/forms edge-to-edge without recreating the
  /// oversized blank margins flagged in the LOT 6.8A audit.
  static const double maxContentWidth = 1600;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isLarge(double width) => width >= large;
}
