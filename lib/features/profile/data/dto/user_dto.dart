class UserDto {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  // Backend'den okuma
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'].toString(), // Int gelirse String'e çevirsin diye
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  // Gerekirse güncelleme için gönderme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}
