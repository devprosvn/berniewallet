// services/algorand_service.dart - Algorand blockchain interaction
import 'dart:convert'; // For UTF-8 encoding

import 'package:algorand_dart/algorand_dart.dart' as algo;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/models/wallet_model.dart';
import 'package:bernie_wallet/services/storage_service.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and Uint8List

class AlgorandService {
  late algo.Algorand _algorand;
  bool _isTestnet = true; // Default to testnet
  final StorageService _storageService; // To persist network preference

  // Constructor
  AlgorandService(this._storageService) {
    _initializeAlgorand();
  }

  Future<void> _initializeAlgorand() async {
    final isTestnet = await _storageService.isTestnet();
    _isTestnet = isTestnet;
    _algorand = algo.Algorand(
      algodClient: algo.AlgodClient(
        apiUrl: _isTestnet ? kAlgodTestnetUrl : kAlgodMainnetUrl,
        apiKey: _isTestnet ? kAlgodTestnetToken : kAlgodMainnetToken,
      ),
      indexerClient: algo.IndexerClient(
        apiUrl: _isTestnet ? kIndexerTestnetUrl : kIndexerMainnetUrl,
        apiKey: _isTestnet
            ? kAlgodTestnetToken
            : kAlgodMainnetToken, // Usually the same token
      ),
    );
  }

  Future<void> toggleNetwork() async {
    _isTestnet = !_isTestnet;
    await _storageService.setTestnet(_isTestnet);
    await _initializeAlgorand(); // Re-initialize with new network settings
    if (kDebugMode) {
      print('Switched to ${_isTestnet ? "TestNet" : "MainNet"}');
    }
  }

  bool isTestnet() => _isTestnet;

  Future<WalletModel> createAccount() async {
    // Create a new account - this is an instance method on Algorand, not static
    final account = await algo.Account.random(); // account is algo.Account
    if (kDebugMode) {
      // Assuming account.publicAddress is directly the string representation
      print('Account created: ${account.publicAddress}');
      final seedPhrase = await account.seedPhrase;
      print('Mnemonic: ${seedPhrase.join(' ')}');
    }

    // Get the seedphrase to store in the WalletModel
    final seedPhrase = await account.seedPhrase;
    return WalletModel(
      // Assuming account.publicAddress is directly the string representation
      address: account.publicAddress,
      mnemonic: seedPhrase.join(' '),
      balance: 0.0,
    );
  }

  Future<WalletModel> importAccount(String mnemonic) async {
    try {
      // Create account from mnemonic
      final account = await algo.Account.fromSeedPhrase(
          mnemonic.split(' ')); // account is algo.Account
      if (kDebugMode) {
        // Assuming account.publicAddress is directly the string representation
        print('Account imported: ${account.publicAddress}');
      }
      // Assuming account.publicAddress is directly the string representation
      final balance = await getAccountBalance(account.publicAddress);
      return WalletModel(
        // Assuming account.publicAddress is directly the string representation
        address: account.publicAddress,
        mnemonic: mnemonic,
        balance: balance,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error importing account: $e');
      }
      rethrow;
    }
  }

  void clearCurrentAccount() {
    // This method is now a no-op since we don't store the account locally anymore
    // It's kept for backward compatibility with the repository layer
  }

