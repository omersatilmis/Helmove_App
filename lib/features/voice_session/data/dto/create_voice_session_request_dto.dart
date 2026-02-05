class CreateVoiceSessionRequestDto {
  final String? title;
  final String? roomName;
  final List<int>? inviteUserIds;

  CreateVoiceSessionRequestDto({this.title, this.roomName, this.inviteUserIds});

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'roomName': roomName,
      'inviteUserIds': inviteUserIds,
    };
  }
}
