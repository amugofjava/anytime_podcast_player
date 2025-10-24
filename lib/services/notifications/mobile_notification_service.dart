import 'package:anytime/core/utils.dart';
import 'package:anytime/services/notifications/notification_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MobileNotificationService extends NotificationService {
  bool _initialised = false;

  MobileNotificationService() {
    if (!_initialised) {
      _init();
      _initialised = true;
    }
  }

  void _init() {
    AwesomeNotifications().initialize(
        'resource://drawable/ic_refresh',
        [
          NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic tests',
            playSound: false,
            enableVibration: false,
            enableLights: false,
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
          )
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group',
          )
        ],
        debug: true);
  }

  @override
  Future<bool> requestPermissionsIfNotGranted() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    bool allowed = false;

    if (!isAllowed) {
      allowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    return allowed;
  }

  @override
  Future<bool> isAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  @override
  Future<void> clearRefreshNotification() async {
    AwesomeNotifications().cancel(10);
  }

  @override
  Future<bool> createRefreshNotification() async {
    final locale = await currentLocale();
    final alertTitle = Intl.message('alert_sync_title_label', locale: locale);
    final alertBody = Intl.message('alert_sync_title_body', locale: locale);

    return await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        customSound: null,
        actionType: ActionType.SilentBackgroundAction,
        wakeUpScreen: false,
        criticalAlert: false,
        category: NotificationCategory.Service,
        title: alertTitle,
        body: alertBody,
      ),
    );
  }
}
