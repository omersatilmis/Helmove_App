import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/widgets/app_button.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Geçici: sign-in sırasında alınan isim bilgisini tutmak için
class _SocialNameInfo {
  final String? firstName;
  final String? lastName;
  const _SocialNameInfo({this.firstName, this.lastName});
}

class PreAuthPage extends StatefulWidget {
  const PreAuthPage({super.key});

  @override
  State<PreAuthPage> createState() => _PreAuthPageState();
}

class _PreAuthPageState extends State<PreAuthPage> {
  bool _isSocialLoading = false;
  String? _activeProvider;
  _SocialNameInfo? _lastNameInfo;

  // --- SOSYAL GİRİŞ MANTIĞI (UPSERT) ---
  Future<void> _handleSocialSignIn(String provider) async {
    if (_isSocialLoading) return;

    setState(() {
      _isSocialLoading = true;
      _activeProvider = provider;
    });

    try {
      bool success = false;
      switch (provider) {
        case 'google':
          success = await _signInWithGoogle();
          break;
        case 'apple':
          success = await _signInWithApple();
          break;
      }

      if (!mounted) return;

      if (success) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.wasNewSocialUser) {
          context.go('/complete-profile', extra: {
            'firstName': _lastNameInfo?.firstName,
            'lastName': _lastNameInfo?.lastName,
          });
        } else {
          context.go('/homepage');
        }
      } else {
        _showErrorSnackBar(context.read<AuthProvider>().errorMessage);
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar(null);
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
          _activeProvider = null;
        });
      }
    }
  }

  void _showErrorSnackBar(String? backendMessage) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (backendMessage != null && backendMessage.trim().isNotEmpty)
              ? backendMessage
              : l10n.socialSignInNotReady,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final googleSignIn = GoogleSignIn(
      serverClientId:
          '38184125630-qo9bffnh1ul85e5jaun0ldmppb3lm38f.apps.googleusercontent.com',
      scopes: const ['email', 'profile'],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return false;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    
    final resolvedIdToken = (idToken != null && idToken.trim().isNotEmpty)
        ? idToken
        : accessToken;

    if (resolvedIdToken == null || resolvedIdToken.trim().isEmpty) {
      return false;
    }

    _lastNameInfo = _SocialNameInfo(
      firstName: account.displayName?.split(' ').firstOrNull,
      lastName: account.displayName?.split(' ').skip(1).join(' '),
    );

    return authProvider.socialSignIn(
      provider: 'google',
      idToken: resolvedIdToken,
      accessToken: accessToken,
      email: account.email,
      displayName: account.displayName,
      rememberMe: true,
    );
  }

  Future<bool> _signInWithApple() async {
    final authProvider = context.read<AuthProvider>();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      return false;
    }

    final firstName = credential.givenName?.trim() ?? '';
    final lastName = credential.familyName?.trim() ?? '';
    final displayName = '$firstName $lastName'.trim();

    _lastNameInfo = _SocialNameInfo(
      firstName: firstName.isNotEmpty ? firstName : null,
      lastName: lastName.isNotEmpty ? lastName : null,
    );

    return authProvider.socialSignIn(
      provider: 'apple',
      idToken: identityToken,
      authorizationCode: credential.authorizationCode,
      email: credential.email,
      displayName: displayName.isEmpty ? null : displayName,
      rememberMe: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIos = !kIsWeb && Platform.isIOS;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 360 ? 20.0 : 32.0;

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        
                        // BAŞLIK
                        Text(
                          l10n.preAuthWelcomeTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          l10n.preAuthSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ANA BUTONLAR
                        AppButton(
                          text: l10n.login,
                          onPressed: () => context.push('/login'),
                          size: AppButtonSize.large,
                          isFullWidth: true,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: l10n.createAccount,
                          onPressed: () => context.push('/register'),
                          size: AppButtonSize.large,
                          isFullWidth: true,
                          variant: AppButtonVariant.secondary,
                          style: AppButtonStyle.outlined,
                          borderRadius: BorderRadius.circular(16),
                        ),

                        const SizedBox(height: 32),

                        // AYIRICI
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.colorScheme.outlineVariant, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                l10n.preAuthSocialDivider,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.colorScheme.outline,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: theme.colorScheme.outlineVariant, thickness: 1)),
                          ],
                        ),
                        
                        const SizedBox(height: 32),

                        // SOSYAL BUTONLAR
                        AppButton(
                          text: l10n.continueWithGoogle,
                          onPressed: _isSocialLoading ? null : () => _handleSocialSignIn('google'),
                          isLoading: _isSocialLoading && _activeProvider == 'google',
                          variant: AppButtonVariant.secondary,
                          style: AppButtonStyle.outlined,
                          isFullWidth: true,
                          borderRadius: BorderRadius.circular(16),
                          icon: Icons.g_mobiledata_rounded,
                          size: AppButtonSize.large,
                        ),
                        
                        if (isIos) ...[
                          const SizedBox(height: 16),
                          AppButton(
                            text: l10n.continueWithApple,
                            onPressed: _isSocialLoading ? null : () => _handleSocialSignIn('apple'),
                            isLoading: _isSocialLoading && _activeProvider == 'apple',
                            variant: AppButtonVariant.secondary,
                            style: AppButtonStyle.outlined,
                            isFullWidth: true,
                            borderRadius: BorderRadius.circular(16),
                            icon: Icons.apple,
                            size: AppButtonSize.large,
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
