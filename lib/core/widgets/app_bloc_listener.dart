import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_state.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_state.dart';
import 'package:moto_comm_app_1/core/resilience/ride_stability_handler.dart';
import 'package:moto_comm_app_1/core/resilience/voice_stability_handler.dart';
import 'package:moto_comm_app_1/core/utils/debouncer.dart';

class AppBlocListener extends StatefulWidget {
  final Widget child;

  const AppBlocListener({super.key, required this.child});

  @override
  State<AppBlocListener> createState() => _AppBlocListenerState();
}

class _AppBlocListenerState extends State<AppBlocListener> {
  late final Debouncer _debouncer;
  late final RideStabilityHandler _rideHandler;
  late final VoiceStabilityHandler _voiceHandler;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(milliseconds: 300); // 300ms debounce for UI updates

    // Handlers are instantiated here to keep state/logic clean via Bloc context
    final rideBloc = context.read<GroupRideBloc>();
    final voiceBloc = context.read<VoiceSessionBloc>();

    _rideHandler = RideStabilityHandler(rideBloc, voiceBloc);
    _voiceHandler = VoiceStabilityHandler(voiceBloc);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AuthProvider for changes
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          // Optionally clear debouncer or ignore.
        }

        return MultiBlocListener(
          listeners: [
            BlocListener<GroupRideBloc, GroupRideState>(
              listener: (context, state) {
                if (authProvider.isAuthenticated) {
                  _debouncer.run(() {
                    if (mounted) _rideHandler.handleState(context, state);
                  });
                }
              },
            ),
            BlocListener<VoiceSessionBloc, VoiceSessionState>(
              listener: (context, state) {
                if (authProvider.isAuthenticated) {
                  _voiceHandler.handleState(context, state);
                }
              },
            ),
          ],
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}
