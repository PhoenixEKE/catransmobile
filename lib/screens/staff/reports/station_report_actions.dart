import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/station/reports/station_report_common.dart';

const stationReportConflictRefreshMessage =
    'Cette demande a été modifiée par un autre utilisateur. Les informations vont être actualisées.';

enum StationReportRequestKind { report, cancellation }

enum StationReportActionKind { approve, reject, apply }

extension StationReportRequestKindLabel on StationReportRequestKind {
  String get label => switch (this) {
        StationReportRequestKind.report => 'report',
        StationReportRequestKind.cancellation => 'annulation',
      };
}

extension StationReportActionKindLabel on StationReportActionKind {
  String labelFor(StationReportRequestKind kind) {
    return switch ((kind, this)) {
      (StationReportRequestKind.report, StationReportActionKind.approve) =>
        'Approuver',
      (StationReportRequestKind.report, StationReportActionKind.reject) =>
        'Rejeter',
      (StationReportRequestKind.report, StationReportActionKind.apply) =>
        'Appliquer',
      (
        StationReportRequestKind.cancellation,
        StationReportActionKind.approve
      ) =>
        'Approuver',
      (StationReportRequestKind.cancellation, StationReportActionKind.reject) =>
        'Rejeter',
      (StationReportRequestKind.cancellation, StationReportActionKind.apply) =>
        'Appliquer',
    };
  }

  String buttonLabelFor(StationReportRequestKind kind) {
    return switch ((kind, this)) {
      (StationReportRequestKind.report, StationReportActionKind.apply) =>
        'Appliquer le report',
      (StationReportRequestKind.cancellation, StationReportActionKind.apply) =>
        'Appliquer l’annulation',
      (_, StationReportActionKind.approve) => 'Approuver',
      (_, StationReportActionKind.reject) => 'Rejeter',
    };
  }

  IconData get icon => switch (this) {
        StationReportActionKind.approve => Icons.check_circle_outline,
        StationReportActionKind.reject => Icons.cancel_outlined,
        StationReportActionKind.apply => Icons.done_all_outlined,
      };

  Color get color => switch (this) {
        StationReportActionKind.approve => const Color(0xFF157347),
        StationReportActionKind.reject => const Color(0xFFB42318),
        StationReportActionKind.apply => const Color(0xFF0F056B),
      };
}

bool canShowStationReportAction({
  required StationReportAvailableActions availableActions,
  required StationReportEligibility eligibility,
  required StationReportActionKind action,
  bool isMutating = false,
}) {
  if (isMutating || !eligibility.isEligible) return false;

  return switch (action) {
    StationReportActionKind.approve => availableActions.canApprove,
    StationReportActionKind.reject => availableActions.canReject,
    StationReportActionKind.apply => availableActions.canApply,
  };
}

List<StationReportActionKind> visibleStationReportActions({
  required StationReportAvailableActions availableActions,
  required StationReportEligibility eligibility,
  bool isMutating = false,
}) {
  return StationReportActionKind.values
      .where(
        (action) => canShowStationReportAction(
          availableActions: availableActions,
          eligibility: eligibility,
          action: action,
          isMutating: isMutating,
        ),
      )
      .toList(growable: false);
}

String stationReportSuccessMessage(
  StationReportRequestKind kind,
  StationReportActionKind action,
) {
  return switch ((kind, action)) {
    (StationReportRequestKind.report, StationReportActionKind.approve) =>
      'Report approuvé.',
    (StationReportRequestKind.report, StationReportActionKind.reject) =>
      'Report rejeté.',
    (StationReportRequestKind.report, StationReportActionKind.apply) =>
      'Report appliqué. Le ticket a été actualisé.',
    (StationReportRequestKind.cancellation, StationReportActionKind.approve) =>
      'Annulation approuvée.',
    (StationReportRequestKind.cancellation, StationReportActionKind.reject) =>
      'Annulation rejetée.',
    (StationReportRequestKind.cancellation, StationReportActionKind.apply) =>
      'Annulation appliquée. La réservation et les tickets ont été annulés.',
  };
}

String? stationReportBusinessCodeFromError(Object error) {
  if (error is! ApiException) return null;
  final details = error.details;
  if (details is Map<String, dynamic>) {
    final code = details['code'] ?? details['blocking_code'];
    if (code is String && code.trim().isNotEmpty) return code.trim();
    final detail = details['detail'];
    if (detail is Map<String, dynamic>) {
      final nestedCode = detail['code'] ?? detail['blocking_code'];
      if (nestedCode is String && nestedCode.trim().isNotEmpty) {
        return nestedCode.trim();
      }
    }
  }
  if (details is Map) {
    return stationReportBusinessCodeFromError(
      ApiException(
        message: error.message,
        statusCode: error.statusCode,
        details: Map<String, dynamic>.from(details),
      ),
    );
  }
  return null;
}

String stationReportMutationErrorMessage(Object error) {
  if (error is ApiException) {
    final businessCode = stationReportBusinessCodeFromError(error);
    final businessMessage = stationReportBusinessErrorMessage(businessCode);
    if (businessMessage != null) return businessMessage;

    switch (error.statusCode) {
      case 401:
        return 'Votre session a expiré. Veuillez vous reconnecter.';
      case 403:
        return 'Vous n’êtes pas autorisé à traiter cette demande.';
      case 404:
        return 'Cette demande n’est plus accessible.';
      case 409:
        return stationReportConflictRefreshMessage;
    }

    final message = error.message.trim();
    if (message.isNotEmpty) return message;
  }
  return 'Impossible de traiter cette demande pour le moment.';
}

String? stationReportBusinessErrorMessage(String? code) {
  return switch (code) {
    'REQUEST_INVALID_STATUS' =>
      'Le statut de cette demande a changé. Les informations vont être actualisées.',
    'RESERVATION_NOT_CONFIRMED' => 'La réservation n’est plus confirmée.',
    'TICKET_ALREADY_USED' =>
      'Cette demande ne peut plus être traitée car un ticket a déjà été utilisé.',
    'TICKET_NOT_MODIFIABLE' => 'Le ticket associé ne peut plus être modifié.',
    'DEPARTURE_NOT_ELIGIBLE' =>
      'Le départ actuel ne permet plus cette opération.',
    'TARGET_DEPARTURE_NOT_OPEN' => 'Le nouveau départ n’est plus ouvert.',
    'TARGET_CAPACITY_UNAVAILABLE' =>
      'Le nouveau départ ne dispose plus de capacité suffisante.',
    'TARGET_SEAT_REQUIRED' => 'Un siège cible est requis pour ce report.',
    'TARGET_SEAT_UNAVAILABLE' => 'Le siège demandé n’est plus disponible.',
    'FARE_DIFFERENCE_NOT_SUPPORTED' =>
      'Le report ne peut pas être appliqué car le tarif est différent.',
    'ACTIVE_REQUEST_ALREADY_EXISTS' =>
      'Une autre demande active existe déjà pour cette réservation.',
    _ => null,
  };
}

bool shouldRefreshAfterStationReportMutationError(Object error) {
  if (error is! ApiException) return false;
  if ([404, 409].contains(error.statusCode)) return true;
  return stationReportBusinessCodeFromError(error) != null;
}

int pageAfterStationReportMutation({
  required int currentPage,
  required int currentResultCount,
}) {
  if (currentPage > 1 && currentResultCount <= 1) return currentPage - 1;
  return currentPage;
}

String normalizeStationReportRejectionReason(String value) => value.trim();
