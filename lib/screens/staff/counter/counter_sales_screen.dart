import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/accounts/user.dart';
import 'package:catrans_app/models/staff/admin/station_cash_models.dart';
import 'package:catrans_app/models/staff/structured_api_error.dart';
import 'package:catrans_app/models/station/operational_departures/station_operational_departures.dart';
import 'package:catrans_app/services/api/station_boarding_api_service.dart';
import 'package:catrans_app/services/api/station_counter_api_service.dart';
import 'package:catrans_app/services/api/station_operational_departures_api_service.dart';

class CounterSalesScreen extends StatefulWidget {
  final User user;
  final StationCounterApiService? counterApiService;
  final StationOperationalDeparturesApiService? operationalApiService;
  final StationBoardingApiService? stationBoardingApiService;

  const CounterSalesScreen({
    super.key,
    required this.user,
    this.counterApiService,
    this.operationalApiService,
    this.stationBoardingApiService,
  });

  @override
  State<CounterSalesScreen> createState() => _CounterSalesScreenState();
}

class _CounterSalesScreenState extends State<CounterSalesScreen> {
  late final StationCounterApiService _counterApiService;
  late final StationOperationalDeparturesApiService _operationalApiService;
  late final StationBoardingApiService _stationBoardingApiService;

  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _manualDepartureIdController = TextEditingController();

  final List<_TravelerDraft> _travelers = [];

  bool _isLoadingDepartures = false;
  bool _isSubmittingReservation = false;
  bool _isSubmittingCash = false;

  String? _departureLoadError;
  String? _formError;

  List<StationOperationalDeparture> _departures = const [];
  String? _selectedDepartureId;
  String? _selectedServiceClassCode;

  StationCashSaleCreateResponse? _pendingSale;
  StationCashConfirmResponse? _confirmedSale;

  @override
  void initState() {
    super.initState();
    _counterApiService = widget.counterApiService ?? StationCounterApiService();
    _operationalApiService = widget.operationalApiService ??
        StationOperationalDeparturesApiService();
    _stationBoardingApiService =
        widget.stationBoardingApiService ?? StationBoardingApiService();
    _travelers.add(_TravelerDraft(isForCustomer: true));
    _loadDepartures();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _manualDepartureIdController.dispose();
    for (final traveler in _travelers) {
      traveler.dispose();
    }
    super.dispose();
  }

  bool get _canSubmitReservation {
    return !_isSubmittingReservation &&
        !_isSubmittingCash &&
        _pendingSale == null &&
        _confirmedSale == null;
  }

