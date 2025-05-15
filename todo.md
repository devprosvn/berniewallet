# BernieWallet Development Checklist

## I. Project Setup & Configuration
- [x] Initialize Flutter project for BernieWallet.
- [x] Add all required dependencies to `pubspec.yaml` as specified.
- [x] Create the base project directory structure as outlined in the specification (`lib/config`, `lib/bloc`, `lib/models`, `lib/repositories`, `lib/services`, `lib/screens`, `lib/widgets`).
- [x] Create initial empty Dart files within the structure (e.g., `app.dart`, `constants.dart`, `theme.dart`, `routes.dart`, BLoC files, model files, service files, repository files, screen files, widget files).

## II. Core Wallet Functionality & Management
- [ ] **Wallet Creation:**
    - [x] Implement `AlgorandWalletService.createWallet()`:
        - [x] Generate cryptographically secure 25-word Algorand mnemonic (using `bip39`).
        - [x] Derive Algorand public address from mnemonic (using `algorand_dart`).
    - [x] Implement secure storage of mnemonic using `flutter_secure_storage` via `SecureStorageService.saveMnemonic()`.
    - [ ] Develop `CreateWalletScreen` UI.
    - [ ] Integrate `CreateWalletScreen` with `WalletBloc` (`CreateWallet` event) and `AlgorandWalletService`.
    - [ ] Display success confirmation and derived address.
- [x] **Wallet Import:**
    - [x] Implement `AlgorandWalletService.importWallet(mnemonic)`:
        - [x] Validate 25-word mnemonic format (using `bip39`).
        - [x] Recover wallet address from valid mnemonic (using `algorand_dart`).
    - [x] Implement secure storage of imported mnemonic using `flutter_secure_storage` via `SecureStorageService.saveMnemonic()`.
    - [ ] Develop `ImportWalletScreen` UI:
        - [ ] Allow 25-word mnemonic input with validation.
        - [ ] Support pasting from clipboard.
    - [ ] Integrate `ImportWalletScreen` with `WalletBloc` (`ImportWallet` event) and `AlgorandWalletService`.
    - [ ] Display success confirmation and recovered address.
- [ ] **Wallet Reset/Delete:**
    - [x] Implement `SecureStorageService.clearStorage()` to remove all wallet data.
    - [ ] Implement `WalletBloc` logic for `DeleteWallet` event.
    - [ ] Add functionality in `SettingsScreen` or a dedicated management screen.
    - [ ] Confirm action with the user before proceeding.
    - [ ] Return to onboarding flow after deletion.
- [ ] **Load Existing Wallet:**
    - [ ] Implement `SecureStorageService.getMnemonic()` to retrieve stored mnemonic.
    - [ ] Implement `WalletBloc` logic for `LoadWallet` event to load wallet on app start if one exists.

## III. Wallet Dashboard Features
- [ ] **Address Display:**
    - [ ] Develop `AddressCard` widget for `WalletScreen`.
    - [ ] Show full Algorand address with copy-to-clipboard functionality (using `clipboard` package).
    - [ ] Display QR code of the address (using `qr_flutter` package).
    - [ ] Show address in truncated format as well.
- [ ] **Balance Display:**
    - [x] Implement `AlgorandWalletService.getBalance(address)` to fetch account balance from Algorand API (using `http` package).
        - [ ] Connect to Algorand API (MainNet/TestNet).
        - [ ] Handle API errors and retry logic.
    - [ ] Develop `BalanceDisplay` widget for `WalletScreen`.
    - [ ] Display balance in both ALGOs and microALGOs (formatting with `intl` package).
    - [ ] Implement refresh mechanism (`RefreshBalance` event in `WalletBloc`).
    - [ ] Show placeholder/loading state (e.g., using `shimmer` package).

## IV. Security Implementation
- [ ] **Secure Storage:**
    - [ ] Ensure `flutter_secure_storage` is correctly implemented in `SecureStorageService` for all sensitive data (mnemonic, PIN).
    - [ ] Verify no mnemonics are stored in plain text or SharedPreferences.
    - [ ] Implement proper error handling for all storage operations.
- [ ] **Authentication:**
    - [ ] Implement `AuthBloc` (States: `Unauthenticated`, `Authenticating`, `Authenticated`, `AuthError`; Events: `Login`, `Logout`, `SetupPin`, `VerifyBiometrics`).
    - [x] Implement `SecureStorageService` methods for PIN: `savePin(pin)`, `verifyPin(pin)`.
    - [ ] Add simple PIN protection for app access.
        - [ ] Develop UI for PIN setup and login.
    - [ ] Implement biometric authentication if available (using `local_auth` package).
    - [ ] Require authentication before displaying mnemonic (e.g., in settings or a dedicated "view recovery phrase" screen).

## V. Transaction History
- [ ] **Transaction List:**
    - [x] Implement `AlgorandWalletService.getTransactions(address)` to fetch transaction history from Algorand API.
        - [ ] Handle API errors.
    - [ ] Create `TransactionModel` data class.
    - [ ] Develop `TransactionsScreen` UI.
    - [ ] Develop `TransactionListItem` widget.
    - [ ] Display recent transactions: type, amount, timestamp (formatting with `intl` package).
    - [ ] Implement pagination or "load more" functionality.
    - [ ] Handle empty states gracefully.

