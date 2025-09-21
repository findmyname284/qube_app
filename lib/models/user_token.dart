class UserToken {
  final String token;

  UserToken({required this.token});

  factory UserToken.fromJson(Map<String, dynamic> j) {
    return UserToken(token: j['token'] as String);
  }
}