  bool get _canConfirmCash {
    return !_isSubmittingReservation &&
        !_isSubmittingCash &&
        _pendingSale != null &&
        _confirmedSale == null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContextCard(user: widget.user),
              const SizedBox(height: 12),
              _buildDepartureSection(compact),
              const SizedBox(height: 12),
              _buildForm(compact),
              if (_formError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _formError!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ],
              if (_pendingSale != null) ...[
                const SizedBox(height: 16),
                _PendingReservationCard(response: _pendingSale!),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    key: const Key('counter-sales-confirm-cash'),
                    onPressed: _canConfirmCash ? _confirmCash : null,
                    icon: _isSubmittingCash
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: const Text('Confirmer paiement espèces'),
                  ),
                ),
              ],
              if (_confirmedSale != null) ...[
                const SizedBox(height: 16),
                _ConfirmedSaleCard(result: _confirmedSale!),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    key: const Key('counter-sales-new-sale'),
                    onPressed: _isSubmittingCash || _isSubmittingReservation
                        ? null
                        : _resetForNewSale,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Nouvelle vente'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepartureSection(bool compact) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Étape 1 · Départ et classe',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                key: const Key('counter-sales-refresh-departures'),
                onPressed: _isLoadingDepartures ? null : _loadDepartures,
                tooltip: 'Rafraîchir les départs',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (_departureLoadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _departureLoadError!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ),
          if (_departures.isNotEmpty)
            KeyedSubtree(
              key: ValueKey(
                  'counter-sales-departure-${_selectedDepartureId ?? 'none'}'),
              child: DropdownButtonFormField<String>(
                key: const Key('counter-sales-departure-select'),
                initialValue: _selectedDepartureId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Départ'),
                items: _departures
                    .map(
                      (departure) => DropdownMenuItem(
                        value: departure.id,
                        child: Text(
                          _departureLabel(departure),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmittingReservation || _isSubmittingCash
                    ? null
                    : (value) async {
                        setState(() {
                          _selectedDepartureId = value;
                          _manualDepartureIdController.text = value ?? '';
                          _pendingSale = null;
                          _confirmedSale = null;
                        });
                        await _syncServiceClassFromDeparture();
                      },
              ),
            )
          else
            TextFormField(
              key: const Key('counter-sales-departure-id-field'),
              controller: _manualDepartureIdController,
              enabled: !_isSubmittingReservation && !_isSubmittingCash,
              decoration: const InputDecoration(
                labelText: 'Identifiant départ',
                helperText:
                    'Aucune liste départ accessible avec vos scopes. Saisissez l’identifiant backend du départ.',
              ),
            ),
          const SizedBox(height: 10),
          KeyedSubtree(
            key: ValueKey(
                'counter-sales-service-class-${_selectedServiceClassCode ?? 'none'}'),
            child: DropdownButtonFormField<String>(
              key: const Key('counter-sales-service-class'),
              initialValue: _selectedServiceClassCode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Classe de service'),
              items: const [
                DropdownMenuItem(value: 'ECONOMIE', child: Text('ÉCONOMIE')),
                DropdownMenuItem(value: 'PRESTIGE', child: Text('PRESTIGE')),
              ],
              onChanged: _isSubmittingReservation || _isSubmittingCash
                  ? null
                  : (value) => setState(() {
                        _selectedServiceClassCode = value;
                        _pendingSale = null;
                        _confirmedSale = null;
                      }),
            ),
          ),
          if (_isLoadingDepartures) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (compact) const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildForm(bool compact) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Étapes 2-7 · Payeur et voyageurs',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('counter-sales-customer-id-field'),
              controller: _customerIdController,
              enabled: _canSubmitReservation,
              decoration: const InputDecoration(
                labelText: 'Customer ID (UUID)',
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Le customer_id est obligatoire.';
                if (!_isUuid(text)) return 'Format UUID invalide.';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ..._travelers.asMap().entries.map((entry) {
              final index = entry.key;
              final traveler = entry.value;
              return _TravelerCard(
                index: index,
                traveler: traveler,
                compact: compact,
                serviceClassCode: _selectedServiceClassCode,
                canEdit: _canSubmitReservation,
                canRemove: _travelers.length > 1,
                onChanged: () => setState(() {
                  _pendingSale = null;
                  _confirmedSale = null;
                }),
                onRemove: () => _removeTraveler(index),
              );
            }),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const Key('counter-sales-add-traveler'),
                  onPressed: _canSubmitReservation ? _addTraveler : null,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Ajouter un voyageur'),
                ),
                ElevatedButton.icon(
                  key: const Key('counter-sales-create-reservation'),
                  onPressed: _canSubmitReservation ? _createReservation : null,
                  icon: _isSubmittingReservation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long_outlined),
                  label: const Text('Créer réservation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDepartures() async {
    setState(() {
      _isLoadingDepartures = true;
      _departureLoadError = null;
    });

    try {
      final response = await _operationalApiService.getOperationalDepartures(
        date: DateTime.now(),
        statuses: const ['open', 'scheduled'],
        pageSize: 50,
      );
      if (!mounted) return;
      setState(() {
        _departures = response.results;
        if (_departures.isNotEmpty && _selectedDepartureId == null) {
          _selectedDepartureId = _departures.first.id;
          _manualDepartureIdController.text = _departures.first.id;
        }
      });
      await _syncServiceClassFromDeparture();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _departures = const [];
        _departureLoadError =
            StructuredApiError.fromException(error).userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _departures = const [];
        _departureLoadError =
            'Impossible de charger la liste des départs pour ce compte.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingDepartures = false);
      }
    }
  }

  Future<void> _syncServiceClassFromDeparture() async {
    final departureId = _selectedDepartureId;
    if (departureId == null || departureId.isEmpty) return;

    try {
      final detail = await _stationBoardingApiService.getDepartureDetail(
        departureId: departureId,
      );
      if (!mounted) return;
      final code = detail.serviceClassCode?.toUpperCase();
      if (code == 'ECONOMIE' || code == 'PRESTIGE') {
        setState(() => _selectedServiceClassCode = code);
      }
    } catch (_) {
      // Le backend reste l'autorité; on garde la sélection manuelle de classe.
    }
  }

  Future<void> _createReservation() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final departureId =
        (_selectedDepartureId ?? _manualDepartureIdController.text).trim();
    final serviceClassCode =
        (_selectedServiceClassCode ?? '').trim().toUpperCase();

    if (departureId.isEmpty) {
      setState(() => _formError = 'Le departure_id est obligatoire.');
      return;
    }
    if (!_isUuid(departureId)) {
      setState(() => _formError = 'Le departure_id doit être un UUID valide.');
      return;
    }
    if (serviceClassCode != 'ECONOMIE' && serviceClassCode != 'PRESTIGE') {
      setState(() => _formError = 'La classe de service est obligatoire.');
      return;
    }

    final isForCustomerCount =
        _travelers.where((traveler) => traveler.isForCustomer).length;
    if (isForCustomerCount > 1) {
      setState(() => _formError =
          'Le client payeur ne peut être associé qu’à un seul voyageur.');
      return;
    }

    final seatNumbers = <int>[];
    final items = <StationCashSaleItemRequest>[];

    for (final traveler in _travelers) {
      final seatNumber = traveler.seatNumber;
      if (serviceClassCode == 'PRESTIGE') {
        if (seatNumber == null || seatNumber < 1) {
          setState(() => _formError =
              'Chaque voyageur Prestige doit avoir un seat_number.');
          return;
        }
        seatNumbers.add(seatNumber);
      }

      if (!traveler.isForCustomer && !traveler.hasTravelerIdentity) {
        setState(() => _formError =
            'Nom, prénom et téléphone sont obligatoires pour un voyageur non payeur.');
        return;
      }

      items.add(
        StationCashSaleItemRequest(
          isForCustomer: traveler.isForCustomer,
          seatNumber: serviceClassCode == 'PRESTIGE' ? seatNumber : null,
          travelerLastname: traveler.isForCustomer
              ? null
              : traveler.lastnameController.text.trim(),
          travelerFirstname: traveler.isForCustomer
              ? null
              : traveler.firstnameController.text.trim(),
          travelerPhone: traveler.isForCustomer
              ? null
              : traveler.phoneController.text.trim(),
        ),
      );
    }

    if (serviceClassCode == 'PRESTIGE' &&
        seatNumbers.toSet().length != seatNumbers.length) {
      setState(() => _formError = 'Les sièges Prestige doivent être uniques.');
      return;
    }

    setState(() {
      _formError = null;
      _isSubmittingReservation = true;
    });

    try {
      final response = await _counterApiService.createCashReservation(
        StationCashSaleCreateRequest(
          departureId: departureId,
          serviceClassCode: serviceClassCode,
          customerId: _customerIdController.text.trim(),
          items: items,
        ),
      );
      if (!mounted) return;
      setState(() {
        _pendingSale = response;
        _confirmedSale = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      final structured = StructuredApiError.fromException(error);
      setState(() => _formError = structured.userMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReservation = false);
      }
    }
  }

  Future<void> _confirmCash() async {
    final pendingSale = _pendingSale;
    if (pendingSale == null) return;

    final note = await _showCashConfirmationDialog();
    if (!mounted || note == null) return;
    final normalizedNote = note.trim();

    setState(() {
      _formError = null;
      _isSubmittingCash = true;
    });

    try {
      final response = await _counterApiService.confirmCashPayment(
        pendingSale.reservation.id,
        note: normalizedNote.isEmpty ? null : normalizedNote,
      );
      if (!mounted) return;
      setState(() => _confirmedSale = response);
    } on ApiException catch (error) {
      if (!mounted) return;
      final structured = StructuredApiError.fromException(error);
      setState(() => _formError = structured.userMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingCash = false);
      }
    }
  }

  Future<String?> _showCashConfirmationDialog() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _CashConfirmationDialog(),
    );
  }

  void _addTraveler() {
    setState(() {
      _travelers.add(_TravelerDraft(isForCustomer: false));
      _pendingSale = null;
      _confirmedSale = null;
    });
  }

  void _removeTraveler(int index) {
    final traveler = _travelers.removeAt(index);
    traveler.dispose();
    setState(() {
      _pendingSale = null;
      _confirmedSale = null;
    });
  }

  void _resetForNewSale() {
    for (final traveler in _travelers) {
      traveler.dispose();
    }
    setState(() {
      _travelers
        ..clear()
        ..add(_TravelerDraft(isForCustomer: true));
      _customerIdController.clear();
      _formError = null;
      _pendingSale = null;
      _confirmedSale = null;
    });
  }

  String _departureLabel(StationOperationalDeparture departure) {
    final date = departure.departureDate;
    final dateText = date == null
        ? '-'
        : '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
    return '$dateText ${departure.displayTime} · ${departure.displayRoute} · '
        '${departure.displayServiceClass}';
  }
}

