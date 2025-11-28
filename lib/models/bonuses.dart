class Bonuses {
  final double amount;
  final double bonusAmount;

  Bonuses({required this.amount, required this.bonusAmount});

  factory Bonuses.fromJson(Map<String, dynamic> json) {
    return Bonuses(amount: json['amount'], bonusAmount: json['bonus_amount']);
  }
}
