import 'package:equatable/equatable.dart';

abstract class VoiceSessionState extends Equatable {
  const VoiceSessionState();

  @override
  List<Object?> get props => [];
}

class VoiceSessionInitial extends VoiceSessionState {}

class VoiceSessionLoading extends VoiceSessionState {}

class VoiceSessionCreated extends VoiceSessionState {
  final int sessionId;

  const VoiceSessionCreated(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class VoiceSessionActionSuccess extends VoiceSessionState {
  final String message;

  const VoiceSessionActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class VoiceSessionLeft extends VoiceSessionState {
  final int sessionId;

  const VoiceSessionLeft(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

class VoiceSessionError extends VoiceSessionState {
  final String message;

  const VoiceSessionError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Tek bir session'ın detayları yüklendi
class VoiceSessionDetailsLoaded extends VoiceSessionState {
  final dynamic session; // VoiceSessionEntity

  const VoiceSessionDetailsLoaded(this.session);

  @override
  List<Object?> get props => [session];
}

/// Kullanıcının aktif session'ları yüklendi
class MyVoiceSessionsLoaded extends VoiceSessionState {
  final List<dynamic> sessions; // List<VoiceSessionEntity>

  const MyVoiceSessionsLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// Davet kabul edildi
class VoiceSessionInviteAccepted extends VoiceSessionState {
  final int sessionId;

  const VoiceSessionInviteAccepted(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
