import 'package:lexiora/core/database/app_database.dart';

/// Web has browser-local storage and no Android auto-backup restore path.
class FreshInstallGuard {
  FreshInstallGuard();
  static final FreshInstallGuard instance = FreshInstallGuard();

  Future<bool> purgeStaleChatData(AppDatabase db) async => false;
}
