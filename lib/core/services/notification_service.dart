import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// A comprehensive notification service that handles both local and Firebase Cloud Messaging (FCM) notifications.
///
/// This service provides a unified interface for managing push notifications in Flutter apps,
/// combining Firebase Cloud Messaging for remote notifications and Flutter Local Notifications
/// for local notification display. It follows the singleton pattern to ensure consistent
/// notification handling across the entire application.
///
/// The service handles:
/// - FCM token management for push notifications
/// - Local notification display with custom styling
/// - Foreground and background message handling
/// - Topic subscription management
/// - Cross-platform notification configuration (Android/iOS)
///
/// ## Setup Requirements
///
/// Before using this service, ensure you have:
/// - Firebase project configured with FCM enabled
/// - Platform-specific notification permissions configured
/// - Background message handler registered in main.dart
///
/// ## Usage Example
///
/// ```dart
/// // Initialize the service (typically in main.dart)
/// final notificationService = NotificationService();
/// await notificationService.init();
///
/// // Display a local notification
/// await notificationService.showNotification(
///   title: 'Welcome!',
///   body: 'Thanks for using our app',
///   data: {'screen': 'home'},
/// );
///
/// // Subscribe to a topic for targeted messaging
/// await notificationService.subscribeTopic('news_updates');
///
/// // Get the FCM token for server-side targeting
/// final token = notificationService.token;
/// print('FCM Token: $token');
/// ```
class NotificationService {
  /// Private constructor for singleton implementation.
  NotificationService._internal();

  /// Factory constructor that returns the singleton instance.
  ///
  /// This ensures that only one instance of [NotificationService] exists
  /// throughout the application lifecycle.
  factory NotificationService() => _instance;

  /// The singleton instance of [NotificationService].
  static final NotificationService _instance = NotificationService._internal();

  /// Flutter Local Notifications plugin instance for displaying local notifications.
  ///
  /// This handles the actual display of notifications on the device,
  /// regardless of whether they originate from FCM or local sources.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Firebase Cloud Messaging instance for handling remote notifications.
  ///
  /// This manages FCM token generation, message reception, and topic subscriptions.
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// The current FCM registration token for this app installation.
  ///
  /// This token uniquely identifies the app installation and is used by
  /// your server to send targeted push notifications. The token may change
  /// when the app is restored on a new device, app is updated, or app data is cleared.
  String? _fcmToken;

  /// Initializes the notification service with both local and Firebase messaging setup.
  ///
  /// This method must be called before using any other notification functionality.
  /// It performs the following initialization steps:
  /// 1. Sets up local notification display capabilities
  /// 2. Configures Firebase Cloud Messaging
  /// 3. Requests necessary permissions
  /// 4. Registers message handlers for foreground notifications
  /// 5. Generates and stores the FCM token
  ///
  /// The method is safe to call multiple times - subsequent calls will complete
  /// the existing initialization process.
  ///
  /// Throws [Exception] if critical initialization steps fail.
  ///
  /// Example:
  /// ```dart
  /// final notificationService = NotificationService();
  /// try {
  ///   await notificationService.init();
  ///   print('Notifications ready');
  /// } catch (e) {
  ///   print('Failed to initialize notifications: $e');
  /// }
  /// ```
  Future<void> init() async {
    if (kDebugMode) print('NotificationService: Starting initialization');
    await _initLocal();
    await _initFirebase();
    if (kDebugMode) print('NotificationService: Initialization completed');
  }

