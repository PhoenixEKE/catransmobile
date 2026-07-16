import 'package:flutter/widgets.dart';

import 'package:catrans_app/models/accounts/internal_profile.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/screens/admin/admin_dashboard_screen.dart';
import 'package:catrans_app/screens/client/home/accueil_screen.dart';
import 'package:catrans_app/screens/staff/staff_placeholder_screen.dart';

class AuthRedirectService {
  const AuthRedirectService._();

  static Widget homeForUser(User user) {
    if (user.isCustomer) {
      return const AccueilScreen();
    }

    final role = user.internalProfile?.role;
    if (role == InternalRole.admin || role == InternalRole.director) {
      return const AdminDashboardScreen();
    }

    return StaffPlaceholderScreen.forUser(user);
  }
}
