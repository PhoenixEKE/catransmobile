import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:catrans_app/core/network/api_exception.dart';
import 'package:catrans_app/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      newPasswordConfirm: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      return;
    }

    final fieldErrors = _fieldErrorsFrom(error);
    if (fieldErrors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _currentPasswordError = fieldErrors['current_password'];
      _newPasswordError =
          fieldErrors['new_password'] ?? fieldErrors['new_password_confirm'];
    });
  }

  /// Reads the backend's field-scoped error payload (e.g.
  /// `{"current_password": ["Mot de passe actuel incorrect."]}`) so the
  /// "current password wrong" and "new password too weak" cases can be
  /// shown on their respective fields instead of one generic message.
  Map<String, String> _fieldErrorsFrom(ApiException error) {
    final details = error.details;
    if (details is! Map) return {};

    final result = <String, String>{};
    for (final key in [
      'current_password',
      'new_password',
      'new_password_confirm',
    ]) {
      final message = _firstString(details[key]);
      if (message != null) result[key] = message;
    }
    return result;
  }

  String? _firstString(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is List && value.isNotEmpty) {
      return value.map((item) => item.toString()).join(' ');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Modifier le mot de passe'),
        backgroundColor: const Color(0xFF0F056B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline,
                      color: Color(0xFF0F056B), size: 42),
                  const SizedBox(height: 16),
                  const Text(
                    'Changer votre mot de passe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F056B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PasswordField(
                    controller: _currentPasswordController,
                    label: 'Mot de passe actuel',
                    obscure: _obscureCurrent,
                    onToggleObscure: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    errorText: _currentPasswordError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe actuel';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _PasswordField(
                    controller: _newPasswordController,
                    label: 'Nouveau mot de passe',
                    obscure: _obscureNew,
                    onToggleObscure: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    errorText: _newPasswordError,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nouveau mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _PasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer le nouveau mot de passe',
                    obscure: _obscureConfirm,
                    onToggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le nouveau mot de passe';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFD807),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'ENREGISTRER',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? errorText;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF0F056B)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: onToggleObscure,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F056B), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        errorText: errorText,
      ),
      validator: validator,
    );
  }
}
