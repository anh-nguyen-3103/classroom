import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// A singleton service for managing Firebase Analytics integration.
///
/// This service provides a centralized way to handle analytics events and
/// screen tracking throughout the application. It follows the singleton pattern
/// to ensure consistent analytics state across the app.
///
/// Example usage:
/// ```dart
/// final analytics = AnalyticsService();
/// await analytics.init();
///
/// // Log a custom event
/// await analytics.logEvent(
///   name: 'user_action',
///   parameters: {'action_type': 'button_tap'},
/// );
///
/// // Track screen views
/// await analytics.logScreenView(screenName: 'home_screen');
/// ```
class AnalyticsService {
  /// Private constructor for singleton pattern.
  AnalyticsService._internal();

  /// Factory constructor that returns the singleton instance.
  factory AnalyticsService() => _instance;

  /// The singleton instance of [AnalyticsService].
  static final AnalyticsService _instance = AnalyticsService._internal();

  /// The Firebase Analytics instance.
  ///
  /// This will be null if initialization fails or hasn't been completed yet.
  FirebaseAnalytics? _analytics;

  /// Whether the analytics service has been successfully initialized.
  bool _initialized = false;

  /// Initializes the Firebase Analytics service.
  ///
  /// This method must be called before using any other analytics methods.
  /// It's safe to call multiple times - subsequent calls will be ignored.
  ///
  /// Returns a [Future] that completes when initialization is finished.
  /// If initialization fails, the service will be marked as disabled.
  ///
  /// Example:
  /// ```dart
  /// final analytics = AnalyticsService();
  /// await analytics.init();
  /// ```
  Future<void> init() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;

      if (kDebugMode) {
        print('AnalyticsService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnalyticsService: Failed to initialize - $e');
      }
    }
  }

  /// Whether the analytics service is enabled and ready to use.
  ///
  /// Returns `true` if the service has been initialized successfully and
  /// Firebase Analytics is available. Returns `false` otherwise.
  ///
  /// This should be checked before calling analytics methods to ensure
  /// they will function properly.
  bool get isEnabled => _initialized && _analytics != null;

  /// Logs a custom analytics event.
  ///
  /// The [name] parameter is required and should follow Firebase Analytics
  /// naming conventions (alphanumeric characters and underscores only).
  ///
  /// The optional [parameters] map can contain additional data about the event.
  /// Parameter values must be of type [String], [int], [double], or [bool].
  ///
  /// If the service is not enabled, this method will return immediately
  /// without logging anything.
  ///
  /// Example:
  /// ```dart
  /// await analytics.logEvent(
  ///   name: 'purchase_completed',
  ///   parameters: {
  ///     'item_id': 'abc123',
  ///     'item_category': 'electronics',
  ///     'value': 29.99,
  ///   },
  /// );
  /// ```
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!isEnabled) return;

    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        print('AnalyticsService: Logged event - $name: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnalyticsService: Failed to log event - $e');
      }
    }
  }

  /// Logs a screen view event for analytics tracking.
  ///
  /// The [screenName] parameter is required and should uniquely identify
  /// the screen or page being viewed.
  ///
  /// The optional [screenClass] parameter can be used to group similar
  /// screens together (e.g., 'ProductScreen' for different product pages).
  ///
  /// Screen view events help track user navigation patterns and popular
  /// content within your app.
  ///
  /// If the service is not enabled, this method will return immediately
  /// without logging anything.
  ///
  /// Example:
  /// ```dart
  /// await analytics.logScreenView(
  ///   screenName: 'product_detail',
  ///   screenClass: 'ProductScreen',
  /// );
  /// ```
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!isEnabled) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        print('AnalyticsService: Logged screen view - $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnalyticsService: Failed to log screen view - $e');
      }
    }
  }
}
