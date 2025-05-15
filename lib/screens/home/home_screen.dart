// screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/models/wallet_model.dart';
import 'package:bernie_wallet/widgets/shared/loading_indicator.dart';
import 'package:bernie_wallet/widgets/wallet/address_card.dart';
import 'package:bernie_wallet/widgets/wallet/balance_card.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart'; // For potential actions
import 'package:bernie_wallet/screens/home/transaction_history_screen.dart'; // Uncommented
import 'package:bernie_wallet/widgets/wallet/transaction_list_item.dart';
import 'package:bernie_wallet/models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pinController = TextEditingController();
  bool _isPinDialogShowing =
      false; // Flag to avoid showing multiple PIN dialogs

  @override
  void initState() {
    super.initState();

    // Ensure PIN dialog appears on initial load if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<WalletBloc>().state;
        if (state.status == WalletStatus.pinProtected &&
            state.wallet != null &&
            !_isPinDialogShowing) {
          _showPinDialog(context, state.wallet!, state.errorMessage);
        }
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showPinDialog(
      BuildContext context, WalletModel wallet, String? initialErrorMessage) {
    if (_isPinDialogShowing) return; // Prevent showing multiple PIN dialogs
    setState(() => _isPinDialogShowing = true);

    _pinController.clear();
    String? displayError = initialErrorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (stfContext, setStateDialog) {
          // Use a local variable to track state changes without Provider
          // instead of watching context continuously
          final currentBlocState = context.read<WalletBloc>().state;

          // Update display error if needed
          if (currentBlocState is WalletRequiresPin &&
              currentBlocState.wallet?.address == wallet.address &&
              currentBlocState.errorMessage != null) {
            displayError = currentBlocState.errorMessage;
          } else if (currentBlocState.status != WalletStatus.pinProtected) {
            displayError =
                null; // Clear error if state is no longer pinProtected
          }

          return AlertDialog(
            title: const Text('Enter PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please enter your PIN to unlock the wallet.'),
                const SizedBox(height: kDefaultPadding),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  autofocus: true, // Good for PIN dialogs
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    errorText: displayError,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Unlock'),
                onPressed: () {
                  final enteredPin = _pinController.text;
                  if (enteredPin.isNotEmpty) {
                    // Use read for event handlers, not watch
                    context.read<WalletBloc>().add(VerifyPin(pin: enteredPin));
                    // PIN attempt submitted, BLoC will update state.
                  } else {
                    setStateDialog(() => displayError = 'PIN cannot be empty');
                  }
                },
              ),
            ],
          );
        });
      },
    ).then((_) {
      setState(() =>
          _isPinDialogShowing = false); // Reset flag when dialog is dismissed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppName),
        actions: [
          // Network Toggle
          BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(state.isTestnet
                    ? Icons.public_off_outlined
                    : Icons.public_outlined),
                tooltip:
                    state.isTestnet ? 'Switch to MainNet' : 'Switch to TestNet',
                onPressed: () {
                  context.read<WalletBloc>().add(const ToggleNetwork());
                },
              );
            },
          ),
          // Settings/More Options Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_wallet') {
                _showClearWalletConfirmation(context);
              } else if (value == 'set_pin') {
                _showSetPinDialog(context);
              } else if (value == 'clear_pin') {
                context.read<WalletBloc>().add(const ClearPin());
              }
            },
            itemBuilder: (BuildContext context) {
              // Use read instead of watch to avoid provider errors in event handlers
              final state = context.read<WalletBloc>().state;
              // Use the isPinSet field from WalletState directly
              final bool canClearPin = state.isPinSet;

              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'set_pin',
                  child: Text('Set/Change PIN'),
                ),
                PopupMenuItem<String>(
                  value: 'clear_pin',
                  enabled: canClearPin, // Use the direct state field
                  child: const Text('Clear PIN'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'clear_wallet',
                  child: Text('Clear Wallet Data',
                      style: TextStyle(color: kErrorColor)),
                ),
              ];
            },
          ),
        ],
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          // Manage PIN Dialog
          if (state.status == WalletStatus.pinProtected &&
              state.wallet != null) {
            // If PIN protection is active but dialog isn't showing, schedule it for next frame
            // This is now managed by the builder part as well for redundancy
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                // Don't need isDialogAlreadyOpen check as we're providing an explicit button now
                if (state.errorMessage?.contains('Invalid PIN') == true) {
                  // Show error snackbar for invalid PIN
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid PIN: ${state.errorMessage}'),
                      backgroundColor: kErrorColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            });
          } else if (state.status == WalletStatus.pinVerified) {
            // When PIN is verified, dismiss any PIN dialog that might be open
            if (Navigator.of(context).canPop()) {
              ModalRoute<dynamic>? currentRoute = ModalRoute.of(context);
              if (currentRoute is DialogRoute) {
                Navigator.of(context).pop();
              }
            }

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallet unlocked successfully'),
                backgroundColor: kSuccessColor,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state.status == WalletStatus.initial) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil(kWelcomeRoute, (route) => false);
          } else if (state.status == WalletStatus.error &&
              state.errorMessage != null) {
            if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
              return; // Early return if this context isn't current
            }

            // Only show error snackbar for non-PIN related errors
            bool isPinDialogError =
                state.errorMessage!.toLowerCase().contains('pin');

            if (!isPinDialogError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: kErrorColor));
            }
          }
        },
        builder: (context, state) {
          if (state.status == WalletStatus.loading && state.wallet == null) {
            return const LoadingIndicator(message: 'Loading wallet...');
          }

          if (state.status == WalletStatus.pinProtected &&
              state.wallet != null) {
            // When PIN protected state is detected, trigger the PIN dialog immediately
            // and show a different UI with PIN field directly in the screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                _showPinDialog(context, state.wallet!, state.errorMessage);
              }
            });

            // Enhanced PIN UI directly in the screen
            return Padding(
              padding: const EdgeInsets.all(kDefaultPadding * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 48, color: kPrimaryColor),
                  const SizedBox(height: kDefaultPadding),
                  Text(
                    'Wallet Locked',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kSmallPadding),
                  Text(
                    'Enter your PIN to unlock',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding * 2),
                  AppButton(
                    text: 'Unlock Wallet',
                    onPressed: () {
                      if (!_isPinDialogShowing) {
                        _showPinDialog(
                            context, state.wallet!, state.errorMessage);
                      }
                    },
                  ),
                ],
              ),
            );
          }

          if (state.wallet == null || state.status == WalletStatus.initial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No wallet found or wallet cleared.'),
                  const SizedBox(height: kDefaultPadding),
                  AppButton(
                    text: 'Go to Welcome Screen',
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                            kWelcomeRoute, (route) => false),
                  ),
                ],
              ),
            );
          }

          final wallet = state.wallet!;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(const RefreshBalance());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BalanceCard(
                    balance: wallet.balance,
                    isLoading: state.status == WalletStatus.loading,
                    onRefresh: () {
                      context.read<WalletBloc>().add(const RefreshBalance());
                    },
                    isTestnet: state.isTestnet,
                  ),
                  const SizedBox(height: kMediumPadding),
                  AddressCard(
                    address: wallet.address,
                    truncatedAddress: wallet.truncatedAddress,
                  ),

                  // Add transaction action buttons row
                  const SizedBox(height: kDefaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Send ALGO',
                          onPressed: () {
                            Navigator.of(context).pushNamed(kSendRoute);
                          },
                          color: kPrimaryColor,
                          textColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: kMediumPadding),
                      Expanded(
                        child: AppButton(
                          text: 'Receive ALGO',
                          onPressed: () {
                            Navigator.of(context).pushNamed(kReceiveRoute);
                          },
                          color: kSecondaryColor,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: kDefaultPadding * 1.5),
                  Text(
                    'Recent Activity',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: kSmallPadding),

                  // Recent transactions list
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                    ),
                    child: state.transactions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: kDefaultPadding * 2),
                            child: const Center(
                              child: Text('No transactions yet.'),
                            ),
                          )
                        : Column(
                            children: [
                              ...state.transactions.take(3).map(
                                    (transaction) => TransactionListItem(
                                      transaction: transaction,
                                      currentWalletAddress: wallet.address,
                                    ),
                                  ),
                            ],
                          ),
                  ),

                  const SizedBox(height: kSmallPadding),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'View All Transactions',
                      isOutlined: true,
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                            kTransactionHistoryRoute,
                            arguments: {'address': wallet.address});
                      },
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding * 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showClearWalletConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Wallet Data?'),
        content: const Text(
            'Are you sure you want to delete all wallet data? This action cannot be undone. Ensure you have backed up your recovery phrase!'),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Data'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<WalletBloc>().add(const DeleteWallet());
            },
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog(BuildContext context) {
    final pinSetController = TextEditingController();
    final confirmPinSetController = TextEditingController();
    String? pinDialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (stfDialogCtx, setStateDialog) {
          return AlertDialog(
            title: const Text('Set PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pinSetController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                      labelText: 'New PIN (4-6 digits)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: kMediumPadding),
                TextField(
                  controller: confirmPinSetController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                      labelText: 'Confirm New PIN',
                      border: OutlineInputBorder()),
                ),
                if (pinDialogError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: kSmallPadding),
                    child: Text(pinDialogError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
              ],
            ),
            actions: <Widget>[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Set PIN'),
                onPressed: () {
                  final pin = pinSetController.text;
                  final confirmPin = confirmPinSetController.text;
                  if (pin.length < 4 || pin.length > 6) {
                    setStateDialog(
                        () => pinDialogError = 'PIN must be 4-6 digits.');
                    return;
                  }
                  if (pin != confirmPin) {
                    setStateDialog(() => pinDialogError = 'PINs do not match.');
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  context.read<WalletBloc>().add(SetPin(pin: pin));
                },
              ),
            ],
          );
        });
      },
    ).then((_) {
      pinSetController.dispose();
      confirmPinSetController.dispose();
    });
  }
}
