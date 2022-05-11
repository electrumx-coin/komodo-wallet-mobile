import 'package:flutter/foundation.dart';
import 'package:komodo_dex/model/wallet_security_settings.dart';
import 'package:komodo_dex/services/db/database.dart';
import 'package:komodo_dex/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';

WalletSecuritySettingsProvider walletSecuritySettingsProvider =
    WalletSecuritySettingsProvider();

class WalletSecuritySettingsProvider extends ChangeNotifier {
  // MRC: Needed to support using in Blocs
  // Should prefer using Provider when possible.
  WalletSecuritySettings _walletSecuritySettings = WalletSecuritySettings();
  SharedPreferences _prefs;

  WalletSecuritySettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> migrateSecuritySettings() async {
    Log('security_settings_provider', 'Migrating wallet security settings');

    // isCamoActive should always be removed on cold boot
    await _prefs.remove('isCamoActive');

    // MRC: If this key isn't present, we didn't do the migration yet,
    // this key also should be present on newly created wallets.
    if (_prefs.containsKey('wallet_security_settings_migrated')) return;

    try {
      await _prefs.setBool(
          'wallet_security_settings_migration_in_progress', true);

      final tmpPinProtection = _prefs.getBool('switch_pin');
      final tmpBioProtection = _prefs.getBool('switch_pin_biometric');
      final tmpCamoEnabled = _prefs.getBool('isCamoEnabled');
      final tmpCamoFraction = _prefs.getInt('camoFraction');
      final tmpCamoBalance = _prefs.getString('camoBalance');
      final tmpCamoSessionStartedAt = _prefs.getInt('camoSessionStartedAt');

      // MRC: We should migrate all wallets at once, this should be safer than
      // migrating only the current one, the user can change each of them later

      final tmpWalletSecuritySettings = WalletSecuritySettings(
        activatePinProtection: tmpPinProtection ?? false,
        activateBioProtection: tmpBioProtection ?? false,
        enableCamo: tmpCamoEnabled ?? false,
        isCamoActive: false,
        camoFraction: tmpCamoFraction,
        camoBalance: tmpCamoBalance,
        camoSessionStartedAt: tmpCamoSessionStartedAt,
      );

      _walletSecuritySettings = tmpWalletSecuritySettings;
      await _updateDb(allWallets: true);

      // Guarantee that pin creation is always done,
      // even if user doesn't complete it before update
      final tmpPinCreate = _prefs.getBool('isPinIsCreated');
      if (tmpPinCreate != null && tmpPinCreate)
        await _prefs.setBool('is_pin_creation_in_progress', true);
      await _prefs.remove('isPinIsCreated');

      // Clean up shared preferences

      // Old shared prefs
      // unused, was renamed to isPinIsCreated previously
      await _prefs.remove('isPinIsSet');

      // should have been deleted after finishing pin setup
      await _prefs.remove('pin_create');
      // renamed to is_camo_pin_creation_in_progress for better name
      await _prefs.remove('isCamoPinCreated');
      // should have been deleted after finishing camo pins etup

      await _prefs.setBool('wallet_security_settings_migrated', true);

      Log('security_settings_provider',
          'Migrated wallet security settings sucessfully');

      await Future.delayed(const Duration(milliseconds: 100));

      await _prefs.remove('wallet_security_settings_migration_in_progress');
    } catch (e) {
      Log('security_settings_provider',
          'Failed to migrate wallet security settings, error: ${e.toString()}');
    }
  }

  Future<void> getCurrentSettingsFromDb() async {
    _walletSecuritySettings = await Db.getCurrentWalletSecuritySettings();

    final pinProtection = _walletSecuritySettings.activatePinProtection;
    final bioProtection = _walletSecuritySettings.activateBioProtection;
    final camoEnabled = _walletSecuritySettings.enableCamo;
    final camoActive = _walletSecuritySettings.isCamoActive;
    final camoFraction = _walletSecuritySettings.camoFraction;
    final camoBalance = _walletSecuritySettings.camoBalance;
    final camoSessionStartedAt = _walletSecuritySettings.camoSessionStartedAt;

    await _prefs.setBool('switch_pin', pinProtection);
    await _prefs.setBool('switch_pin_biometric', bioProtection);
    await _prefs.setBool('isCamoEnabled', camoEnabled);
    await _prefs.setBool('isCamoActive', camoActive);
    if (camoFraction != null) await _prefs.setInt('camoFraction', camoFraction);
    if (camoBalance != null) await _prefs.setString('camoBalance', camoBalance);
    if (camoSessionStartedAt != null)
      await _prefs.setInt('camoSessionStartedAt', camoSessionStartedAt);
  }

  Future<void> _updateDb({bool allWallets = false}) async {
    await Db.updateWalletSecuritySettings(_walletSecuritySettings,
        allWallets: allWallets);
  }

  bool get activatePinProtection =>
      _prefs.getBool('switch_pin') ??
      _walletSecuritySettings.activatePinProtection;

  set activatePinProtection(bool v) {
    _walletSecuritySettings.activatePinProtection = v;
    _prefs.setBool('switch_pin', v);

    _updateDb().then((value) => notifyListeners());
  }

  bool get activateBioProtection =>
      _prefs.getBool('switch_pin_biometric') ??
      _walletSecuritySettings.activateBioProtection;

  set activateBioProtection(bool v) {
    _walletSecuritySettings.activateBioProtection = v;
    _prefs.setBool('switch_pin_biometric', v);

    _updateDb().then((value) => notifyListeners());
  }

  bool get enableCamo =>
      _prefs.getBool('isCamoEnabled') ?? _walletSecuritySettings.enableCamo;

  set enableCamo(bool v) {
    _walletSecuritySettings.enableCamo = v;
    _prefs.setBool('isCamoEnabled', v);

    _updateDb().then((value) => notifyListeners());
  }

  bool get isCamoActive => _prefs.getBool('isCamoActive') ?? false;

  set isCamoActive(bool v) {
    _prefs.setBool('isCamoActive', v);

    notifyListeners();
  }

  int get camoFraction =>
      _prefs.getInt('camoFraction') ?? _walletSecuritySettings.camoFraction;

  set camoFraction(int v) {
    _walletSecuritySettings.camoFraction = v;
    _prefs.setInt('camoFraction', v);

    _updateDb().then((value) => notifyListeners());
  }

  String get camoBalance =>
      _prefs.getString('camoBalance') ?? _walletSecuritySettings.camoBalance;

  set camoBalance(String v) {
    _walletSecuritySettings.camoBalance = v;
    if (v == null) {
      _prefs.remove('camoBalance');
    } else {
      _prefs.setString('camoBalance', v);
    }
    _updateDb().then((value) => notifyListeners());
  }

  int get camoSessionStartedAt =>
      _prefs.getInt('camoSessionStartedAt') ??
      _walletSecuritySettings.camoSessionStartedAt;

  set camoSessionStartedAt(int v) {
    _walletSecuritySettings.camoSessionStartedAt = v;
    _prefs.setInt('camoSessionStartedAt', v);

    _updateDb().then((value) => notifyListeners());
  }
}
