class Profile {
  final String name;
  final String lastName;
  final String login;
  final String email;
  final String? phone;
  final String? avatar;
  final String amount;
  final String? bonusAmount;
  final bool isConfirmed;

  Profile({
    required this.name,
    required this.lastName,
    required this.login,
    required this.email,
    this.phone,
    this.avatar,
    required this.amount,
    this.bonusAmount,
    this.isConfirmed = false,
  });

  factory Profile.fromJson(Map<String, dynamic> j) {
    return Profile(
      name: j['name'] ?? '',
      lastName: j['last_name'] ?? '',
      login: j['login'] ?? '',
      email: j['email'] ?? '',
      phone: j['phone'],
      avatar: j['avatar'],
      amount: j['amount'],
      bonusAmount: j['bonus_amount'],
      isConfirmed: j['is_confirmed'] ?? false,
    );
  }
}
