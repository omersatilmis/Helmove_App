import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global BlocObserver that logs ALL Bloc errors to the debug console.
/// This prevents the "invisible rethrow" problem where bloc.dart:231
/// masks the actual exception. Every error that any Bloc/Cubit throws
/// will be printed here FIRST, before it has a chance to crash the app.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint(
      '🔴 [AppBlocObserver] ${bloc.runtimeType} threw an error:\n'
      '   Error: $error\n'
      '   StackTrace: $stackTrace',
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    // Only log VoiceSessionBloc transitions to avoid noise
    if (bloc.runtimeType.toString().contains('VoiceSession')) {
      debugPrint(
        '🔄 [AppBlocObserver] ${bloc.runtimeType} '
        '${transition.event.runtimeType} → ${transition.nextState.runtimeType}',
      );
    }
    super.onTransition(bloc, transition);
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    if (bloc.runtimeType.toString().contains('VoiceSession')) {
      debugPrint(
        '📩 [AppBlocObserver] ${bloc.runtimeType} received ${event.runtimeType}',
      );
    }
    super.onEvent(bloc, event);
  }
}
