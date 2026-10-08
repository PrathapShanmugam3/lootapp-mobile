class WalletSummary {
  const WalletSummary({required this.balance, required this.totalEarned, required this.totalWithdrawn});

  final double balance;
  final double totalEarned;
  final double totalWithdrawn;

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
        totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0,
      );
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.comment,
    required this.status,
    this.date,
    this.time,
    this.trxId,
  });

  final int id;
  final String type;
  final double amount;
  final String? comment;
  final String status;
  final String? date;
  final String? time;
  final String? trxId;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: json['id'] as int,
        type: json['type']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        comment: json['comment']?.toString(),
        status: json['status']?.toString() ?? '',
        date: json['date']?.toString(),
        time: json['time']?.toString(),
        trxId: json['trxId']?.toString(),
      );
}
