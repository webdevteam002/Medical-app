class PaymentInstructionsModel {
  final List<String> methods;
  final String jazzcashNumber;
  final String easypaisaNumber;
  final String bankDetails;
  final String whatsappNumber;
  final String instructions;

  const PaymentInstructionsModel({
    required this.methods,
    required this.jazzcashNumber,
    required this.easypaisaNumber,
    required this.bankDetails,
    required this.whatsappNumber,
    required this.instructions,
  });

  factory PaymentInstructionsModel.fromJson(Map<String, dynamic> json) {
    final methodsRaw = json['methods'];
    return PaymentInstructionsModel(
      methods: methodsRaw is List
          ? methodsRaw.map((e) => e.toString()).toList()
          : const ['jazzcash', 'easypaisa', 'bank'],
      jazzcashNumber: json['jazzcashNumber'] as String? ?? '',
      easypaisaNumber: json['easypaisaNumber'] as String? ?? '',
      bankDetails: json['bankDetails'] as String? ?? '',
      whatsappNumber: json['whatsappNumber'] as String? ?? '',
      instructions: json['instructions'] as String? ??
          'Send payment then WhatsApp screenshot. Access activated within 24 hours.',
    );
  }
}

class ManualPaymentIntentResult {
  final String subscriptionId;
  final String planType;
  final String status;
  final PaymentInstructionsModel instructions;

  const ManualPaymentIntentResult({
    required this.subscriptionId,
    required this.planType,
    required this.status,
    required this.instructions,
  });

  factory ManualPaymentIntentResult.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>? ?? {};
    final plan = sub['plan'] as Map<String, dynamic>? ?? {};
    final instructionsRaw = json['instructions'] as Map<String, dynamic>? ?? {};

    return ManualPaymentIntentResult(
      subscriptionId: sub['id'] as String? ?? '',
      planType: plan['planType'] as String? ?? '',
      status: sub['status'] as String? ?? 'PENDING',
      instructions: PaymentInstructionsModel.fromJson(instructionsRaw),
    );
  }
}
