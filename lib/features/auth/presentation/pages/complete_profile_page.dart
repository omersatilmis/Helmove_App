import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/core/widgets/app_input_field.dart';
import 'package:helmove/features/auth/presentation/widgets/auth_header_widget.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CompleteProfilePage extends StatefulWidget {
  final String? prefillFirstName;
  final String? prefillLastName;

  const CompleteProfilePage({
    super.key,
    this.prefillFirstName,
    this.prefillLastName,
  });

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _firstNameController = TextEditingController(
      text: widget.prefillFirstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.prefillLastName ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileProvider = context.read<ProfileProvider>();
      final success = await profileProvider.updateProfile(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        context.go('/homepage');
      } else {
        setState(() {
          _errorMessage =
              profileProvider.errorMessage ?? 'Profil güncellenemedi';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight =
                (constraints.maxHeight * 0.28).clamp(180.0, 280.0);
            const horizontalPadding = 24.0;

            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: AuthHeaderWidget(
                    title: l10n.completeProfileTitle,
                    subtitle: l10n.completeProfileSubtitle,
                    verticalOffset: -1.0,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppInputField(
                            controller: _usernameController,
                            type: AppInputType.standard,
                            label: l10n.username,
                            leadingIcon: Icons.alternate_email,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.usernameRequired;
                              }
                              if (val.trim().length < 3) {
                                return l10n.usernameTooShort;
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_.]+$')
                                  .hasMatch(val.trim())) {
                                return l10n.usernameInvalidChars;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          AppInputField(
                            controller: _firstNameController,
                            type: AppInputType.standard,
                            label: l10n.firstName,
                            leadingIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.firstNameRequired;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          AppInputField(
                            controller: _lastNameController,
                            type: AppInputType.standard,
                            label: l10n.lastName,
                            leadingIcon: Icons.person_outline,
                            textInputAction: TextInputAction.done,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return l10n.lastNameRequired;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          AppButton(
                            text: l10n.saveAndContinue,
                            isLoading: _isLoading,
                            size: AppButtonSize.large,
                            borderRadius: BorderRadius.circular(16),
                            isFullWidth: true,
                            onPressed: _isLoading ? null : _handleSave,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
