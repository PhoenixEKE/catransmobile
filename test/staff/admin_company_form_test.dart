import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_company_form_dialog.dart';

void main() {
  group('admin company form', () {
    testWidgets('create mode validates name and exposes optional fields',
        (tester) async {
      await tester.pumpWidget(const _FormHarness());
      await tester.tap(find.text('Ouvrir'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Nouvelle compagnie'), findsOneWidget);
      expect(find.text('Nom *'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Téléphone service client'), findsOneWidget);

      await tester.tap(find.text('Créer'));
      await tester.pump();

      expect(find.text('Nom est obligatoire.'), findsOneWidget);
    });

    testWidgets('field error is displayed near company code', (tester) async {
      await tester.pumpWidget(const _FormHarness(
        error: StructuredApiError(
          code: 'transport_duplicate_company_code',
          detail: 'Une compagnie utilise déjà ce code.',
          field: 'code',
          statusCode: 400,
        ),
      ));
      await tester.tap(find.text('Ouvrir'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Une compagnie utilise déjà ce code.'), findsOneWidget);
    });

    testWidgets('edit mode can clear nullable code and phone', (tester) async {
      AdminCompanyFormResult? result;
      await tester.pumpWidget(_FormHarness(
        initialCompany: _company(),
        onResult: (value) => result = value,
      ));
      await tester.tap(find.text('Ouvrir'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.enterText(find.widgetWithText(TextFormField, 'Code'), '');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Téléphone service client'),
        '',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(milliseconds: 250));

      final json = result!.updateRequest!.toJson();
      expect(json['code'], isNull);
      expect(json['customer_service_phone'], isNull);
      expect(json.containsKey('name'), isFalse);
    });
  });
}

class _FormHarness extends StatelessWidget {
  final StructuredApiError? error;
  final AdminCompany? initialCompany;
  final ValueChanged<AdminCompanyFormResult?>? onResult;

  const _FormHarness({
    this.error,
    this.initialCompany,
    this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showAdminCompanyFormDialog(
                    context: context,
                    isSubmitting: false,
                    error: error,
                    initialCompany: initialCompany,
                  );
                  onResult?.call(result);
                },
                child: const Text('Ouvrir'),
              ),
            );
          },
        ),
      ),
    );
  }
}

AdminCompany _company() {
  return const AdminCompany(
    id: 'company-1',
    name: 'CA TRANS',
    code: 'CAT',
    customerServicePhone: '+2250101010101',
    isActive: true,
    createdAt: '2026-07-20T08:00:00Z',
    updatedAt: '2026-07-20T09:00:00Z',
  );
}
