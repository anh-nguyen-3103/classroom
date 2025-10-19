import 'package:classroom/core/services/storage_service.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// Enum defining available haptic feedback modes
enum HapticMode { off, light, medium, heavy }

/// A service class that provides haptic feedback functionality with mode switching.
///
/// This service wraps the haptic_feedback package to provide a clean interface
/// for triggering haptic feedback with automatic capability checking and
/// user-configurable haptic modes.
///
/// Example usage:
/// ```dart
/// // Set haptic mode
/// await HapticService.setMode(HapticMode.medium);
///
/// // Trigger haptic feedback (will use current mode)
/// await HapticService.feedback();
///
/// // Check current mode
/// HapticMode currentMode = HapticService.currentMode;
///
/// // Get all available modes
/// List<HapticMode> modes = HapticService.availableModes;
/// ```
class HapticService {
  /// The current haptic feedback mode
  static HapticMode _currentMode = HapticMode.medium;

  /// Storage key for persisting haptic mode preference
  static const String _hapticModeKey = 'haptic_mode';

  /// Returns the current haptic feedback mode
  static HapticMode get currentMode => _currentMode;

  /// Returns all available haptic modes
  static List<HapticMode> get availableModes => HapticMode.values;

  /// Returns whether haptic feedback is available on the current device.
  ///
  /// This getter checks if the device supports haptic feedback capabilities.
  /// It's recommended to check this before attempting to use haptic feedback
  /// in your application, although all haptic methods in this service
  /// automatically perform this check.
  ///
  /// Returns a [Future<bool>] that resolves to `true` if haptic feedback
  /// is supported, `false` otherwise.
  static Future<bool> get active async {
    return await Haptics.canVibrate();
  }

