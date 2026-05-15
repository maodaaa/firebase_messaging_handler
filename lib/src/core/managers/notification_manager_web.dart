import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../../enums/export.dart';
import '../../models/export.dart';
import '../services/fcm_service.dart';
import '../utils/platform_utils.dart';

typedef BackgroundMessageCallback = Future<bool> Function(
    RemoteMessage message);
typedef DataOnlyMessageBridge = Future<void> Function(RemoteMessage message);
typedef UnifiedMessageHandler = Future<bool> Function(
    NormalizedMessage message, NotificationLifecycle lifecycle);

/// Web/WASM-safe notification manager.
///
/// Native local-notification features are no-ops on this path because
/// `flutter_local_notifications` is not currently WASM-compatible.
class NotificationManager {
  static NotificationManager? _instance;

  /// Singleton instance.
  static NotificationManager get instance {
    _instance ??= NotificationManager._internal();
    return _instance!;
  }

  NotificationManager._internal();

  final FCMService _fcmService = FCMService.instance;
  final StreamController<NotificationData?> _clickStreamController =
      StreamController<NotificationData?>.broadcast();
  final StreamController<InAppNotificationData> _inAppStreamController =
      StreamController<InAppNotificationData>.broadcast();

  UnifiedMessageHandler? _unifiedMessageHandler;
  Future<bool> Function(RemoteMessage message)? _backgroundCallback;
  DataOnlyMessageBridge? _dataOnlyMessageBridge;
  void Function(String event, Map<String, dynamic> data)? _analyticsCallback;
  String? _configuredTimezone;

  /// The reason the last FCM token fetch failed, or null after success.
  String? get lastTokenError => _fcmService.lastTokenError;

  Future<Stream<NotificationData?>?> initialize({
    required String senderId,
    required List<NotificationChannelData> androidChannels,
    required String androidNotificationIconPath,
    Future<bool> Function(String fcmToken)? updateTokenCallback,
    bool includeInitialNotificationInStream = true,
    String? webVapidKey,
  }) async {
    await _fcmService.initialize();
    final token = await _fcmService.getToken(vapidKey: webVapidKey);
    if (token != null && updateTokenCallback != null) {
      await updateTokenCallback(token);
    }
    FirebaseMessaging.onMessage.listen(processNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_emitMessageClick);
    if (includeInitialNotificationInStream) {
      final initial = await _fcmService.getInitialMessage();
      if (initial != null) {
        _emitMessageClick(initial, isFromTerminated: true);
      }
    }
    return _clickStreamController.stream;
  }

  Stream<NotificationData?> getNotificationClickStream() {
    return _clickStreamController.stream;
  }

  void emitTestClick(NotificationData data) {
    _clickStreamController.add(data);
  }

  Future<NotificationData?> getInitialNotificationData() async {
    return getInitialNotificationDataStatic();
  }

  static Future<NotificationData?> getInitialNotificationDataStatic() async {
    final message = await FCMService.instance.getInitialMessage();
    if (message == null) return null;
    return _notificationDataFromMessage(message, isFromTerminated: true);
  }

