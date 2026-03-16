import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/base_navigation_args.dart';

/// Mixin to enforce navigation argument validation and security policies.
/// Usage:
/// class _MyPageState extends State&lt;MyPage&gt; with NavigationGuardMixin&lt;MyPage&gt; { ... }
mixin NavigationGuardMixin<T extends StatefulWidget> on State<T> {
  /// The arguments passed to the page.
  BaseNavigationArgs? get args;

  @override
  void initState() {
    super.initState();
    // Schedule validation after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateArgs();
    });
  }

  void _validateArgs() {
    final arguments = args;
    if (arguments == null || !arguments.isValid) {
      final reason =
          arguments?.errorMessage ?? 'Eksik veya geçersiz parametreler.';
      _handleInvalidNavigation(reason);
    }
  }

  void _handleInvalidNavigation(String reason) {
    if (!mounted) return;

    // Show standardized error snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(reason)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    // Safe Redirect
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/communication'); // Default safe fallback
    }
  }

  /// Manually trigger a security exit (e.g. from BlocListener)
  void forceExitPage({String message = 'Oturum sonlandırıldı.'}) {
    _handleInvalidNavigation(message);
  }
}
