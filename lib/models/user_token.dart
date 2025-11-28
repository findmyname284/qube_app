class UserToken {
  final String accessToken;
  final String refreshToken;

  UserToken({required this.accessToken, required this.refreshToken});

  factory UserToken.fromJson(Map<String, dynamic> j) {
    return UserToken(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String,
    );
  }
}
