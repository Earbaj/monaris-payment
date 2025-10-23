class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String? ticket;
  final Map<String, dynamic>? responseData;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.ticket,
    this.responseData,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      transactionId: json['transaction_id'],
      ticket: json['ticket'],
      responseData: json['response_data'],
    );
  }
}