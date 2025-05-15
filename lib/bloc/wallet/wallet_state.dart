// bloc/wallet/wallet_state.dart - Wallet BLoC States

part of 'wallet_bloc.dart';

enum WalletStatus {
  initial,
  loading,
  created,
  imported,
  ready,
  error,
  pinProtected,
  pinVerified,
  transactionSent
}

abstract class WalletState extends Equatable {
  final WalletStatus status;
  final WalletModel? wallet;
  final String? errorMessage;
  final bool isTestnet; // To track current network
  final bool isPinSet; // To track if a PIN is currently set
  final List<TransactionModel> transactions; // Add transaction list

  const WalletState({
    required this.status,
    this.wallet,
    this.errorMessage,
    this.isTestnet = false, // Default to Mainnet
    this.isPinSet = false, // Default to false
    this.transactions = const [], // Default to empty list
  });

  @override
  List<Object?> get props =>
      [status, wallet, errorMessage, isTestnet, isPinSet, transactions];

  WalletState copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  });
}

class WalletInitial extends WalletState {
  const WalletInitial({bool isTestnet = false, bool isPinSet = false})
      : super(
            status: WalletStatus.initial,
            isTestnet: isTestnet,
            isPinSet: isPinSet);

  @override
  WalletInitial copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    // Initial state typically doesn't change dynamically for isPinSet here,
    // but WalletBloc will decide the initial isPinSet value upon loading.
    return WalletInitial(
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
    );
  }
}

class WalletLoading extends WalletState {
  const WalletLoading(
      {required bool currentIsTestnet, required bool currentIsPinSet})
      : super(
            status: WalletStatus.loading,
            isTestnet: currentIsTestnet,
            isPinSet: currentIsPinSet);

  @override
  WalletLoading copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletLoading(
      currentIsTestnet: isTestnet ?? this.isTestnet,
      currentIsPinSet: isPinSet ?? this.isPinSet,
    );
  }
}

class WalletCreated extends WalletState {
  const WalletCreated(
      {required WalletModel wallet,
      required bool isTestnet,
      required bool isPinSet})
      : super(
            status: WalletStatus.created,
            wallet: wallet,
            isTestnet: isTestnet,
            isPinSet: isPinSet);

  @override
  WalletCreated copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletCreated(
      wallet: wallet ?? this.wallet!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
    );
  }
}

class WalletImported extends WalletState {
  const WalletImported(
      {required WalletModel wallet,
      required bool isTestnet,
      required bool isPinSet})
      : super(
            status: WalletStatus.imported,
            wallet: wallet,
            isTestnet: isTestnet,
            isPinSet: isPinSet);

  @override
  WalletImported copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletImported(
      wallet: wallet ?? this.wallet!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
    );
  }
}

class WalletReady extends WalletState {
  const WalletReady({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
            status: WalletStatus.ready,
            wallet: wallet,
            isTestnet: isTestnet,
            isPinSet: isPinSet,
            transactions: transactions);

  @override
  WalletReady copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletReady(
      wallet: wallet ?? this.wallet!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletError extends WalletState {
  const WalletError(
      {required String errorMessage,
      required bool isTestnet,
      required bool isPinSet})
      : super(
            status: WalletStatus.error,
            errorMessage: errorMessage,
            isTestnet: isTestnet,
            isPinSet: isPinSet);

  @override
  WalletError copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletError(
      errorMessage: errorMessage ?? this.errorMessage!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
    );
  }
}

// States for PIN functionality if you want to reflect it in WalletState
// Alternatively, PIN logic can be handled by a separate AuthBloc or within screens

class WalletRequiresPin extends WalletState {
  const WalletRequiresPin({
    required bool isTestnet,
    WalletModel? wallet,
    String? errorMessage,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
            status: WalletStatus.pinProtected,
            isTestnet: isTestnet,
            wallet: wallet,
            errorMessage: errorMessage,
            isPinSet: isPinSet, // isPinSet should be true here
            transactions: transactions);

  @override
  WalletRequiresPin copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletRequiresPin(
      isTestnet: isTestnet ?? this.isTestnet,
      wallet: wallet ?? this.wallet,
      errorMessage: errorMessage ?? this.errorMessage,
      isPinSet: isPinSet ?? this.isPinSet,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletPinVerified extends WalletState {
  const WalletPinVerified({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.pinVerified,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          transactions: transactions,
        );

  @override
  WalletPinVerified copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletPinVerified(
      wallet: wallet ?? this.wallet!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
      transactions: transactions ?? this.transactions,
    );
  }
}

// Add state for transaction sent
class WalletTransactionSent extends WalletState {
  const WalletTransactionSent({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.transactionSent,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          transactions: transactions,
        );

  @override
  WalletTransactionSent copyWith({
    WalletStatus? status,
    WalletModel? wallet,
    String? errorMessage,
    bool? isTestnet,
    bool? isPinSet,
    List<TransactionModel>? transactions,
  }) {
    return WalletTransactionSent(
      wallet: wallet ?? this.wallet!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
      transactions: transactions ?? this.transactions,
    );
  }
}
