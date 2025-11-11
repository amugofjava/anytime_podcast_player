import 'package:anytime/services/notifications/notification_service.dart';

class MockNotificationService extends NotificationService {
  @override
  Future<bool> isAllowed() async {
    return true;
  }

  @override
  Future<bool> requestPermissionsIfNotGranted() async {
    return true;
  }

  @override
  Future<void> clearRefreshNotification() async {}

  @override
  Future<bool> createRefreshNotification() async {
    return true;
  }
}
