import '../core/constants/app_constants.dart';
import '../core/utils/password_utils.dart';
import '../database/daos/settings_dao.dart';

class PinService {
  final SettingsDao _settingsDao;
  PinService(this._settingsDao);

  Future<bool> isPinSet() async {
    final v = await _settingsDao.getValue(AppConstants.settingsPinHash);
    return v != null && v.isNotEmpty;
  }

  Future<bool> verify(String pin) async {
    final hash = await _settingsDao.getValue(AppConstants.settingsPinHash);
    if (hash == null || hash.isEmpty) return true;
    return PasswordUtils.hashPassword(pin) == hash;
  }

  Future<void> setPin(String pin) async {
    await _settingsDao.setValue(
      AppConstants.settingsPinHash,
      PasswordUtils.hashPassword(pin),
    );
  }

  Future<void> clearPin() =>
      _settingsDao.removeValue(AppConstants.settingsPinHash);
}