import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String appId = 'YOUR_ONESIGNAL_APP_ID'; // TODO: Replace with actual App ID

  /// Initialize OneSignal
  static Future<void> initialize() async {
    // Enable verbose logging for debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal with App ID
    OneSignal.initialize(appId);

    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Set up notification handlers
    _setupNotificationHandlers();
  }

  /// Set up notification event handlers
  static void _setupNotificationHandlers() {
    // Notification opened handler
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.notificationId}');

      // Handle notification click
      final data = event.notification.additionalData;
      if (data != null) {
        // Navigate to task detail if task_id is present
        if (data.containsKey('task_id')) {
          final taskId = data['task_id'] as String;
          print('Navigate to task: $taskId');
          // Navigation will be handled by router in main.dart
        }
      }
    });

    // Foreground notification handler
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Foreground notification: ${event.notification.notificationId}');

      // Display the notification even when app is in foreground
      event.preventDefault();
      event.notification.display();
    });

    // Permission observer
    OneSignal.Notifications.addPermissionObserver((state) {
      print('Notification permission state changed: $state');
    });
  }

  /// Get the current player ID (device identifier)
  static Future<String?> getPlayerId() async {
    final subscription = OneSignal.User.pushSubscription;
    return subscription.id;
  }

  /// Set external user ID (for linking to your backend)
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
    print('OneSignal external user ID set: $userId');
  }

  /// Remove external user ID (on logout)
  static Future<void> removeExternalUserId() async {
    await OneSignal.logout();
    print('OneSignal external user ID removed');
  }

  /// Send tags for user segmentation
  static Future<void> sendTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
    print('OneSignal tags sent: $tags');
  }

  /// Remove tags
  static Future<void> removeTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
    print('OneSignal tags removed: $keys');
  }

  /// Check if user has granted notification permission
  static Future<bool> hasPermission() async {
    return await OneSignal.Notifications.permission;
  }

  /// Prompt user for notification permission
  static Future<bool> promptPermission() async {
    return await OneSignal.Notifications.requestPermission(true);
  }
}
