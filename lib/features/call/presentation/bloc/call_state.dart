import 'package:equatable/equatable.dart';

/// CallBloc State'leri — P2P Arama Durumları
///
/// Durum geçişleri:
/// CallInitial → CallOutgoing (arayan) veya CallIncoming (aranan)
/// CallOutgoing → CallConnecting → CallActive → CallEnded
/// CallIncoming → CallConnecting → CallActive → CallEnded
/// Herhangi bir state → CallEnded (hata, red, timeout)
abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

/// Boşta — Arama yok
class CallInitial extends CallState {
  const CallInitial();
}

/// Arıyor — Arama isteği gönderildi, cevap bekleniyor
class CallOutgoing extends CallState {
  final int targetUserId;
  final String? targetDisplayName;

  const CallOutgoing({required this.targetUserId, this.targetDisplayName});

  @override
  List<Object?> get props => [targetUserId, targetDisplayName];
}

/// Gelen arama — Telefon çalıyor (Kabul/Red ekranı)
class CallIncoming extends CallState {
  final int callerId;
  final String? callerDisplayName;
  final String? callerProfileImageUrl;

  const CallIncoming({
    required this.callerId,
    this.callerDisplayName,
    this.callerProfileImageUrl,
  });

  @override
  List<Object?> get props => [callerId, callerDisplayName, callerProfileImageUrl];
}

/// Bağlanıyor — WebRTC PeerConnection kuruluyor (ICE exchange)
class CallConnecting extends CallState {
  final int remoteUserId;

  const CallConnecting({required this.remoteUserId});

  @override
  List<Object?> get props => [remoteUserId];
}

/// Aktif arama — Bağlantı kuruldu, konuşuluyor
class CallActive extends CallState {
  final int remoteUserId;
  final bool isMicrophoneOn;
  final bool isSpeakerOn;
  final Duration callDuration;

  const CallActive({
    required this.remoteUserId,
    this.isMicrophoneOn = true,
    this.isSpeakerOn = false,
    this.callDuration = Duration.zero,
  });

  CallActive copyWith({
    bool? isMicrophoneOn,
    bool? isSpeakerOn,
    Duration? callDuration,
  }) {
    return CallActive(
      remoteUserId: remoteUserId,
      isMicrophoneOn: isMicrophoneOn ?? this.isMicrophoneOn,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      callDuration: callDuration ?? this.callDuration,
    );
  }

  @override
  List<Object?> get props => [
    remoteUserId,
    isMicrophoneOn,
    isSpeakerOn,
    callDuration,
  ];
}

/// Arama bitti
class CallEnded extends CallState {
  final String? reason;
  final Duration? callDuration;

  const CallEnded({this.reason, this.callDuration});

  @override
  List<Object?> get props => [reason, callDuration];
}

/// Hata durumu
class CallError extends CallState {
  final String message;

  const CallError({required this.message});

  @override
  List<Object?> get props => [message];
}
