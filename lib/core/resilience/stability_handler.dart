import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Abstract base class for all stability handlers.
///
/// Each handler is responsible for listening to a specific Bloc and
/// taking action (Redirect, SnackBar, Data Clear) based on state changes.
abstract class StabilityHandler<B extends StateStreamable<S>, S> {
  /// The Bloc to listen to.
  final B bloc;

  StabilityHandler(this.bloc);

  /// Called when the Bloc emits a new state.
  /// Returns `true` if this handler handled the state and no further action is needed.
  void handleState(BuildContext context, S state);

  /// Helper to show a standardized notification.
  void showNotification(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red
            : Colors.orange, // Standardize colors
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
