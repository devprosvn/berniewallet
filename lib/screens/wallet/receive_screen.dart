import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive ALGO'),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.wallet == null) {
            return const Center(
              child: Text('Wallet not available.'),
            );
          }

          final address = state.wallet!.address;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(kMediumPadding),
                    child: Column(
                      children: [
                        Text(
                          'Your ${state.isTestnet ? 'TestNet' : 'MainNet'} Address',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: kDefaultPadding),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(kMediumPadding),
                          child: QrImageView(
                            data: address,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: kDefaultPadding),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kMediumPadding,
                            vertical: kSmallPadding,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(kDefaultRadius),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  address,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Address copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Copy to clipboard',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
                  child: Text(
                    'Send only Algorand (ALGO) or Algorand Standard Assets (ASA) to this address. Sending any other cryptocurrency may result in permanent loss.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kWarningColor),
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                AppButton(
                  text: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