class _TravelerDraft {
  bool isForCustomer;
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController seatNumberController = TextEditingController();

  _TravelerDraft({required this.isForCustomer});

  bool get hasTravelerIdentity {
    return lastnameController.text.trim().isNotEmpty &&
        firstnameController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty;
  }

  int? get seatNumber {
    final value = seatNumberController.text.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  void dispose() {
    lastnameController.dispose();
    firstnameController.dispose();
    phoneController.dispose();
    seatNumberController.dispose();
  }
}

class _CashConfirmationDialog extends StatefulWidget {
  const _CashConfirmationDialog();

  @override
  State<_CashConfirmationDialog> createState() =>
      _CashConfirmationDialogState();
}

class _CashConfirmationDialogState extends State<_CashConfirmationDialog> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirm() {
    final note = _noteController.text.trim();
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer le paiement espèces ?'),
      content: TextField(
        key: const Key('counter-sales-cash-note'),
        controller: _noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Note (optionnelle)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          key: const Key('counter-sales-cash-confirm-dialog-submit'),
          onPressed: _confirm,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

class _TravelerCard extends StatelessWidget {
  final int index;
  final _TravelerDraft traveler;
  final String? serviceClassCode;
  final bool compact;
  final bool canEdit;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _TravelerCard({
    required this.index,
    required this.traveler,
    required this.serviceClassCode,
    required this.compact,
    required this.canEdit,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isPrestige = serviceClassCode == 'PRESTIGE';

    final identityFields = [
      Expanded(
        child: TextFormField(
          key: Key('counter-sales-traveler-$index-lastname'),
          controller: traveler.lastnameController,
          enabled: canEdit && !traveler.isForCustomer,
          decoration: const InputDecoration(labelText: 'Nom voyageur'),
          onChanged: (_) => onChanged(),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextFormField(
          key: Key('counter-sales-traveler-$index-firstname'),
          controller: traveler.firstnameController,
          enabled: canEdit && !traveler.isForCustomer,
          decoration: const InputDecoration(labelText: 'Prénom voyageur'),
          onChanged: (_) => onChanged(),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextFormField(
          key: Key('counter-sales-traveler-$index-phone'),
          controller: traveler.phoneController,
          enabled: canEdit && !traveler.isForCustomer,
          decoration: const InputDecoration(labelText: 'Téléphone voyageur'),
          keyboardType: TextInputType.phone,
          onChanged: (_) => onChanged(),
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Voyageur ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (canRemove)
                IconButton(
                  key: Key('counter-sales-remove-traveler-$index'),
                  onPressed: canEdit ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Retirer ce voyageur',
                ),
            ],
          ),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              key: Key('counter-sales-is-for-customer-$index'),
              contentPadding: EdgeInsets.zero,
              value: traveler.isForCustomer,
              onChanged: canEdit
                  ? (value) {
                      traveler.isForCustomer = value;
                      onChanged();
                    }
                  : null,
              title: const Text('Ce billet est pour le client payeur'),
            ),
          ),
          if (!compact)
            Row(children: identityFields)
          else ...[
            identityFields[0],
            const SizedBox(height: 8),
            identityFields[2],
            const SizedBox(height: 8),
            identityFields[4],
          ],
          if (isPrestige) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: compact ? double.infinity : 180,
              child: TextFormField(
                key: Key('counter-sales-traveler-$index-seat-number'),
                controller: traveler.seatNumberController,
                enabled: canEdit,
                decoration: const InputDecoration(labelText: 'Seat number'),
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final User user;

  const _ContextCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final station =
        user.internalProfile?.station?.name ?? 'Gare non renseignée';
    final counter =
        user.internalProfile?.counter?.displayName ?? 'Guichet non renseigné';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vente guichet · Paiement espèces',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text('Gare: $station'),
          Text('Guichet: $counter'),
          const Text('Canal: station_counter'),
        ],
      ),
    );
  }
}

class _PendingReservationCard extends StatelessWidget {
  final StationCashSaleCreateResponse response;

  const _PendingReservationCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEC84B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Étapes 8-9 · Réservation créée, en attente de paiement',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Référence: ${response.reservation.reference}'),
          Text('Statut: ${response.reservation.status}'),
          Text('Voyageurs: ${response.itemCount}'),
          Text('Montant total: ${response.totalAmount} ${response.currency}'),
          Text(
              'Paiement espèces autorisé: ${response.canConfirmCash ? 'Oui' : 'Non'}'),
        ],
      ),
    );
  }
}

class _ConfirmedSaleCard extends StatelessWidget {
  final StationCashConfirmResponse result;

  const _ConfirmedSaleCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFABEFC6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Étapes 10-11 · Paiement confirmé',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Réservation: ${result.reservation.reference}'),
          Text('Statut réservation: ${result.reservation.status}'),
          Text(
              'Paiement: ${result.payment.reference} (${result.payment.status})'),
          Text('Montant encaissé: ${result.payment.displayAmount}'),
          Text(result.alreadyPaid
              ? 'Paiement déjà confirmé auparavant.'
              : 'Paiement confirmé avec succès.'),
          const SizedBox(height: 8),
          const Text(
            'Tickets générés',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (result.tickets.isEmpty)
            const Text('Aucun ticket retourné par le backend.')
          else
            ...result.tickets.map(
              (ticket) => Text(
                '- ${ticket.reference} · ${ticket.seatLabel} · ${ticket.travelerFullName.isEmpty ? '-' : ticket.travelerFullName}',
              ),
            ),
        ],
      ),
    );
  }
}

bool _isUuid(String value) {
  final regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return regex.hasMatch(value);
}
