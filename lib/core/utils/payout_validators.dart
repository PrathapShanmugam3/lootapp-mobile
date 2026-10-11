/// UPI / bank account rules shared by Edit account (where payout details are
/// entered) and the Withdraw sheet (which pays to the saved details). Same
/// regexes the API enforces in profileService.js and walletService.js.
class PayoutValidators {
  PayoutValidators._();

  static final upiPattern = RegExp(r'^[a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+$');
  static final accountPattern = RegExp(r'^[0-9]{9,18}$');
  static final ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  static bool isValidUpi(String v) => upiPattern.hasMatch(v.trim());
  static bool isValidAccount(String v) => accountPattern.hasMatch(v.trim());
  static bool isValidIfsc(String v) => ifscPattern.hasMatch(v.trim().toUpperCase());

  /// UPI ID is optional, but must be valid when filled.
  static String? upi(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!value.contains('@')) return 'UPI ID must contain @ (e.g. name@okhdfc)';
    return isValidUpi(value) ? null : 'Enter a valid UPI ID';
  }

  /// Account number is required whenever an IFSC code is entered.
  static String? account(String? v, {required String ifsc}) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return ifsc.trim().isEmpty ? null : 'Account number is required with IFSC';
    if (value.length < 9) return 'Account number must be 9–18 digits';
    return isValidAccount(value) ? null : 'Enter a valid account number';
  }

  /// IFSC is required whenever an account number is entered.
  static String? ifsc(String? v, {required String account}) {
    final value = v?.trim().toUpperCase() ?? '';
    if (value.isEmpty) return account.trim().isEmpty ? null : 'IFSC code is required with account number';
    if (value.length != 11) return 'IFSC code must be 11 characters';
    return isValidIfsc(value) ? null : 'Enter a valid IFSC code (e.g. HDFC0001234)';
  }
}
