import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_icons.dart';
import 'auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  var _isSubmitting = false;
  var _obscureCurrentPassword = true;
  var _obscureNewPassword = true;
  var _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 460,
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.10,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: AppNeumorphic.softShadow(
                                theme.brightness,
                                depth: 0.10,
                                distance: 6,
                                blur: 16,
                              ),
                            ),
                            child: Icon(
                              AppIcons.lock,
                              size: 38,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Change Password',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set a new password before continuing.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const Key('currentPasswordField'),
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: const Icon(AppIcons.lock),
                            suffixIcon: IconButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscureCurrentPassword =
                                            !_obscureCurrentPassword;
                                      });
                                    },
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? AppIcons.eyeOff
                                    : AppIcons.eye,
                              ),
                            ),
                          ),
                          validator: _requiredPassword,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('newPasswordField'),
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(AppIcons.lock),
                            suffixIcon: IconButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscureNewPassword =
                                            !_obscureNewPassword;
                                      });
                                    },
                              icon: Icon(
                                _obscureNewPassword
                                    ? AppIcons.eyeOff
                                    : AppIcons.eye,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.trim().isEmpty) {
                              return 'New password is required';
                            }
                            if (password.length < 6) {
                              return 'Use at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('confirmPasswordField'),
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(AppIcons.lock),
                            suffixIcon: IconButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? AppIcons.eyeOff
                                    : AppIcons.eye,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '') != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            key: const Key('changePasswordSubmitButton'),
                            onPressed: _isSubmitting ? null : _submit,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _isSubmitting
                                  ? SizedBox.square(
                                      key: const ValueKey(
                                        'changePasswordLoader',
                                      ),
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              colorScheme.onPrimary,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'UPDATE PASSWORD',
                                      key: ValueKey('changePasswordText'),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => ref
                                    .read(authControllerProvider.notifier)
                                    .logout(),
                          icon: const Icon(AppIcons.logout),
                          label: const Text('Logout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String? _requiredPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);

    await ref
        .read(authControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
