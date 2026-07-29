import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/models/staff/admin/operations/admin_promotion_models.dart';
import 'package:catrans_app/models/staff/paged_result.dart';
import 'package:catrans_app/services/api/staff/admin/admin_operations_api_service.dart';
import 'package:catrans_app/widgets/staff/staff_empty_state.dart';
import 'package:catrans_app/widgets/staff/staff_error_state.dart';
import 'package:catrans_app/widgets/staff/staff_loading_state.dart';

class AdminPromotionsScreen extends StatefulWidget {
  final bool canManage;

  const AdminPromotionsScreen({super.key, required this.canManage});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final _apiService = AdminOperationsApiService();
  final _queryController = TextEditingController();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  PagedResult<AdminPromotion>? _page;
  AdminPromotion? _selectedPromotion;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isReordering = false;
  bool _isActiveDraft = true;
  bool? _isActiveFilter;
  String? _error;
  int _pageIndex = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (page != null) _pageIndex = page;
    });

    try {
      final result = await _apiService.listPromotions(
        query: _queryController.text,
        isActive: _isActiveFilter,
        page: _pageIndex,
      );
      if (!mounted) return;
      setState(() {
        _page = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _readableError(error);
        _isLoading = false;
      });
    }
  }

  void _selectPromotion(AdminPromotion promotion) {
    setState(() {
      _selectedPromotion = promotion;
      _titleController.text = promotion.title;
      _textController.text = promotion.text;
      _pickedImageBytes = null;
      _pickedImageName = null;
      _isActiveDraft = promotion.isActive;
    });
  }

  void _newPromotion() {
    setState(() {
      _selectedPromotion = null;
      _titleController.clear();
      _textController.clear();
      _pickedImageBytes = null;
      _pickedImageName = null;
      _isActiveDraft = true;
    });
  }

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = file.name;
    });
  }

  void _clearPickedImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageName = null;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Le titre est obligatoire.');
      return;
    }
    if (_selectedPromotion == null && _pickedImageBytes == null) {
      _showMessage("L'image est obligatoire à la création.");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final request = AdminPromotionWriteRequest(
        title: title,
        text: _textController.text,
        isActive: _isActiveDraft,
        imageBytes: _pickedImageBytes,
        imageFileName: _pickedImageName,
      );
      final selected = _selectedPromotion;
      final saved = selected == null
          ? await _apiService.createPromotion(request)
          : await _apiService.updatePromotion(selected.id, request);
      if (!mounted) return;
      if (selected == null) {
        _showMessage('Promotion créée.');
        _newPromotion();
      } else {
        _showMessage('Promotion mise à jour.');
        _selectPromotion(saved);
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readableError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _movePromotion(AdminPromotion promotion, String direction) async {
    if (!widget.canManage || _isReordering) return;
    setState(() => _isReordering = true);
    try {
      await _apiService.movePromotion(promotion.id, direction);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readableError(error));
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  Future<void> _toggleActive(AdminPromotion promotion) async {
    if (!widget.canManage) return;
    setState(() => _isSaving = true);
    try {
      final updated = promotion.isActive
          ? await _apiService.deactivatePromotion(promotion.id)
          : await _apiService.activatePromotion(promotion.id);
      if (!mounted) return;
      _showMessage(
          updated.isActive ? 'Promotion activée.' : 'Promotion désactivée.');
      _selectPromotion(updated);
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readableError(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toolbar(
          queryController: _queryController,
          isActive: _isActiveFilter,
          canManage: widget.canManage,
          onActiveChanged: (value) {
            setState(() {
              _isActiveFilter = switch (value) {
                'true' => true,
                'false' => false,
                _ => null,
              };
            });
            _load(page: 1);
          },
          onQuerySubmitted: (_) => _load(page: 1),
          onRefresh: () => _load(),
          onNew: _newPromotion,
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading && _page == null) {
      return const StaffLoadingState(message: 'Chargement des promotions...');
    }
    if (_error != null) {
      return StaffErrorState(message: _error!, onRetry: _load);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 940;
        final list = _PromotionList(
          page: _page,
          selectedId: _selectedPromotion?.id,
          isLoading: _isLoading,
          canManage: widget.canManage,
          isReordering: _isReordering,
          onSelect: _selectPromotion,
          onToggleActive: _toggleActive,
          onMove: _movePromotion,
          onPrevious: (_page?.hasPrevious ?? false)
              ? () => _load(page: (_pageIndex - 1).clamp(1, 999).toInt())
              : null,
          onNext: (_page?.hasNext ?? false)
              ? () => _load(page: _pageIndex + 1)
              : null,
        );
        final form = _PromotionForm(
          selectedPromotion: _selectedPromotion,
          titleController: _titleController,
          textController: _textController,
          pickedImageBytes: _pickedImageBytes,
          pickedImageName: _pickedImageName,
          isActive: _isActiveDraft,
          isSaving: _isSaving,
          canManage: widget.canManage,
          onActiveChanged: (value) => setState(() => _isActiveDraft = value),
          onPickImage: _pickImage,
          onClearPickedImage: _clearPickedImage,
          onSave: _save,
        );

        if (compact) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                list,
                const SizedBox(height: 12),
                form,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 420, child: list),
            const SizedBox(width: 14),
            Expanded(child: form),
          ],
        );
      },
    );
  }

  String _readableError(Object error) {
    if (error is ApiException) return error.message;
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController queryController;
  final bool? isActive;
  final bool canManage;
  final ValueChanged<String?> onActiveChanged;
  final ValueChanged<String> onQuerySubmitted;
  final VoidCallback onRefresh;
  final VoidCallback onNew;

  const _Toolbar({
    required this.queryController,
    required this.isActive,
    required this.canManage,
    required this.onActiveChanged,
    required this.onQuerySubmitted,
    required this.onRefresh,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            controller: queryController,
            decoration: const InputDecoration(labelText: 'Recherche'),
            onSubmitted: onQuerySubmitted,
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: switch (isActive) {
              true => 'true',
              false => 'false',
              null => null,
            },
            decoration: const InputDecoration(labelText: 'Statut'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tous')),
              DropdownMenuItem(value: 'true', child: Text('Actives')),
              DropdownMenuItem(value: 'false', child: Text('Inactives')),
            ],
            onChanged: onActiveChanged,
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Rafraîchir'),
        ),
        if (canManage)
          ElevatedButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle promotion'),
          ),
      ],
    );
  }
}

