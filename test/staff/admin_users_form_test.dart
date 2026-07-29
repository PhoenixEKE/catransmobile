import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/staff_refs.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_user_form_dialog.dart';

void main() {
  group('admin user form', () {
    testWidgets('create mode exposes password and required fields',
        (tester) async {
      await tester.pumpWidget(const _FormHarness());

      expect(find.text('Nouvel utilisateur'), findsOneWidget);
      expect(find.text('Mot de passe initial *'), findsOneWidget);
      expect(find.text('Créer'), findsOneWidget);
    });

    testWidgets('edit mode hides initial password field', (tester) async {
      await tester.pumpWidget(_FormHarness(initialUser: _detail()));

      expect(find.text('Modifier l’utilisateur'), findsOneWidget);
      expect(find.text('Mot de passe initial *'), findsNothing);
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('field error is displayed near backend field', (tester) async {
      await tester.pumpWidget(const _FormHarness(
        error: StructuredApiError(
          detail: 'Adresse email déjà utilisée.',
          field: 'email',
          statusCode: 400,
        ),
      ));

      expect(find.text('Adresse email déjà utilisée.'), findsOneWidget);
    });
  });
}

class _FormHarness extends StatelessWidget {
  final StructuredApiError? error;
  final AdminInternalUserDetail? initialUser;

  const _FormHarness({this.error, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AdminUserFormDialog(
          roles: _roles,
          stations: _stations,
          loadCountersForStation: (_) async => _counters,
          isSubmitting: false,
          error: error,
          initialUser: initialUser,
        ),
      ),
    );
  }
}

const _roles = [
  AdminInternalRoleOption(
    value: 'cashier',
    label: 'Guichetier',
    requiresStation: true,
    requiresCounter: true,
    allowsStation: true,
    allowsCounter: true,
  ),
];

const _stations = [StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon')];
const _counters = [StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1')];

AdminInternalUserDetail _detail() {
  return const AdminInternalUserDetail(
    id: 'user-1',
    email: 'cashier@catrans.test',
    phoneNumber: '+2250101010101',
    lastname: 'Koffi',
    firstname: 'Aya',
    isActive: true,
    role: 'cashier',
    roleLabel: 'Guichetier',
    station: StaffRef(id: 'station-1', code: 'YOP', name: 'Yopougon'),
    counter: StaffRef(id: 'counter-1', code: 'G1', name: 'Guichet 1'),
  );
}
