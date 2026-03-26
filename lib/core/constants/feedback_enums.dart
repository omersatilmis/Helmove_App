import 'package:flutter/material.dart';
import 'package:helmove/l10n/app_localizations.dart';

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

extension FeedbackCategoryLocalization on FeedbackCategory {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case FeedbackCategory.general:
        return l10n.feedbackCategoryGeneral;
      case FeedbackCategory.bugReport:
        return l10n.feedbackCategoryBugReport;
      case FeedbackCategory.featureRequest:
        return l10n.feedbackCategoryFeatureRequest;
      case FeedbackCategory.uiImprovement:
        return l10n.feedbackCategoryUiImprovement;
      case FeedbackCategory.performance:
        return l10n.feedbackCategoryPerformance;
      case FeedbackCategory.security:
        return l10n.feedbackCategorySecurity;
      case FeedbackCategory.other:
        return l10n.feedbackCategoryOther;
    }
  }
}

extension FeedbackStatusLocalization on FeedbackStatus {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case FeedbackStatus.newStatus:
        return l10n.feedbackStatusNew;
      case FeedbackStatus.read:
        return l10n.feedbackStatusRead;
      case FeedbackStatus.inProgress:
        return l10n.feedbackStatusInProgress;
      case FeedbackStatus.completed:
        return l10n.feedbackStatusCompleted;
      case FeedbackStatus.wontFix:
        return l10n.feedbackStatusWontFix;
    }
  }
}
