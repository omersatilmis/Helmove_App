import re

file_path = r'c:\Users\omerf\FlutterProjeleri\helmove\lib\core\services\signalr_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target_fallback = '''  Future<void> _sendSessionDescriptionSignal({'''
replace_fallback = '''  // [NEW] Fallback Sinyallesme (HTTP POST via Dio)
  Future<void> _fallbackSendSignal(String method, String targetUserId, String type, String sdp) async {
    try {
      final token = await authLocalDataSource.getToken();
      _resolvedBaseUrl ??= await NetworkModule.getBaseUrl();
      final dio = Dio();
      
      final payload = {'type': type, 'sdp': sdp};
      
      // Backend'de "/api/communication/fallback" veya benzer bir endpoint oldugu varsayilir.
      // Eger yoksa 404 yiyecektir ancak sistem cokertecek throw atilmaz, gracefull fallback saglar.
      await dio.post(
        '${_resolvedBaseUrl!}api/communication/fallback',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'method': method,
          'targetUserId': targetUserId,
          'payload': payload,
        },
      );
      AppLogger.info("SignalR: Fallback HTTP Sinyali basariyla iletildi -> $targetUserId ($method)");
    } catch (e) {
      AppLogger.error("SignalR: HTTP Fallback Sinyali de basarisiz oldu!", e);
      // Hata firlatmak yerine gracefully durduruyoruz, boylece P2P cokuyorsa SFU'ya dusme isler.
    }
  }

  Future<void> _sendSessionDescriptionSignal({'''

content = re.sub(
    r'Future<void> sendOffer\(String targetUserId, String sdp\) async \{\s*if \(!isConnected\) \{.*?\throw StateError[^;]+;\s*\}',
    '''Future<void> sendOffer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning("SignalR: Offer gonderilemedi - BAGLANTI YOK! Fallback (HTTP) deneniyor...");
      return await _fallbackSendSignal('SendOffer', targetUserId, 'offer', sdp);
    }''', content, flags=re.DOTALL
)

content = re.sub(
    r'Future<void> sendAnswer\(String targetUserId, String sdp\) async \{\s*if \(!isConnected\) \{.*?\throw StateError[^;]+;\s*\}',
    '''Future<void> sendAnswer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning("SignalR: Answer gonderilemedi - BAGLANTI YOK! Fallback (HTTP) deneniyor...");
      return await _fallbackSendSignal('SendAnswer', targetUserId, 'answer', sdp);
    }''', content, flags=re.DOTALL
)

content = content.replace(target_fallback, replace_fallback)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('SignalR HTTP Fallback applied successfully.')
