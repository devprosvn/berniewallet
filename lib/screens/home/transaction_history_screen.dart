import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/repositories/wallet_repository.dart';
import 'package:bernie_wallet/widgets/shared/loading_indicator.dart';
import 'package:bernie_wallet/widgets/wallet/transaction_list_item.dart';
import 'package:bernie_wallet/config/constants.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String address;

  const TransactionHistoryScreen({Key? key, required this.address})
      : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final walletRepository = context.read<WalletRepository>();
      // final isTestnet = context.read<WalletBloc>().state.isTestnet; // Not needed for this call

      final transactions = await walletRepository.getTransactionHistory(
          widget.address
          // isTestnet: isTestnet // This parameter does not exist on the repository method
          );
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load transaction history: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchTransactions,
            tooltip: 'Refresh Transactions',
          )
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading transactions...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: kErrorColor)),
              const SizedBox(height: kDefaultPadding),
              ElevatedButton(
                onPressed: _fetchTransactions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Text('No transactions found for this address.'),
      );
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return TransactionListItem(
          transaction: transaction,
          currentWalletAddress: widget.address, // Corrected parameter name
        );
      },
    );
  }
}