  Future<void> processNotification(RemoteMessage message,
      {NotificationLifecycle lifecycle =
          NotificationLifecycle.foreground}) async {
    await _invokeUnifiedHandler(message, lifecycle);
    if (message.notification == null && _dataOnlyMessageBridge != null) {
      await _dataOnlyMessageBridge!(message);
    }
  }

  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    Map<String, dynamic>? payload,
    String? channelId,
    int? notificationId,
  }) async {}

  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool allowWhileIdle = false,
  }) async {
    return false;
  }

  Future<bool> cancelScheduledNotification(int id) async => true;

  Future<bool> cancelAllScheduledNotifications() async => true;

  Future<List<dynamic>?> getPendingNotifications() async => const [];

  Future<String?> refreshLocalTimezone() async => _configuredTimezone;

  Future<String?> getConfiguredLocalTimezone() async => _configuredTimezone;

  Future<void> setIOSBadgeCount(int count) async {}

  Future<int?> getIOSBadgeCount() async => null;

  Future<void> setAndroidBadgeCount(int count) async {}

  Future<int?> getAndroidBadgeCount() async => null;

  Future<void> clearBadgeCount() async {}

  Future<void> subscribeToTopic(String topic) async {
    await _fcmService.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcmService.unsubscribeFromTopic(topic);
  }

  Future<void> unsubscribeFromAllTopics() async {}

  Future<String?> getFcmToken() async => _fcmService.getToken();

  Future<void> clearToken() async {}

  void setAnalyticsCallback(
      void Function(String event, Map<String, dynamic> data) callback) {
    _analyticsCallback = callback;
  }

  void trackAnalyticsEvent(String event, Map<String, dynamic> data) {
    _analyticsCallback?.call(event, data);
  }

  void setForegroundNotificationOptions(
      ForegroundNotificationOptions options) {}

  void registerInAppTemplates(
      Map<String, InAppNotificationTemplate> templates) {}

  void clearInAppTemplates() {}

  void setInAppFallbackDisplayHandler(
      InAppNotificationDisplayCallback? fallbackHandler) {}

  void setInAppNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {}

  Future<void> setInAppDeliveryPolicy(InAppDeliveryPolicy policy) async {}

  Stream<InAppNotificationData> getInAppMessageStream({
    bool includePendingStorageItems = true,
  }) {
    return _inAppStreamController.stream;
  }

  Future<void> flushPendingInAppMessages() async {}

  Future<void> clearPendingInAppMessages({String? id}) async {}

  Future<void> setBackgroundProcessingCallback(
      Future<bool> Function(RemoteMessage message)? callback) async {
    _backgroundCallback = callback;
  }

  void setDataOnlyMessageBridge(DataOnlyMessageBridge? bridge) {
    _dataOnlyMessageBridge = bridge;
  }

  Future<void> setUnifiedMessageHandler(UnifiedMessageHandler? handler) async {
    _unifiedMessageHandler = handler;
  }

  void enableDefaultDataOnlyBridge({
    String? channelId,
    String titleKey = 'title',
    String bodyKey = 'body',
  }) {
    _dataOnlyMessageBridge = (message) async {
      _emitMessageClick(message);
    };
  }

  Future<void> setBackgroundMessageHandler(
      Future<void> Function(RemoteMessage message) handler) async {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await _backgroundCallback?.call(message);
    await processNotification(
      message,
      lifecycle: NotificationLifecycle.background,
    );
  }

  Future<NotificationDiagnosticsResult> runDiagnostics() async {
    final token = await _fcmService.getToken();
    return NotificationDiagnosticsResult(
      success: true,
      permissionsGranted: token != null,
      authorizationStatus: token != null ? 'available' : 'unknown',
      fcmTokenAvailable: token != null,
      badgeSupported: false,
      webNotificationsAllowed: false,
      pendingNotificationCount: 0,
      platform: currentPlatformName,
      recommendations: token == null
          ? <String>['Check Firebase web configuration and VAPID key.']
          : const <String>[],
      metadata: <String, dynamic>{
        'lastTokenError': _fcmService.lastTokenError,
      },
    );
  }

  Future<void> dispose() async {
    await _clickStreamController.close();
    await _inAppStreamController.close();
  }

  Future<void> createCustomSoundChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String soundFileName,
    NotificationImportanceEnum importance = NotificationImportanceEnum.high,
    NotificationPriorityEnum priority = NotificationPriorityEnum.high,
    bool enableVibration = true,
    bool enableLights = true,
  }) async {}

  Future<List<String>?> getAvailableSounds() async => const [];

  Future<bool> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required RepeatIntervalEnum repeatInterval,
    required int hour,
    required int minute,
    String? channelId,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
  }) async {
    return false;
  }

  Future<bool> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? channelId,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
  }) async {
    return false;
  }

  Future<void> showGroupedNotification({
    required String title,
    required String body,
    required String groupKey,
    required String groupTitle,
    String? channelId,
    Map<String, dynamic>? payload,
    bool isSummary = false,
    int? notificationId,
  }) async {}

  Future<void> createNotificationGroup({
    required String groupKey,
    required String groupTitle,
    required List<NotificationData> notifications,
    String? channelId,
  }) async {}

  Future<void> dismissNotificationGroup(String groupKey) async {}

  Future<void> showThreadedNotification({
    required String title,
    required String body,
    required String threadIdentifier,
    String? channelId,
    Map<String, dynamic>? payload,
    int? notificationId,
  }) async {}

  Future<bool> _invokeUnifiedHandler(
      RemoteMessage message, NotificationLifecycle lifecycle) async {
    final handler = _unifiedMessageHandler;
    if (handler == null) return false;
    return handler(
        _normalizedMessageFromMessage(message, lifecycle), lifecycle);
  }

  void _emitMessageClick(RemoteMessage message,
      {bool isFromTerminated = false}) {
    _clickStreamController.add(
      _notificationDataFromMessage(
        message,
        isFromTerminated: isFromTerminated,
      ),
    );
  }

  static NotificationData _notificationDataFromMessage(
    RemoteMessage message, {
    bool isFromTerminated = false,
  }) {
    return NotificationData(
      payload: message.data,
      title: message.notification?.title ?? message.data['title'] as String?,
      body: message.notification?.body ?? message.data['body'] as String?,
      imageUrl:
          message.notification?.web?.image ?? message.data['image'] as String?,
      type: isFromTerminated
          ? NotificationTypeEnum.terminated
          : NotificationTypeEnum.foreground,
      isFromTerminated: isFromTerminated,
      messageId: message.messageId,
      senderId: message.senderId,
      timestamp: DateTime.now(),
    );
  }

  static NormalizedMessage _normalizedMessageFromMessage(
      RemoteMessage message, NotificationLifecycle lifecycle) {
    return NormalizedMessage(
      id: message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: message.notification?.title ?? message.data['title'] as String?,
      body: message.notification?.body ?? message.data['body'] as String?,
      imageUrl:
          message.notification?.web?.image ?? message.data['image'] as String?,
      data: message.data,
      receivedAt: DateTime.now(),
      lifecycle: lifecycle,
      origin: 'web',
      rawMessage: message,
    );
  }
}
