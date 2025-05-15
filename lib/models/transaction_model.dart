// models/transaction_model.dart - Transaction data model

import 'package:equatable/equatable.dart';
import 'dart:convert'; // For potential note decoding

enum TransactionType { payment, assetTransfer, appCall, unknown }

class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final String sender;
  final String receiver;
  final double amount; // In Algos for payment transactions, units for ASA
  final double fee; // In Algos
  final DateTime dateTime;
  final String? note;
  final int roundTime; // Block round time
  final String? assetId; // For asset transfers
  final Map<String, dynamic>?
      rawJson; // To store the original JSON for more details

  const TransactionModel({
    required this.id,
    required this.type,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.fee,
    required this.dateTime,
    this.note,
    required this.roundTime,
    this.assetId,
    this.rawJson, // Added rawJson
  });

  // Helper to determine if the transaction is outgoing or incoming for a given address
  bool isOutgoing(String currentAddress) {
    return sender == currentAddress;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        sender,
        receiver,
        amount,
        fee,
        dateTime,
        note,
        roundTime,
        assetId,
        rawJson, // Added rawJson to props
      ];

  // Factory constructor for creating a TransactionModel from a JSON map (e.g., from Algorand API)
  factory TransactionModel.fromJson(
      Map<String, dynamic> json, String currentAddress) {
    TransactionType txType = TransactionType.unknown;
    String actualReceiver = json['payment-transaction']?['receiver'] ?? '';
    double txAmount = 0.0;
    String? txAssetId;
    String? decodedNote;

    final String txTypeString = json['tx-type'] as String? ?? '';

    if (txTypeString == 'pay') {
      txType = TransactionType.payment;
      final paymentTx = json['payment-transaction'] as Map<String, dynamic>?;
      txAmount = ((paymentTx?['amount'] ?? 0) as num).toDouble() / 1000000.0;
      actualReceiver = paymentTx?['receiver'] as String? ?? '';
    } else if (txTypeString == 'axfer') {
      txType = TransactionType.assetTransfer;
      final assetTransferTx =
          json['asset-transfer-transaction'] as Map<String, dynamic>?;
      txAmount = ((assetTransferTx?['amount'] ?? 0) as num).toDouble();
      actualReceiver = assetTransferTx?['receiver'] as String? ?? '';
      txAssetId = (assetTransferTx?['asset-id'] as num?)?.toString();
    } else if (txTypeString == 'appl') {
      txType = TransactionType.appCall;
      // For app calls, amount and receiver might not be directly applicable in the same way.
      // The application-transaction field would have more details like app ID.
      final appTx = json['application-transaction'] as Map<String, dynamic>?;
      actualReceiver = (appTx?['application-id'] as num?)?.toString() ??
          'App Call'; // Often receiver is empty, app-id is key.
    }

    if (json['note'] != null) {
      try {
        // Attempt to decode from base64, then UTF-8
        final List<int> noteBytes = base64Decode(json['note']);
        decodedNote = utf8.decode(noteBytes, allowMalformed: true);
      } catch (e) {
        // If decoding fails, use the raw note or a placeholder
        decodedNote =
            json['note'] is String ? json['note'] : '[Note decoding error]';
      }
    }

    return TransactionModel(
      id: json['id'] as String? ?? 'N/A',
      type: txType,
      sender: json['sender'] as String? ?? '',
      receiver: actualReceiver,
      amount: txAmount,
      fee: ((json['fee'] ?? 0) as num).toDouble() / 1000000.0,
      dateTime: json['round-time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['round-time'] as int) * 1000)
          : DateTime.now(),
      note: decodedNote,
      roundTime: json['round-time'] as int? ?? 0,
      assetId: txAssetId,
      rawJson: json, // Store the full JSON
    );
  }
}
