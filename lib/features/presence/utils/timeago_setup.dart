import 'package:timeago/timeago.dart' as timeago;

/// Uygulama başlangıcında bir kez çağrılmalı.
void setupTimeagoLocales() {
  timeago.setLocaleMessages('tr', timeago.TrMessages());
}
