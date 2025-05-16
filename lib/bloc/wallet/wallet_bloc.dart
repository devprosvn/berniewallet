// bloc/wallet/wallet_bloc.dart - Wallet BLoC

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bernie_wallet/models/wallet_model.dart';
import 'package:bernie_wallet/repositories/wallet_repository.dart';
import 'package:bernie_wallet/models/transaction_model.dart'; // Added for TransactionModel
// import 'package:bernie_wallet/services/storage_service.dart'; // Unused import
import 'package:flutter/foundation.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(const WalletInitial(isPinSet: false)) {
    on<LoadWallet>(_onLoadWallet);
    on<CreateWallet>(_onCreateWallet);
    on<ImportWallet>(_onImportWallet);
    on<DeleteWallet>(_onDeleteWallet);
    on<RefreshBalance>(_onRefreshBalance);
    on<SetPin>(_onSetPin);
    on<VerifyPin>(_onVerifyPin);
    on<ClearPin>(_onClearPin);
    on<ToggleNetwork>(_onToggleNetwork);
    on<SendTransaction>(
        _onSendTransaction); // Added handler for SendTransaction
  }

  Future<void> _onLoadWallet(
      LoadWallet event, Emitter<WalletState> emit) async {
    bool currentlyHasPin = false;
    try {
      currentlyHasPin = await _walletRepository.hasPin();
    } catch (_) {
      // If error checking PIN, assume false for safety, or handle error appropriately.
      // This might happen if storage is unavailable.
    }
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: currentlyHasPin));
    try {
      final isTestnet = await _walletRepository.isTestnetActive();
      final wallet = await _walletRepository.loadWallet();
      if (wallet != null) {
        // Fetch initial transactions
        final transactions =
            await _walletRepository.getTransactionHistory(wallet.address);

        final hasPin = await _walletRepository.hasPin();
        if (hasPin) {
          emit(WalletRequiresPin(
            isTestnet: isTestnet,
            wallet: wallet,
            isPinSet: true,
            transactions: transactions,
          ));
        } else {
          emit(WalletReady(
            wallet: wallet,
            isTestnet: isTestnet,
            isPinSet: false,
            transactions: transactions,
          ));
        }
      } else {
        emit(WalletInitial(isTestnet: isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to load wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: currentlyHasPin));
    }
  }

  Future<void> _onCreateWallet(
      CreateWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      final wallet = await _walletRepository.createWallet();
      if (event.pin != null && event.pin!.isNotEmpty) {
        await _walletRepository.setPin(event.pin!);
      }

      final bool actualPinExists = await _walletRepository.hasPin();

      if (actualPinExists) {
        emit(WalletRequiresPin(
            isTestnet: state.isTestnet, wallet: wallet, isPinSet: true));
      } else {
        emit(WalletCreated(
            wallet: wallet, isTestnet: state.isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to create wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onImportWallet(
      ImportWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      final wallet = await _walletRepository.importWallet(event.mnemonic);
      if (event.pin != null && event.pin!.isNotEmpty) {
        await _walletRepository.setPin(event.pin!);
      }

      final bool actualPinExists = await _walletRepository.hasPin();

      if (actualPinExists) {
        emit(WalletRequiresPin(
            isTestnet: state.isTestnet, wallet: wallet, isPinSet: true));
      } else {
        emit(WalletImported(
            wallet: wallet, isTestnet: state.isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to import wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onDeleteWallet(
      DeleteWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      await _walletRepository.deleteWallet();
      await _walletRepository.clearPin();
      emit(WalletInitial(isTestnet: state.isTestnet, isPinSet: false));
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to delete wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onRefreshBalance(
      RefreshBalance event, Emitter<WalletState> emit) async {
    final WalletModel? currentWallet = state.wallet;
    final bool currentIsTestnet = state.isTestnet;
    final bool currentIsPinSet = state.isPinSet;

    if (currentWallet == null) {
      emit(WalletError(
          errorMessage: 'Cannot refresh balance: No wallet loaded.',
          isTestnet: currentIsTestnet,
          isPinSet: currentIsPinSet));
      return;
    }

    emit(WalletLoading(
        currentIsTestnet: currentIsTestnet, currentIsPinSet: currentIsPinSet));

    try {
      final WalletModel refreshedWallet =
          await _walletRepository.refreshBalance(currentWallet);
      final bool appHasPin = await _walletRepository.hasPin();

      // Fetch updated transactions
      final transactions = await _walletRepository
          .getTransactionHistory(refreshedWallet.address);

      if (appHasPin && state.status != WalletStatus.pinVerified) {
        emit(WalletRequiresPin(
          wallet: refreshedWallet,
          isTestnet: currentIsTestnet,
          isPinSet: true,
          transactions: transactions,
        ));
      } else {
        emit(WalletReady(
          wallet: refreshedWallet,
          isTestnet: currentIsTestnet,
          isPinSet: appHasPin,
          transactions: transactions,
        ));
      }
    } catch (e) {
      emit(WalletError(
        errorMessage: 'Failed to refresh balance: ${e.toString()}',
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
    }
  }

  Future<void> _onSetPin(SetPin event, Emitter<WalletState> emit) async {
    final previousWallet = state.wallet;
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      await _walletRepository.setPin(event.pin);
      if (previousWallet != null) {
        emit(WalletReady(
            wallet: previousWallet,
            isTestnet: state.isTestnet,
            isPinSet: true));
      } else {
        emit(WalletInitial(isTestnet: state.isTestnet, isPinSet: true));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to set PIN: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onVerifyPin(VerifyPin event, Emitter<WalletState> emit) async {
    try {
      final isValidPin = await _walletRepository.verifyPin(event.pin);
      if (isValidPin) {
        if (state.wallet != null) {
          emit(WalletPinVerified(
              wallet: state.wallet!,
              isTestnet: state.isTestnet,
              isPinSet: true,
              transactions: state.transactions));
        } else {
          emit(WalletError(
              errorMessage: 'PIN verified but no wallet found.',
              isTestnet: state.isTestnet,
              isPinSet: true));
        }
      } else {
        if (state.wallet != null) {
          emit(WalletRequiresPin(
              isTestnet: state.isTestnet,
              wallet: state.wallet,
              errorMessage: 'Invalid PIN.',
              isPinSet: true,
              transactions: state.transactions));
        } else {
          emit(WalletError(
              errorMessage: 'Invalid PIN and no wallet loaded.',
              isTestnet: state.isTestnet,
              isPinSet: await _walletRepository.hasPin()));
        }
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to verify PIN: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: await _walletRepository.hasPin()));
    }
  }

  Future<void> _onClearPin(ClearPin event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      await _walletRepository.clearPin();
      if (state.wallet != null) {
        emit(WalletReady(
            wallet: state.wallet!,
            isTestnet: state.isTestnet,
            isPinSet: false));
      } else {
        emit(WalletInitial(isTestnet: state.isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to clear PIN: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: true));
    }
  }

  Future<void> _onToggleNetwork(
      ToggleNetwork event, Emitter<WalletState> emit) async {
    final previousWallet = state.wallet;
    final previousIsPinSet = state.isPinSet;

    emit(WalletLoading(
        currentIsTestnet: !state.isTestnet, currentIsPinSet: previousIsPinSet));
    try {
      final newNetworkIsTestnet = await _walletRepository.toggleNetwork();

      if (previousWallet != null) {
        final WalletModel updatedWalletOnNewNetwork =
            await _walletRepository.refreshBalance(previousWallet);

        final hasPin = await _walletRepository.hasPin();
        if (hasPin && state.status == WalletStatus.pinProtected) {
          emit(WalletRequiresPin(
              wallet: updatedWalletOnNewNetwork,
              isTestnet: newNetworkIsTestnet,
              isPinSet: true));
        } else if (hasPin &&
            (state.status == WalletStatus.ready ||
                state.status == WalletStatus.pinVerified)) {
          emit(WalletReady(
              wallet: updatedWalletOnNewNetwork,
              isTestnet: newNetworkIsTestnet,
              isPinSet: true));
        } else {
          emit(WalletReady(
              wallet: updatedWalletOnNewNetwork,
              isTestnet: newNetworkIsTestnet,
              isPinSet: hasPin));
        }
      } else {
        final hasPin = await _walletRepository.hasPin();
        emit(WalletInitial(isTestnet: newNetworkIsTestnet, isPinSet: hasPin));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to toggle network: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onSendTransaction(
      SendTransaction event, Emitter<WalletState> emit) async {
    final currentWallet = state.wallet;
    final bool currentIsTestnet = state.isTestnet;
    final bool currentIsPinSet = state.isPinSet;

    if (currentWallet == null) {
      emit(WalletError(
          errorMessage: 'Không thể gửi giao dịch: Không tìm thấy ví.',
          isTestnet: currentIsTestnet,
          isPinSet: currentIsPinSet));
      return;
    }

    // Cần kiểm tra thêm 0.001 ALGO cho phí giao dịch
    const minTxFee = 0.001; // 1000 microALGOs

    // Kiểm tra số dư có đủ bao gồm phí giao dịch không
    if (event.amount + minTxFee > currentWallet.balance) {
      emit(WalletError(
        errorMessage:
            'Số dư không đủ. Cần có ít nhất ${event.amount + minTxFee} ALGO (bao gồm phí giao dịch).',
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
      return;
    }

    // Kiểm tra số tiền giao dịch (ít nhất 0.1 ALGO)
    if (event.amount < 0.1) {
      emit(WalletError(
        errorMessage: 'Số tiền giao dịch phải ít nhất 0.1 ALGO.',
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
      return;
    }

    emit(WalletLoading(
        currentIsTestnet: currentIsTestnet, currentIsPinSet: currentIsPinSet));

    try {
      // Thực hiện giao dịch
      final txId = await _walletRepository.sendTransaction(
        currentWallet,
        event.recipientAddress,
        event.amount,
        note: event.note,
      );

      if (kDebugMode) {
        print('Giao dịch hoàn tất với ID: $txId');
      }

      // Cập nhật số dư ví sau giao dịch
      final updatedWallet =
          await _walletRepository.refreshBalance(currentWallet);

      // Lấy lịch sử giao dịch đã cập nhật
      final transactions =
          await _walletRepository.getTransactionHistory(updatedWallet.address);

      // Phát trạng thái giao dịch đã gửi
      emit(WalletTransactionSent(
        wallet: updatedWallet,
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
        transactions: transactions,
      ));

      // Sau đó phát trạng thái sẵn sàng sau một khoảng thời gian
      await Future.delayed(const Duration(seconds: 2));

      emit(WalletReady(
        wallet: updatedWallet,
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
        transactions: transactions,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi trong _onSendTransaction: ${e.toString()}');
      }

      // Xử lý thông báo lỗi
      String errorMessage = e.toString();

      // Làm sạch thông báo lỗi cho người dùng
      if (errorMessage
          .contains("Exception: Failed to send transaction: Exception:")) {
        errorMessage = errorMessage.replaceAll(
            "Exception: Failed to send transaction: Exception:", "");
      } else if (errorMessage
          .contains("Exception: Failed to send transaction:")) {
        errorMessage = errorMessage.replaceAll(
            "Exception: Failed to send transaction:", "");
      } else if (errorMessage.contains("Exception:")) {
        errorMessage = errorMessage.replaceAll("Exception:", "");
      }

      errorMessage = errorMessage.trim();

      emit(WalletError(
        errorMessage: errorMessage,
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
    }
  }
}
