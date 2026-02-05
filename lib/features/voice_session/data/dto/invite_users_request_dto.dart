class InviteUsersRequestDto {
  final List<int> userIds;

  InviteUsersRequestDto({required this.userIds});

  Map<String, dynamic> toJson() {
    return {'userIds': userIds};
  }
}
