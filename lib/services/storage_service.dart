// services/storage_service.dart - Secure storage operations
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bernie_wallet/config/constants.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
      // Options for Android and iOS can be configured here if needed
      // aOptions: AndroidOptions(encryptedSharedPreferences: true),
      // iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  // Singleton pattern for easy access if not using DI for services
  // static final StorageService _instance = StorageService._internal();
  // factory StorageService() => _instance;
  // StorageService._internal();

  // Mnemonic Storage
  Future<void> saveMnemonic(String mnemonic) async {
    await _secureStorage.write(key: kMnemonicStorageKey, value: mnemonic);
  }

  Future<String?> getMnemonic() async {
    return await _secureStorage.read(key: kMnemonicStorageKey);
  }

  Future<void> deleteMnemonic() async {
    await _secureStorage.delete(key: kMnemonicStorageKey);
  }

  // Wallet Address Storage (mainly for quick lookup, derived from mnemonic)
  Future<void> saveWalletAddress(String address) async {
    await _secureStorage.write(key: kWalletAddressStorageKey, value: address);
  }

  Future<String?> getWalletAddress() async {
    return await _secureStorage.read(key: kWalletAddressStorageKey);
  }

  Future<void> deleteWalletAddress() async {
    await _secureStorage.delete(key: kWalletAddressStorageKey);
  }

  // PIN Storage
  Future<void> savePin(String pin) async {
    // Consider hashing the PIN before storing for added security, though flutter_secure_storage is already encrypted.
    // For simplicity, storing directly. If hashing, verification logic will also change.
    await _secureStorage.write(key: kPinStorageKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _secureStorage.read(key: kPinStorageKey);
  }

  Future<void> deletePin() async {
    await _secureStorage.delete(key: kPinStorageKey);
  }

  // Network Preference Storage
  Future<void> saveNetworkPreference(bool isTestnet) async {
    await _secureStorage.write(
        key: kNetworkPreferenceStorageKey,
        value: isTestnet ? 'testnet' : 'mainnet');
  }

  Future<bool> getNetworkPreferenceIsTestnet() async {
    final preference =
        await _secureStorage.read(key: kNetworkPreferenceStorageKey);
    // Default to Mainnet if no preference is stored
    return preference == 'testnet';
  }

  // Alias methods for more consistent naming in AlgorandService
  Future<bool> isTestnet() async {
    return await getNetworkPreferenceIsTestnet();
  }

  Future<void> setTestnet(bool isTestnet) async {
    await saveNetworkPreference(isTestnet);
  }

  Future<void> deleteNetworkPreference() async {
    await _secureStorage.delete(key: kNetworkPreferenceStorageKey);
  }

  // Clear all wallet related data
  Future<void> clearAllWalletData() async {
    await deleteMnemonic();
    await deleteWalletAddress();
    await deletePin();
    await deleteNetworkPreference();
    // Add any other keys you might store
  }
}
