class ConfirmRegisterRequestDto {
  final String email;
  final String code;

  ConfirmRegisterRequestDto({required this.email, required this.code});

  Map<String, dynamic> toJson() => {'email': email, 'code': code};
}