  /// Initializes the haptic service and loads saved mode preference.
  ///
  /// This should be called during app initialization to restore the user's
  /// previously selected haptic mode.
  ///
  /// Requires StorageService to be initialized first.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await StorageService.init();
  ///   await HapticService.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init() async {
    try {
      final savedModeIndex = StorageService.get<int>(_hapticModeKey);
      if (savedModeIndex != null &&
          savedModeIndex >= 0 &&
          savedModeIndex < HapticMode.values.length) {
        _currentMode = HapticMode.values[savedModeIndex];
      }
    } catch (e) {
      // If storage fails, keep default mode
      _currentMode = HapticMode.medium;
    }
  }

  /// Sets the haptic feedback mode and persists the preference.
  ///
  /// Parameters:
  /// * [mode] - The haptic mode to set
  ///
  /// Example:
  /// ```dart
  /// // Turn off haptic feedback
  /// await HapticService.setMode(HapticMode.off);
  ///
  /// // Set to heavy haptic feedback
  /// await HapticService.setMode(HapticMode.heavy);
  /// ```
  static Future<void> setMode(HapticMode mode) async {
    _currentMode = mode;
    try {
      await StorageService.save(_hapticModeKey, mode.index);
    } catch (e) {
      // If storage fails, mode is still set for current session
    }
  }

  /// Cycles to the next haptic mode in the sequence: off → light → medium → heavy → off
  ///
  /// Returns the new mode that was set.
  ///
  /// Example:
  /// ```dart
  /// // Cycle through modes on settings button tap
  /// HapticMode newMode = await HapticService.cycleMode();
  /// print('New haptic mode: ${newMode.name}');
  /// ```
  static Future<HapticMode> cycleMode() async {
    final currentIndex = _currentMode.index;
    final nextIndex = (currentIndex + 1) % HapticMode.values.length;
    final nextMode = HapticMode.values[nextIndex];
    await setMode(nextMode);
    return nextMode;
  }

  /// Triggers haptic feedback based on the current mode.
  ///
  /// This is the main method to use for haptic feedback throughout your app.
  /// It will automatically use the appropriate haptic intensity based on the
  /// current mode setting, or do nothing if mode is set to off.
  ///
  /// Example:
  /// ```dart
  /// // Trigger haptic feedback on button tap
  /// onTap: () async {
  ///   await HapticService.feedback();
  ///   // Handle button action
  /// }
  /// ```
  static Future<void> feedback() async {
    if (_currentMode == HapticMode.off || !(await active)) {
      return;
    }

    switch (_currentMode) {
      case HapticMode.light:
        await _triggerLight();
        break;
      case HapticMode.medium:
        await _triggerMedium();
        break;
      case HapticMode.heavy:
        await _triggerHeavy();
        break;
      case HapticMode.off:
        break;
    }
  }

  /// Triggers a light haptic feedback regardless of current mode.
  ///
  /// This method provides subtle haptic feedback suitable for light touches,
  /// selections, or minor UI interactions. The feedback is only triggered
  /// if the device supports haptic capabilities.
  ///
  /// Note: This bypasses the current mode setting. Use [feedback()] for
  /// mode-aware haptic feedback.
  ///
  /// Example:
  /// ```dart
  /// // Force light haptic feedback
  /// await HapticService.light();
  /// ```
  static Future<void> light() async {
    if (await active) {
      await _triggerLight();
    }
  }

  /// Triggers a medium haptic feedback regardless of current mode.
  ///
  /// This method provides moderate haptic feedback suitable for standard
  /// UI interactions, notifications, or confirmations. The feedback is
  /// only triggered if the device supports haptic capabilities.
  ///
  /// Note: This bypasses the current mode setting. Use [feedback()] for
  /// mode-aware haptic feedback.
  ///
  /// Example:
  /// ```dart
  /// // Force medium haptic feedback
  /// await HapticService.medium();
  /// ```
  static Future<void> medium() async {
    if (await active) {
      await _triggerMedium();
    }
  }

  /// Triggers a heavy haptic feedback regardless of current mode.
  ///
  /// This method provides strong haptic feedback suitable for important
  /// actions, errors, or significant state changes. The feedback is
  /// only triggered if the device supports haptic capabilities.
  ///
  /// Note: This bypasses the current mode setting. Use [feedback()] for
  /// mode-aware haptic feedback.
  ///
  /// Use this sparingly as heavy haptic feedback can be jarring to users
  /// if overused.
  ///
  /// Example:
  /// ```dart
  /// // Force heavy haptic feedback
  /// await HapticService.heavy();
  /// ```
  static Future<void> heavy() async {
    if (await active) {
      await _triggerHeavy();
    }
  }

  /// Gets a human-readable name for the given haptic mode.
  ///
  /// Parameters:
  /// * [mode] - The haptic mode to get the name for (optional, uses current mode if null)
  ///
  /// Returns a localized string name for the mode.
  ///
  /// Example:
  /// ```dart
  /// String modeName = HapticService.getModeName(HapticMode.medium);
  /// // Returns: "Medium"
  /// ```
  static String getModeName([HapticMode? mode]) {
    final targetMode = mode ?? _currentMode;
    switch (targetMode) {
      case HapticMode.off:
        return 'Off';
      case HapticMode.light:
        return 'Light';
      case HapticMode.medium:
        return 'Medium';
      case HapticMode.heavy:
        return 'Heavy';
    }
  }

  /// Gets a human-readable description for the given haptic mode.
  ///
  /// Parameters:
  /// * [mode] - The haptic mode to get the description for (optional, uses current mode if null)
  ///
  /// Returns a localized string description for the mode.
  ///
  /// Example:
  /// ```dart
  /// String description = HapticService.getModeDescription(HapticMode.light);
  /// // Returns: "Subtle vibration for light touches"
  /// ```
  static String getModeDescription([HapticMode? mode]) {
    final targetMode = mode ?? _currentMode;
    switch (targetMode) {
      case HapticMode.off:
        return 'No haptic feedback';
      case HapticMode.light:
        return 'Subtle vibration for light touches';
      case HapticMode.medium:
        return 'Moderate vibration for standard interactions';
      case HapticMode.heavy:
        return 'Strong vibration for important actions';
    }
  }

  /// Returns whether haptic feedback is currently enabled (not set to off).
  static bool get isEnabled => _currentMode != HapticMode.off;

  // Private methods for triggering specific haptic types
  static Future<void> _triggerLight() async {
    await Haptics.vibrate(HapticsType.light);
  }

  static Future<void> _triggerMedium() async {
    await Haptics.vibrate(HapticsType.medium);
  }

  static Future<void> _triggerHeavy() async {
    await Haptics.vibrate(HapticsType.heavy);
  }
}
