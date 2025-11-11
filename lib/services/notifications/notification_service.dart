abstract class NotificationService {
  Future<bool> requestPermissionsIfNotGranted();

  Future<bool> isAllowed();

  Future<bool> createRefreshNotification();

  Future<void> clearRefreshNotification();
}