class _PromotionList extends StatelessWidget {
  final PagedResult<AdminPromotion>? page;
  final String? selectedId;
  final bool isLoading;
  final bool canManage;
  final bool isReordering;
  final ValueChanged<AdminPromotion> onSelect;
  final ValueChanged<AdminPromotion> onToggleActive;
  final void Function(AdminPromotion promotion, String direction) onMove;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PromotionList({
    required this.page,
    required this.selectedId,
    required this.isLoading,
    required this.canManage,
    required this.isReordering,
    required this.onSelect,
    required this.onToggleActive,
    required this.onMove,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final results = page?.results ?? const <AdminPromotion>[];
    if (isLoading && results.isEmpty) {
      return const StaffLoadingState(message: 'Chargement des promotions...');
    }
    if (results.isEmpty) {
      return const StaffEmptyState(
        icon: Icons.campaign_outlined,
        title: 'Aucune promotion',
        message: 'Aucune promotion ne correspond aux filtres.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...results.asMap().entries.map((entry) {
          final index = entry.key;
          final promotion = entry.value;
          final selected = promotion.id == selectedId;
          final isFirstOverall = index == 0 && !(page?.hasPrevious ?? false);
          final isLastOverall =
              index == results.length - 1 && !(page?.hasNext ?? false);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: selected ? const Color(0xFFF3F5FF) : Colors.white,
            child: ListTile(
              leading: _PromotionThumb(imageUrl: promotion.imageUrl),
              title: Text(
                promotion.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                promotion.isActive ? 'Active' : 'Inactive',
              ),
              selected: selected,
              onTap: () => onSelect(promotion),
              trailing: canManage
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Monter',
                          visualDensity: VisualDensity.compact,
                          onPressed: !isReordering && !isFirstOverall
                              ? () => onMove(promotion, 'up')
                              : null,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Descendre',
                          visualDensity: VisualDensity.compact,
                          onPressed: !isReordering && !isLastOverall
                              ? () => onMove(promotion, 'down')
                              : null,
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton(
                          tooltip: promotion.isActive ? 'Désactiver' : 'Activer',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onToggleActive(promotion),
                          icon: Icon(
                            promotion.isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Page précédente',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Page suivante',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

class _PromotionForm extends StatelessWidget {
  final AdminPromotion? selectedPromotion;
  final TextEditingController titleController;
  final TextEditingController textController;
  final Uint8List? pickedImageBytes;
  final String? pickedImageName;
  final bool isActive;
  final bool isSaving;
  final bool canManage;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onPickImage;
  final VoidCallback onClearPickedImage;
  final VoidCallback onSave;

  const _PromotionForm({
    required this.selectedPromotion,
    required this.titleController,
    required this.textController,
    required this.pickedImageBytes,
    required this.pickedImageName,
    required this.isActive,
    required this.isSaving,
    required this.canManage,
    required this.onActiveChanged,
    required this.onPickImage,
    required this.onClearPickedImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = selectedPromotion?.imageUrl;
    final pickedBytes = pickedImageBytes;
    final hasExistingImage = imageUrl != null && imageUrl.isNotEmpty;
    final isCreate = selectedPromotion == null;
    final enabled = canManage && !isSaving;
    return SingleChildScrollView(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_outlined, color: Color(0xFF0F056B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCreate ? 'Nouvelle promotion' : 'Modifier la promotion',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: pickedBytes != null
                      ? Image.memory(pickedBytes, fit: BoxFit.cover)
                      : hasExistingImage
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE9ECF4),
                                child:
                                    const Icon(Icons.broken_image_outlined),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFE9ECF4),
                              child: const Icon(
                                Icons.image_outlined,
                                color: Color(0xFF687083),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onPickImage : null,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      hasExistingImage || pickedBytes != null
                          ? "Changer l'image"
                          : 'Choisir une image...',
                    ),
                  ),
                  if (pickedBytes != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: enabled ? onClearPickedImage : null,
                      child: const Text('Retirer'),
                    ),
                  ],
                ],
              ),
              if (pickedImageName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Sélectionné : $pickedImageName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF687083),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                enabled: enabled,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Texte'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isActive,
                onChanged: canManage && !isSaving ? onActiveChanged : null,
                title: const Text('Active'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: canManage && !isSaving ? onSave : null,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionThumb extends StatelessWidget {
  final String? imageUrl;

  const _PromotionThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 54,
        height: 54,
        color: const Color(0xFFE9ECF4),
        child: url == null || url.isEmpty
            ? const Icon(Icons.image_outlined, color: Color(0xFF687083))
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}
