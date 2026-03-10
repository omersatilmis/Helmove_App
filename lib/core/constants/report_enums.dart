import 'package:flutter/material.dart';

/// Backend'deki 'ReportCategory' enum'ı ile tam uyumlu
enum ReportCategory {
  spam(0, 'Spam / Gereksiz', Icons.block, Colors.orange),
  harassment(1, 'Taciz', Icons.gavel, Colors.red),
  inappropriateContent(2, 'Uygunsuz İçerik', Icons.visibility_off, Colors.deepOrange),
  fakeAccount(3, 'Sahte Hesap', Icons.person_off, Colors.blueGrey),
  violence(4, 'Şiddet / Tehdit', Icons.warning, Colors.redAccent),
  hateSpeech(5, 'Nefret Söylemi', Icons.campaign, Colors.deepPurple),
  scam(6, 'Dolandırıcılık', Icons.account_balance_wallet, Colors.teal),
  copyrightViolation(7, 'Telif Hakkı İhlali', Icons.copyright, Colors.brown),
  other(8, 'Diğer', Icons.more_horiz, Colors.grey);

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const ReportCategory(this.value, this.label, this.icon, this.color);

  static ReportCategory fromValue(int value) =>
      values.firstWhere((e) => e.value == value, orElse: () => ReportCategory.other);
}

/// Backend'deki 'ReportStatus' enum'ı ile tam uyumlu
enum ReportStatus {
  pending(0, 'Beklemede', Icons.hourglass_empty, Colors.orange),
  underReview(1, 'İncelemede', Icons.search, Colors.blue),
  resolved(2, 'Çözüldü', Icons.check_circle, Colors.green),
  rejected(3, 'Reddedildi', Icons.cancel, Colors.red),
  actionTaken(4, 'İşlem Yapıldı', Icons.settings_suggest, Colors.indigo);

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const ReportStatus(this.value, this.label, this.icon, this.color);

  static ReportStatus fromValue(int value) =>
      values.firstWhere((e) => e.value == value, orElse: () => ReportStatus.pending);
}

/// Raporun hangi hedefe yapıldığını belirler
enum ReportTargetType {
  user(0, 'Kullanıcı', Icons.person),
  content(1, 'İçerik', Icons.article),
  comment(2, 'Yorum', Icons.comment),
  groupRide(3, 'Grup Sürüşü', Icons.motorcycle),
  message(4, 'Mesaj', Icons.message);

  final int value;
  final String label;
  final IconData icon;

  const ReportTargetType(this.value, this.label, this.icon);

  static ReportTargetType fromValue(int value) =>
      values.firstWhere((e) => e.value == value, orElse: () => ReportTargetType.content);
}