  bool isValidMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(' ');
    if (words.length != 25) return false;
    return bip39.validateMnemonic(mnemonic.trim());
  }

  Future<double> getAccountBalance(String address) async {
    try {
      final accountInfo = await _algorand.getAccountByAddress(address);
      return accountInfo.amount / 1000000.0; // Convert microAlgos to Algos
    } catch (e) {
      // Attempt to identify "Account Not Found" errors via message string matching
      // This is less robust than a status code but a common fallback.
      String errorMessage = '';
      if (e is algo.AlgorandException) {
        errorMessage = e.message.toLowerCase();
      } else {
        errorMessage = e.toString().toLowerCase();
      }

      if (errorMessage.contains('account not found') ||
              errorMessage.contains('no accounts found for address') ||
              errorMessage
                  .contains('no such account') || // Common alternative phrasing
              errorMessage
                  .contains('404') // Sometimes status code is in message string
          ) {
        return 0.0; // Account not found, so balance is 0
      }

      // Log the actual error message if in debug mode for further diagnosis
      if (kDebugMode) {
        print(
            'Error in getAccountBalance for address $address: $e (Type: ${e.runtimeType})');
        if (e is algo.AlgorandException) {
          print('AlgorandException message: ${e.message}');
        }
      }

      // Rethrow a new exception that includes the original error string for clarity in logs/UI
      throw Exception(
          'Failed to fetch account balance. Original error: ${e.toString()}');
    }
  }

  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    try {
      final response = await _algorand
          .indexer()
          .transactions()
          .whereAddress(algo.Address.fromAlgorandAddress(address: address))
          .search(limit: 20); // Limiting to 20 for now

      return response.transactions
          .map((tx) => _createTransactionModel(tx, address))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching transaction history for $address: $e');
      }
      return [];
    }
  }

  TransactionModel _createTransactionModel(dynamic rawTx, String address) {
    // Implement mapping from rawTx to TransactionModel
    // This is a placeholder for the fromRawTransaction functionality
    // Adapt this based on your TransactionModel structure
    return TransactionModel(
      id: rawTx.id,
      type: _determineTransactionType(rawTx),
      sender: rawTx.sender,
      receiver: _getReceiverAddress(rawTx),
      amount: _getTransactionAmount(rawTx),
      fee: rawTx.fee / 1000000.0, // Convert to Algos
      dateTime: DateTime.fromMillisecondsSinceEpoch(rawTx.roundTime * 1000),
      note: _decodeNote(rawTx.note),
      roundTime: rawTx.roundTime,
      assetId: _getAssetId(rawTx),
      rawJson: rawTx.toJson(), // Store the raw JSON for more details
    );
  }

  // Helper methods for _createTransactionModel
  TransactionType _determineTransactionType(dynamic tx) {
    final String txType = tx.txType ?? '';
    if (txType == 'pay') return TransactionType.payment;
    if (txType == 'axfer') return TransactionType.assetTransfer;
    if (txType == 'appl') return TransactionType.appCall;
    return TransactionType.unknown;
  }

  String _getReceiverAddress(dynamic tx) {
    if (tx.txType == 'pay' && tx.paymentTransaction != null) {
      return tx.paymentTransaction.receiver ?? '';
    } else if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      return tx.assetTransferTransaction.receiver ?? '';
    }
    return '';
  }

  double _getTransactionAmount(dynamic tx) {
    if (tx.txType == 'pay' && tx.paymentTransaction != null) {
      return tx.paymentTransaction.amount / 1000000.0; // Convert to Algos
    } else if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      return tx.assetTransferTransaction.amount.toDouble();
    }
    return 0.0;
  }

  String? _getAssetId(dynamic tx) {
    if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      final assetId = tx.assetTransferTransaction.assetId;
      return assetId?.toString();
    }
    return null;
  }

  String? _decodeNote(dynamic note) {
    if (note == null) return null;
    try {
      if (note is List<int>) {
        return utf8.decode(note, allowMalformed: true);
      } else if (note is String) {
        return note;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding note: $e');
      }
    }
    return '[Note decoding error]';
  }

  Future<String?> sendPayment({
    required String senderMnemonic,
    required String recipientAddress,
    required int amount,
    String? note,
  }) async {
    try {
      // Convert the mnemonic to an account
      final account =
          await algo.Account.fromSeedPhrase(senderMnemonic.split(' '));

      // Lấy thông tin tài khoản để kiểm tra số dư
      final accountInfo =
          await _algorand.getAccountByAddress(account.publicAddress);
      const minFee = 1000; // Phí giao dịch tối thiểu trên Algorand (microAlgos)

      // Kiểm tra xem số dư có đủ cho cả số tiền và phí giao dịch không
      if (accountInfo.amount < (amount + minFee)) {
        throw Exception(
            'Số dư không đủ để thực hiện giao dịch này. Cần ít nhất ${(amount + minFee) / 1000000} ALGO (bao gồm phí).');
      }

      // Lấy tham số giao dịch được đề xuất
      final params = await _algorand.getSuggestedTransactionParams();

      // Xây dựng giao dịch thanh toán với chuyển đổi ghi chú phù hợp
      final transaction = await (algo.PaymentTransactionBuilder()
            ..sender = account.address
            ..receiver =
                algo.Address.fromAlgorandAddress(address: recipientAddress)
            ..amount = amount
            ..note = note != null ? Uint8List.fromList(utf8.encode(note)) : null
            ..suggestedParams = params)
          .build();

      // Ký và gửi giao dịch
      final signedTransaction = await transaction.sign(account);
      final txId = await _algorand.sendTransaction(signedTransaction);

      // Xác minh chúng ta nhận được ID giao dịch hợp lệ
      if (txId.isEmpty) {
        throw Exception(
            'Giao dịch đã được gửi nhưng không có ID giao dịch được trả về');
      }

      if (kDebugMode) {
        print('Giao dịch đã gửi thành công: $txId');
      }
      return txId;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi gửi thanh toán: ${e.toString()}');
      }

      // Xử lý chi tiết cho AlgorandException
      if (e is algo.AlgorandException) {
        // Trích xuất và trả về thông báo lỗi chi tiết từ Algorand API
        final errorMessage = e.message;

        String detailedError = 'Lỗi Algorand: $errorMessage';

        // Xử lý các mã lỗi hoặc thông báo lỗi cụ thể
        if (errorMessage.toLowerCase().contains('overspend') ||
            errorMessage.toLowerCase().contains('insufficient funds')) {
          detailedError =
              'Số dư không đủ để thực hiện giao dịch này. Vui lòng kiểm tra số dư và phí giao dịch.';
        } else if (errorMessage.toLowerCase().contains('below min')) {
          detailedError =
              'Số tiền giao dịch thấp hơn số tiền tối thiểu cho phép.';
        } else if (errorMessage.toLowerCase().contains('rejected')) {
          detailedError =
              'Giao dịch bị từ chối bởi mạng Algorand. Vui lòng thử lại sau.';
        } else if (errorMessage.toLowerCase().contains('timeout')) {
          detailedError =
              'Hết thời gian kết nối đến mạng Algorand. Vui lòng kiểm tra kết nối mạng và thử lại.';
        } else if (errorMessage.toLowerCase().contains('params')) {
          detailedError =
              'Tham số giao dịch không hợp lệ. Vui lòng thử lại sau.';
        }

        throw Exception(detailedError);
      }

      // Ném lại với thông báo mô tả rõ ràng hơn
      throw Exception('Không thể gửi giao dịch: ${e.toString()}');
    }
  }

  Future<String> getExplorerUrl(String type, String id) async {
    final baseUrl = _isTestnet ? kTestNetExplorerUrl : kMainNetExplorerUrl;
    if (type == 'transaction') {
      return '$baseUrl/tx/$id';
    } else if (type == 'address') {
      return '$baseUrl/address/$id';
    }
    return baseUrl;
  }
}
