class HelpEndpoints {
  static const String prefix = '/api';

  /// Rapor gönderimi için POST endpoint'i
  static const String reports = '$prefix/Report';

  /// Geri bildirim gönderimi için POST endpoint'i
  static const String feedback = '$prefix/Feedback';

  /// (Opsiyonel) Kullanıcının kendi raporlarını görmesi için GET endpoint'i
  static const String userReports = '$prefix/Report/user';

  /// (Opsiyonel) Kullanıcının kendi geri bildirimlerini görmesi için GET endpoint'i
  static const String userFeedback = '$prefix/Feedback/user';
}
