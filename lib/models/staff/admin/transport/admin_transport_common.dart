typedef AdminTransportJson = Map<String, dynamic>;

String readTransportString(dynamic value) => value?.toString() ?? '';

String? readTransportNullableString(dynamic value) => value?.toString();

bool readTransportBool(dynamic value, {bool defaultValue = false}) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return defaultValue;
}

int readTransportInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

AdminTransportJson readTransportMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return AdminTransportJson.from(value);
  return const {};
}

String? trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

class AdminTransportPatchField<T> {
  final bool isProvided;
  final T? value;

  const AdminTransportPatchField.absent()
      : isProvided = false,
        value = null;

  const AdminTransportPatchField.value(T this.value) : isProvided = true;

  const AdminTransportPatchField.clear()
      : isProvided = true,
        value = null;
}

void writePatchField<T>(
  AdminTransportJson json,
  String key,
  AdminTransportPatchField<T> field, {
  Object? Function(T? value)? encode,
}) {
  if (!field.isProvided) return;
  json[key] = encode == null ? field.value : encode(field.value);
}
