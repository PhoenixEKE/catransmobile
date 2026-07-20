import 'package:flutter/material.dart';

import 'package:catrans_app/core/permissions/staff_permissions.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/admin_internal_user_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_user_detail_dialog.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_user_form_dialog.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_users_controller.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_users_list.dart';
import 'package:catrans_app/screens/staff/admin/users/admin_users_toolbar.dart';
import 'package:catrans_app/screens/staff/pages/staff_access_denied_page.dart';
import 'package:catrans_app/services/api/staff/admin/admin_users_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';
import 'package:catrans_app/widgets/staff/staff_module_header.dart';
import 'package:catrans_app/widgets/staff/staff_read_only_banner.dart';

class AdminUsersHomeScreen extends StatefulWidget {
  final User user;
  final AdminUsersApiService? apiService;

  const AdminUsersHomeScreen({
    super.key,
    required this.user,
    this.apiService,
  });

  @override
  State<AdminUsersHomeScreen> createState() => _AdminUsersHomeScreenState();
}

class _AdminUsersHomeScreenState extends State<AdminUsersHomeScreen> {
  late final StaffPermissions _permissions;
  AdminUsersController? _controller;

  bool get _canManage => _permissions.canManageAdminUsers;

  @override
  void initState() {
    super.initState();
    _permissions = StaffPermissions.fromScopes(widget.user.scopes);
    if (_permissions.canReadAdminUsers) {
      final controller = AdminUsersController(apiService: widget.apiService);
      _controller = controller;
      controller.initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canReadAdminUsers) {
      return const StaffAccessDeniedPage();
    }

    final controller = _controller!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaffModuleHeader(
                icon: Icons.manage_accounts,
                title: 'Utilisateurs internes',
                description:
                    'Administration des comptes personnel, rôles, gares et guichets.',
                trailing: _HeaderCounter(controller: controller),
              ),
              const SizedBox(height: 14),
              StaffReadOnlyBanner(isReadOnly: !_canManage),
              const SizedBox(height: 18),
              if (controller.optionsError != null) ...[
                StaffErrorState(
                  message: controller.optionsError!,
                  onRetry: controller.loadOptions,
                ),
                const SizedBox(height: 14),
              ],
              AdminUsersToolbar(
                initialQuery: controller.query,
                selectedRole: controller.role,
                selectedStationId: controller.stationId,
                selectedCounterId: controller.counterId,
                selectedIsActive: controller.isActive,
                ordering: controller.ordering,
                roles: controller.roles,
                stations: controller.stations,
                counters: controller.counters,
                isLoadingCounters: controller.isLoadingCounters,
                canManage: _canManage,
                onSearch: controller.search,
                onRoleChanged: controller.setRole,
                onStationChanged: controller.setStation,
                onCounterChanged: controller.setCounter,
                onActiveChanged: controller.setActiveFilter,
                onOrderingChanged: controller.setOrdering,
                onRefresh: controller.refresh,
                onCreate: _openCreateForm,
              ),
              const SizedBox(height: 18),
              _buildContent(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(AdminUsersController controller) {
    if (controller.isLoadingUsers && controller.usersPage == null) {
      return const StaffLoadingState(
        message: 'Chargement des utilisateurs internes...',
      );
    }

    if (controller.listError != null) {
      return StaffErrorState(
        message: controller.listError!,
        onRetry: controller.refresh,
      );
    }

    final page = controller.usersPage;
    if (page == null || page.results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.manage_accounts,
        title: 'Aucun utilisateur interne',
        message:
            'Aucun compte ne correspond aux filtres actuels. Ajustez la recherche ou créez un nouvel utilisateur si vous avez les droits de gestion.',
      );
    }

    return Stack(
      children: [
        AdminUsersList(
          page: page,
          canManage: _canManage,
          onPreviousPage: controller.hasPreviousPage
              ? () => controller.previousPage()
              : null,
          onNextPage:
              controller.hasNextPage ? () => controller.nextPage() : null,
          onOpenDetail: _openDetail,
          onEdit: _openEditForm,
          onActivate: _activateUser,
          onDeactivate: _deactivateUser,
        ),
        if (controller.isLoadingUsers)
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

  Future<void> _openDetail(AdminInternalUserSummary user) async {
    await showAdminUserDetailDialog(
      context: context,
      user: user,
      loadDetail: _controller!.getDetail,
    );
  }

  Future<void> _openCreateForm() async {
    if (!_canManage) return;
    StructuredApiError? formError;
    AdminInternalUserCreateRequest? draft;

    while (mounted) {
      final result = await showAdminUserFormDialog(
        context: context,
        roles: _controller!.roles,
        stations: _controller!.stations,
        loadCountersForStation: _controller!.countersForStation,
        isSubmitting: _controller!.isSubmitting,
        error: formError,
        initialCreateRequest: draft,
      );
      if (result?.createRequest == null) return;

      draft = result!.createRequest!;
      final success = await _controller!.createUser(draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Utilisateur interne créé.');
        return;
      }
      formError = _controller!.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller!.formError ?? 'Création impossible.');
        return;
      }
    }
  }

  Future<void> _openEditForm(AdminInternalUserSummary user) async {
    if (!_canManage) return;
    AdminInternalUserDetail detail;
    try {
      detail = await _controller!.getDetail(user.id);
    } catch (_) {
      if (mounted) {
        _showSnackBar('Impossible de charger le détail utilisateur.');
      }
      return;
    }

    if (!mounted) return;

    StructuredApiError? formError;
    AdminInternalUserUpdateRequest? draft;
    while (mounted) {
      final result = await showAdminUserFormDialog(
        context: context,
        roles: _controller!.roles,
        stations: _controller!.stations,
        loadCountersForStation: _controller!.countersForStation,
        isSubmitting: _controller!.isSubmitting,
        error: formError,
        initialUser: detail,
        initialUpdateRequest: draft,
      );
      if (result?.updateRequest == null) return;

      draft = result!.updateRequest!;
      final success = await _controller!.updateUser(user.id, draft);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Utilisateur interne mis à jour.');
        return;
      }
      formError = _controller!.structuredFormError;
      if (formError == null) {
        _showSnackBar(_controller!.formError ?? 'Modification impossible.');
        return;
      }
    }
  }

  Future<void> _activateUser(AdminInternalUserSummary user) async {
    if (!_canManage) return;
    final confirmed = await _confirmAction(
      title: 'Activer cet utilisateur ?',
      message: 'Le compte pourra de nouveau accéder au portail CA TRANS.',
      actionLabel: 'Activer',
    );
    if (confirmed != true) return;

    final success = await _controller!.activateUser(user.id);
    if (!mounted) return;
    _showSnackBar(success
        ? 'Utilisateur activé.'
        : _controller!.formError ?? 'Activation impossible.');
  }

  Future<void> _deactivateUser(AdminInternalUserSummary user) async {
    if (!_canManage) return;
    final confirmed = await _confirmAction(
      title: 'Désactiver cet utilisateur ?',
      message:
          'Le compte ne pourra plus utiliser les accès internes avec ses JWT existants.',
      actionLabel: 'Désactiver',
      destructive: true,
    );
    if (confirmed != true) return;

    final success = await _controller!.deactivateUser(user.id);
    if (!mounted) return;
    _showSnackBar(success
        ? 'Utilisateur désactivé.'
        : _controller!.formError ?? 'Désactivation impossible.');
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: destructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                      foregroundColor: Colors.white,
                    )
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
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

class _HeaderCounter extends StatelessWidget {
  final AdminUsersController controller;

  const _HeaderCounter({required this.controller});

  @override
  Widget build(BuildContext context) {
    final count = controller.usersPage?.count;
    if (count == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBD7FF)),
      ),
      child: Text(
        '$count compte${count > 1 ? 's' : ''}',
        style: const TextStyle(
          color: Color(0xFF0F056B),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
