import 'package:flutter/material.dart';

import 'package:catrans_app/models/staff/admin/transport/admin_company_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_companies_controller.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_companies_list.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_companies_toolbar.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_company_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/transport/companies/admin_company_form_dialog.dart';
import 'package:catrans_app/services/api/staff/admin/transport/admin_transport_base_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminCompaniesScreen extends StatefulWidget {
  final bool canManage;
  final AdminTransportBaseApiService? apiService;

  const AdminCompaniesScreen({
    super.key,
    required this.canManage,
    this.apiService,
  });

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  late final AdminCompaniesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminCompaniesController(apiService: widget.apiService);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminCompaniesToolbar(
              initialQuery: _controller.query,
              selectedIsActive: _controller.isActive,
              ordering: _controller.ordering,
              canManage: widget.canManage,
              onSearch: _controller.search,
              onActiveChanged: _controller.setActiveFilter,
              onOrderingChanged: _controller.setOrdering,
              onRefresh: _controller.refresh,
              onCreate: _openCreateForm,
            ),
            const SizedBox(height: 18),
            _buildContent(),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.companiesPage == null) {
      return const StaffLoadingState(message: 'Chargement des compagnies...');
    }

    if (_controller.listError != null) {
      return StaffErrorState(
        message: _controller.listError!,
        onRetry: _controller.refresh,
      );
    }

    final page = _controller.companiesPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.business,
        title: 'Aucune compagnie',
        message:
            'Aucune compagnie ne correspond aux filtres actuels. Ajustez la recherche ou créez une compagnie si vous avez les droits de gestion.',
      );
    }

    return Stack(
      children: [
        AdminCompaniesList(
          page: page,
          canManage: widget.canManage && !_controller.isSubmitting,
          onPreviousPage: _controller.hasPreviousPage
              ? () => _controller.previousPage()
              : null,
          onNextPage:
              _controller.hasNextPage ? () => _controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onEdit: _openEditForm,
          onActivate: _activateCompany,
          onDeactivate: _deactivateCompany,
        ),
        if (_controller.isLoading || _controller.isSubmitting)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openDetail(AdminCompany company) async {
    await showAdminCompanyDetailDialog(
      context: context,
      company: company,
      loadDetail: _controller.getDetail,
    );
  }

  Future<void> _openCreateForm() async {
    if (!widget.canManage) return;
    StructuredApiError? formError;
    AdminCompanyCreateRequest? draft;

    while (mounted) {
      final result = await showAdminCompanyFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        error: formError,
        initialCreateRequest: draft,
      );
      if (result?.createRequest == null) return;

      draft = result!.createRequest!;
      final success = await _controller.createCompany(draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Compagnie créée.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openEditForm(AdminCompany company) async {
    if (!widget.canManage) return;
    AdminCompany detail;
    try {
      detail = await _controller.getDetail(company.id);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Impossible de charger le détail compagnie.');
      }
      return;
    }

    if (!mounted) return;

    StructuredApiError? formError;
    AdminCompanyUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminCompanyFormDialog(
        context: context,
        isSubmitting: _controller.isSubmitting,
        error: formError,
        initialCompany: detail,
        initialUpdateRequest: draft,
      );
      if (result?.updateRequest == null) return;

      draft = result!.updateRequest!;
      final success = await _controller.updateCompany(company.id, draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Compagnie mise à jour.');
        return;
      }
      formError = _controller.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller.formError ?? 'Modification impossible.');
        return;
      }
    }
  }

  Future<void> _activateCompany(AdminCompany company) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(
      title: 'Activer cette compagnie ?',
      message:
          'La compagnie ${company.name} pourra être utilisée par les référentiels transport.',
      actionLabel: 'Activer',
    );
    if (confirmed != true) return;

    final success = await _controller.activateCompany(company.id);
    if (!mounted) return;
    _showSnackBar(
      success
          ? 'Compagnie activée.'
          : _controller.formError ?? 'Activation impossible.',
    );
  }

  Future<void> _deactivateCompany(AdminCompany company) async {
    if (!widget.canManage) return;
    final confirmed = await _confirmAction(
      title: 'Désactiver cette compagnie ?',
      message:
          'La compagnie ${company.name} ne pourra plus être utilisée pour de nouveaux référentiels actifs.',
      actionLabel: 'Désactiver',
      destructive: true,
    );
    if (confirmed != true) return;

    final success = await _controller.deactivateCompany(company.id);
    if (!mounted) return;
    _showSnackBar(
      success
          ? 'Compagnie désactivée.'
          : _controller.formError ?? 'Désactivation impossible.',
    );
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !_controller.isSubmitting,
      builder: (dialogContext) {
        return AlertDialog(
          key: Key(destructive
              ? 'admin-company-deactivate-confirm-dialog'
              : 'admin-company-activate-confirm-dialog'),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: _controller.isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              key: Key(destructive
                  ? 'admin-company-deactivate-confirm'
                  : 'admin-company-activate-confirm'),
              style: destructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: _controller.isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
