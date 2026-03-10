import 'package:flutter/material.dart';

/// Backend'deki 'FeedbackCategory' enum'ı ile tam uyumlu
enum FeedbackCategory {
  general(0, 'Genel', Icons.feedback, Colors.blue),
  bugReport(1, 'Hata Bildirimi', Icons.bug_report, Colors.red),
  featureRequest(2, 'Özellik İsteği', Icons.add_chart, Colors.green),
  uiImprovement(3, 'Arayüz Geliştirme', Icons.palette, Colors.purple),
  performance(4, 'Performans', Icons.speed, Colors.orange),
  security(5, 'Güvenlik', Icons.security, Colors.teal),
  other(6, 'Diğer', Icons.help_outline, Colors.grey);

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const FeedbackCategory(this.value, this.label, this.icon, this.color);

  static FeedbackCategory fromValue(int value) =>
      values.firstWhere((e) => e.value == value, orElse: () => FeedbackCategory.other);
}

/// Geri bildirimin takip durumu
enum FeedbackStatus {
  newStatus(0, 'Yeni', Icons.new_releases, Colors.blue),
  read(1, 'Okundu', Icons.mark_email_read, Colors.grey),
  inProgress(2, 'İşlemde', Icons.pending, Colors.orange),
  completed(3, 'Tamamlandı', Icons.task_alt, Colors.green),
  wontFix(4, 'Yapılmayacak', Icons.do_not_disturb_on, Colors.red);

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const FeedbackStatus(this.value, this.label, this.icon, this.color);

  static FeedbackStatus fromValue(int value) =>
      values.firstWhere((e) => e.value == value, orElse: () => FeedbackStatus.newStatus);
}
