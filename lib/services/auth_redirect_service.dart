import 'package:flutter/widgets.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';
import 'package:catrans_app/screens/staff/pages/staff_profile_incomplete_page.dart';
import 'package:catrans_app/screens/staff/shell/staff_shell_screen.dart';

class AuthRedirectService {
  const AuthRedirectService._();

  static Widget homeForUser(User user) {
    if (user.isCustomer) {
      return const AccueilScreen();
    }

    if (user.internalProfile?.role == InternalRole.legacy_unknown ||
        user.internalProfile == null) {
      return const StaffProfileIncompletePage();
    }

    return const StaffShellScreen();
  }
}
