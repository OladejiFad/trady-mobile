class Transaction {
  final String id;
  final String buyerId;
  final String propertyId;
  final double amount;
  final String status;
  final DateTime transactionDate;
  final String? paymentMethod;

  Transaction({
    required this.id,
    required this.buyerId,
    required this.propertyId,
    required this.amount,
    required this.status,
    required this.transactionDate,
    this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'],
      buyerId: json['buyer'],
      propertyId: json['property'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      transactionDate: DateTime.parse(json['transactionDate']),
      paymentMethod: json['paymentMethod'],
    );
  }
}
