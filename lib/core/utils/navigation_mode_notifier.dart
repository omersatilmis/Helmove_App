import 'package:flutter/foundation.dart';

/// Harita navigasyon modu aktifken true olur.
/// MapBloc tarafından set edilir; BottomBarWrapper dinler.
final ValueNotifier<bool> navigationModeNotifier = ValueNotifier(false);