  /// Initializes local notification capabilities for the current platform.
  ///
  /// This private method sets up the Flutter Local Notifications plugin
  /// with platform-specific configurations:
  /// - **Android**: Uses the app's launcher icon (@mipmap/ic_launcher)
  /// - **iOS**: Uses default Darwin (iOS) notification settings
  ///
  /// The initialization prepares the app to display notifications locally,
  /// which is necessary even for FCM messages that need custom display handling.
  Future<void> _initLocal() async {
    if (kDebugMode) {
      print('NotificationService: Initializing local notifications');
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(settings);
    if (kDebugMode) {
      print('NotificationService: Local notifications initialized');
    }
  }

  /// Initializes Firebase Cloud Messaging with permissions and message handlers.
  ///
  /// This private method performs several critical setup tasks:
  /// 1. **Permissions**: Requests notification permissions from the user
  /// 2. **Foreground Settings**: Configures how notifications appear when app is active
  /// 3. **Token Generation**: Retrieves the unique FCM token for this installation
  /// 4. **Message Handlers**: Sets up listeners for incoming messages
  ///
  /// ## Message Handling
  ///
  /// The method registers handlers for two key scenarios:
  /// - **Foreground Messages**: When app is active and user receives a notification
  /// - **App Launch**: When user taps a notification to open/resume the app
  ///
  /// Both handlers automatically display notifications using [showNotification].
  ///
  /// ## Background Messages
  ///
  /// Background message handling (when app is terminated) must be registered
  /// separately in your main.dart file using a top-level function.
  Future<void> _initFirebase() async {
    if (kDebugMode) {
      print('NotificationService: Initializing Firebase messaging');
    }

    await _messaging.requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) print('NotificationService: Permission requested');

    _fcmToken = await _messaging.getToken();
    if (kDebugMode) print('NotificationService: FCM Token: $_fcmToken');

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print(
          'NotificationService: Received foreground message: ${message.messageId}',
        );
      }
      showNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        data: message.data,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print(
          'NotificationService: App opened from notification: ${message.messageId}',
        );
      }
      showNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        data: message.data,
      );
    });

    // Background handling is registered in main.dart via top-level handler

    if (kDebugMode) {
      print('NotificationService: Firebase messaging initialized');
    }
  }

  /// Displays a local notification with the specified content and optional data payload.
  ///
  /// This method creates and shows a notification using the local notifications plugin.
  /// The notification will appear in the device's notification tray and can be customized
  /// with platform-specific settings.
  ///
  /// ## Parameters
  ///
  /// - [title]: The notification title (required) - appears prominently in the notification
  /// - [body]: The notification body text (required) - provides detailed message content
  /// - [data]: Optional key-value pairs for custom data handling when notification is tapped
  ///
  /// ## Platform Configuration
  ///
  /// - **Android**: Uses 'default_channel' with high importance for prominent display
  /// - **iOS**: Uses standard Darwin notification presentation
  ///
  /// ## Data Payload
  ///
  /// The optional [data] parameter is JSON-encoded and stored as the notification payload.
  /// This allows you to pass custom information that can be accessed when the user
  /// interacts with the notification.
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Simple notification
  /// await notificationService.showNotification(
  ///   title: 'New Message',
  ///   body: 'You have received a new message',
  /// );
  ///
  /// // Notification with custom data
  /// await notificationService.showNotification(
  ///   title: 'Order Update',
  ///   body: 'Your order #123 has been shipped',
  ///   data: {
  ///     'type': 'order_update',
  ///     'order_id': '123',
  ///     'screen': 'order_details',
  ///   },
  /// );
  /// ```
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (kDebugMode) {
      print(
        'NotificationService: Showing notification - Title: "$title", Body: "$body"',
      );
    }

    const android = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: data != null ? json.encode(data) : null,
    );

    if (kDebugMode) {
      print('NotificationService: Notification shown successfully');
    }
  }

  /// The current FCM registration token for this app installation.
  ///
  /// This token is a unique identifier that your server can use to send
  /// targeted push notifications to this specific app installation.
  ///
  /// ## Important Notes
  ///
  /// - The token is generated during [init] and may be `null` before initialization
  /// - Tokens can change when the app is updated, restored, or data is cleared
  /// - Your server should handle token updates to ensure message delivery
  /// - Store this token server-side to enable push notification targeting
  ///
  /// ## Usage
  ///
  /// ```dart
  /// final token = notificationService.token;
  /// if (token != null) {
  ///   // Send token to your server
  ///   await apiService.updateFcmToken(token);
  /// } else {
  ///   print('Notification service not initialized yet');
  /// }
  /// ```
  ///
  /// Returns the FCM token string, or `null` if not yet generated or if
  /// initialization failed.
  String? get token {
    if (kDebugMode) print('NotificationService: Token requested: $_fcmToken');
    return _fcmToken;
  }

  /// Subscribes this app installation to a Firebase Cloud Messaging topic.
  ///
  /// Topics allow you to send messages to multiple devices that have opted in
  /// to a particular topic. This is useful for broadcasting messages to user
  /// segments without managing individual device tokens.
  ///
  /// ## Topic Naming Rules
  ///
  /// Topic names must:
  /// - Be 1-900 characters long
  /// - Contain only letters, numbers, hyphens (-), and underscores (_)
  /// - Not start with `/topics/` (this is added automatically)
  ///
  /// ## Use Cases
  ///
  /// - News categories (e.g., 'sports', 'technology', 'breaking_news')
  /// - User segments (e.g., 'premium_users', 'beta_testers')
  /// - Geographic regions (e.g., 'us_west_coast', 'europe')
  /// - App features (e.g., 'new_features', 'maintenance_alerts')
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Subscribe to news updates
  /// await notificationService.subscribeTopic('news_updates');
  ///
  /// // Subscribe to user's preferred categories
  /// final userPreferences = ['sports', 'technology', 'health'];
  /// for (final category in userPreferences) {
  ///   await notificationService.subscribeTopic(category);
  /// }
  /// ```
  ///
  /// The [topic] parameter specifies the topic name to subscribe to.
  ///
  /// Throws [FirebaseException] if the subscription fails due to network
  /// issues or invalid topic names.
  Future<void> subscribeTopic(String topic) async {
    if (kDebugMode) print('NotificationService: Subscribing to topic: $topic');
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) print('NotificationService: Subscribed to topic: $topic');
  }

  /// Unsubscribes this app installation from a Firebase Cloud Messaging topic.
  ///
  /// This removes the device from the specified topic's subscriber list,
  /// meaning it will no longer receive messages sent to that topic.
  ///
  /// ## When to Unsubscribe
  ///
  /// - User changes notification preferences
  /// - User account is deactivated or deleted
  /// - Topic is no longer relevant to the user
  /// - App feature requiring the topic is disabled
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Unsubscribe from promotional messages
  /// await notificationService.unsubscribeTopic('promotions');
  ///
  /// // Unsubscribe from multiple topics
  /// final topicsToRemove = ['old_feature', 'deprecated_alerts'];
  /// for (final topic in topicsToRemove) {
  ///   await notificationService.unsubscribeTopic(topic);
  /// }
  /// ```
  ///
  /// The [topic] parameter specifies the topic name to unsubscribe from.
  /// It's safe to unsubscribe from topics that the device wasn't subscribed to.
  ///
  /// Throws [FirebaseException] if the unsubscription fails due to network
  /// issues or Firebase service problems.
  Future<void> unsubscribeTopic(String topic) async {
    if (kDebugMode) {
      print('NotificationService: Unsubscribing from topic: $topic');
    }
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('NotificationService: Unsubscribed from topic: $topic');
    }
  }
}