## VI. Technical Architecture
- [ ] **State Management (BLoC):**
    - [ ] Implement `WalletBloc`:
        - [ ] Define States: `WalletInitial`, `WalletLoading`, `WalletCreated`, `WalletImported`, `WalletReady`, `WalletError`.
        - [ ] Define Events: `CreateWallet`, `ImportWallet`, `LoadWallet`, `DeleteWallet`, `RefreshBalance`.
        - [ ] Ensure all wallet operations are managed through this BLoC.
    - [ ] Implement `AuthBloc`:
        - [ ] Define States: `Unauthenticated`, `Authenticating`, `Authenticated`, `AuthError`.
        - [ ] Define Events: `Login`, `Logout`, `SetupPin`, `VerifyBiometrics`.
        - [ ] Ensure all authentication flows are managed through this BLoC.
    - [ ] Use `equatable` for BLoC states and events.
- [ ] **Service Layer:**
    - [ ] Implement `AlgorandWalletService` with all specified methods: `createWallet()`, `importWallet(mnemonic)`, `getBalance(address)`, `getTransactions(address)`.
    - [ ] Implement `SecureStorageService` with all specified methods: `saveMnemonic(mnemonic)`, `getMnemonic()`, `savePin(pin)`, `verifyPin(pin)`, `clearStorage()`.
- [ ] **Repository Pattern:**
    - [ ] Implement `WalletRepository` as an interface between BLoCs and services.
    - [ ] Handle data transformation and business logic within the repository.
    - [ ] Provide unified error handling.
- [ ] **Models:**
    - [ ] Create `WalletModel` (if needed beyond just address/mnemonic).
    - [ ] Create `TransactionModel`.

## VII. UI/UX & App Structure
- [ ] **Project Structure:**
    - [ ] Ensure the `lib/` directory matches the specified structure.
- [ ] **App Entry & Navigation:**
    - [ ] Set up `app.dart` as the app entry point.
    - [ ] Define app constants in `config/constants.dart`.
    - [ ] Define app theming in `config/theme.dart` (Algorand branding).
    - [ ] Define route definitions in `config/routes.dart` and implement navigation.
- [ ] **Screens:**
    - [ ] Develop `Onboarding` screens: `WelcomeScreen`, `CreateWalletScreen`, `ImportWalletScreen`.
    - [ ] Develop `Home` screens: `HomeScreen` (main dashboard), `WalletScreen` (address/balance), `TransactionsScreen`.
    - [ ] Develop `SettingsScreen` (wallet reset, view mnemonic option, MainNet/TestNet switch).
- [ ] **Widgets:**
    - [ ] Develop shared widgets: `AppButton`, `LoadingIndicator`, `MnemonicDisplay`.
    - [ ] Develop wallet-specific widgets: `AddressCard`, `BalanceDisplay`.
    - [ ] Develop transaction-specific widgets: `TransactionListItem`.
- [ ] **UI/UX Guidelines:**
    - [ ] Implement a clean, modern design.
    - [ ] Use consistent color scheme (Algorand blue/teal).
    - [ ] Ensure inputs have validation feedback.
    - [ ] Include loading states and error feedback.
    - [ ] Ensure text is accessible and readable.
    - [ ] Design responsive layouts.
    - [ ] Use `google_fonts` for custom fonts.
    - [ ] Use `flutter_svg` for SVG support if needed.

## VIII. API Integration
- [ ] **Algorand API:**
    - [ ] Use correct API endpoints for MainNet (`https://mainnet-api.algonode.cloud`) and TestNet (`https://testnet-api.algonode.cloud`).
    - [ ] Implement proper API error handling and retry logic.
    - [ ] Add network status indicators (optional, if time permits).
    - [ ] Implement option to switch between MainNet/TestNet (e.g., in `SettingsScreen`).

## IX. Testing & Documentation
- [ ] **Testing (as per specification, if time allows after core functionality):**
    - [ ] Write unit tests for core wallet functionality (service layer).
    - [ ] Write widget tests for critical UI components.
    - [ ] Write BLoC tests for state management.
    - [ ] Test mnemonic generation against Algorand standards.
    - [ ] Test secure storage implementation.
- [ ] **Code Comments:**
    - [ ] Add clear code comments explaining key functionality for educational purposes throughout the codebase.
- [ ] **README:**
    - [ ] Create a `README.md` file.
    - [ ] Include setup instructions.
    - [ ] Include brief feature documentation.
    - [ ] Include instructions on how to run and test the application.

## X. Finalization & Delivery
- [ ] Review all implemented features against the specification.
- [ ] Ensure the application compiles without errors.
- [ ] Ensure proper error handling is implemented throughout.
- [ ] Verify that the application functions correctly for all specified core features.
- [ ] Confirm that security best practices for mnemonic and sensitive data handling are followed.
- [ ] Verify clean architecture principles (BLoC, repository, separation of concerns) are maintained.
- [ ] Ensure code is well-commented.
- [ ] Prepare the `lib/` directory and `pubspec.yaml` for delivery.
- [ ] Prepare brief documentation on running/testing.
- [ ] Package all deliverables.
- [ ] Notify user and send deliverables.
