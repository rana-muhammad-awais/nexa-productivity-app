import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Centralized security service for Biometric and Passcode Authentication.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  bool _isAppUnlocked = false;
  bool _isVaultUnlocked = false;

  bool get isAppUnlocked => _isAppUnlocked;
  bool get isVaultUnlocked => _isVaultUnlocked;

  void lockApp() => _isAppUnlocked = false;
  void unlockApp() => _isAppUnlocked = true;

  void lockVault() => _isVaultUnlocked = false;
  void unlockVault() => _isVaultUnlocked = true;

  /// Check if hardware supports biometrics or device credentials.
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('AuthService.canAuthenticate error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get list of supported biometric types (e.g. fingerprint, face).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('AuthService.getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Prompt user for Biometrics or device PIN/Pattern/Password.
  Future<bool> authenticate({
    String reason = 'Unlock Nexora Personal OS',
    bool stickyAuth = true,
  }) async {
    try {
      final isSupported = await canAuthenticate();
      if (!isSupported) {
        // If device has no security hardware/setup, allow access
        _isAppUnlocked = true;
        return true;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allows device PIN/pattern as fallback
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        _isAppUnlocked = true;
      }
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('AuthService.authenticate error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AuthService.authenticate general error: $e');
      return false;
    }
  }

  /// Specifically authenticate for Vault / Sensitive resources
  Future<bool> authenticateVault() async {
    final success = await authenticate(
      reason: 'Verify identity to unlock Nexora Vault',
    );
    if (success) {
      _isVaultUnlocked = true;
    }
    return success;
  }
}
