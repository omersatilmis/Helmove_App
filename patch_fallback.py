import re

file_path = r'c:\Users\omerf\FlutterProjeleri\moto_comm_app_1\lib\core\services\signalr_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '''  /// SDP Offer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendOffer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Offer gÃƒÂ¶nderilemedi - BAGLANTI YOK! target=$targetUserId",
      );
      throw StateError('SignalR not connected while sending offer');
    }''',
    '''  /// SDP Offer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendOffer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Offer gonderilemedi - BAGLANTI YOK! Fallback (HTTP) deneniyor... target=$targetUserId",
      );
      return await _fallbackSendSignal('SendOffer', targetUserId, 'offer', sdp);
    }'''
)

content = content.replace(
    '''  /// SDP Answer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendAnswer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Answer gÃƒÂ¶nderilemedi - BAGLANTI YOK! target=$targetUserId",
      );
      throw StateError('SignalR not connected while sending answer');
    }''',
    '''  /// SDP Answer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendAnswer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Answer gonderilemedi - BAGLANTI YOK! Fallback (HTTP) deneniyor... target=$targetUserId",
      );
      return await _fallbackSendSignal('SendAnswer', targetUserId, 'answer', sdp);
    }'''
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('SignalR HTTP Fallback wired correctly.')
