class Profile {
  final String name;
  final String surname;
  final String username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int? balance;
  final int? discount;

  Profile({
    required this.name,
    required this.surname,
    required this.username,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.balance,
    this.discount,
  });

  factory Profile.fromJson(Map<String, dynamic> j) {
    return Profile(
      name: j['name'] ?? '',
      surname: j['surname'] ?? '',
      username: j['username'] ?? '',
      email: j['email'] ?? '',
      phone: j['phone'],
      avatarUrl: j['avatarUrl'],
      balance: j['balance'],
      discount: j['discount'],
    );
  }
}
