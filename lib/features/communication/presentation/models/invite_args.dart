import '../../../../core/navigation/base_navigation_args.dart';

class InviteArgs extends BaseNavigationArgs {
  final int sessionId;
  final bool isFromCreateGroup;
  final Map<String, dynamic>? groupData;

  const InviteArgs({
    required this.sessionId,
    this.isFromCreateGroup = false,
    this.groupData,
  });

  factory InviteArgs.empty() {
    return const InviteArgs(sessionId: 0);
  }

  @override
  bool get isValid => sessionId > 0 || (isFromCreateGroup && groupData != null);

  @override
  String? get errorMessage => isValid ? null : 'Geçersiz Davet Bilgisi';

  static InviteArgs? fromExtra(Object? extra) {
    if (extra is InviteArgs) return extra;
    if (extra is Map<String, dynamic>) {
      return InviteArgs(
        sessionId: extra['sessionId'] ?? 0,
        isFromCreateGroup: extra['isFromCreateGroup'] ?? false,
        groupData: extra['groupData'] ?? extra,
      );
    }
    if (extra is int) {
      return InviteArgs(sessionId: extra);
    }
    return null;
  }
}
