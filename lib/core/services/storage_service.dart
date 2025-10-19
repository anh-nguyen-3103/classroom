import 'package:classroom/core/utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A comprehensive storage service wrapper around Hive for Flutter applications.
///
/// This service provides a simple and type-safe interface for local data persistence
/// using Hive as the underlying storage mechanism. It supports common operations
/// like saving, retrieving, updating, and deleting data with automatic initialization
/// and error handling.
///
/// ## Usage
///
/// Initialize the service once in your app's main function:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await StorageService.init();
///   runApp(MyApp());
/// }
/// ```
///
/// Then use throughout your app:
/// ```dart
/// // Save data
/// await StorageService.save('key', 'value');
///
/// // Retrieve data
/// String? value = StorageService.get<String>('key');
///
/// // Check if key exists
/// bool value = StorageService.exists('key');
/// ```
class StorageService {
  /// The internal Hive box instance for data storage.
  static late Box _box;

  /// Flag to track whether the service has been initialized.
  static bool _initialized = false;

  /// Initializes the storage service.
  ///
  /// This method must be called once before using any other methods.
  /// It initializes Hive for Flutter and opens the application's storage box.
  ///
  /// **Note:** This method is idempotent - calling it multiple times is safe.
  ///
  /// Throws:
  /// * [HiveError] if Hive initialization fails
  /// * [FileSystemException] if storage directory cannot be accessed
  ///
  /// Example:
  /// ```dart
  /// await StorageService.init();
  /// ```
  static Future<void> init() async {
    if (!_initialized) {
      await Hive.initFlutter();
      _box = await Hive.openBox(BoxStorageKeys.app);
      _initialized = true;
    }
  }

  /// Saves a value to storage with the specified key.
  ///
  /// The [key] must be a non-null string identifier.
  /// The [value] can be any serializable type supported by Hive.
  ///
  /// Parameters:
  /// * [key] - The unique identifier for the stored value
  /// * [value] - The data to store (must be serializable)
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  /// * [HiveError] if the save operation fails
  ///
  /// Example:
  /// ```dart
  /// await StorageService.save('user_age', 25);
  /// await StorageService.save('user_data', {'name': 'John', 'age': 25});
  /// ```
  static Future<void> save(String key, dynamic value) async {
    await _ensureInitialized();
    await _box.put(key, value);
  }

  /// Retrieves a value from storage by key with optional type casting.
  ///
  /// Returns the stored value cast to type [T], or [defaultValue] if the key
  /// doesn't exist or casting fails.
  ///
  /// Type parameters:
  /// * [T] - The expected return type
  ///
  /// Parameters:
  /// * [key] - The key to look up
  /// * [defaultValue] - Optional default value if key not found
  ///
  /// Returns:
  /// * The stored value of type [T], or [defaultValue] if not found
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  ///
  /// Example:
  /// ```dart
  /// String? name = StorageService.get<String>('user_name');
  /// int age = StorageService.get<int>('user_age', defaultValue: 0);
  /// ```
  static T? get<T>(String key, {T? defaultValue}) {
    _ensureInitializedSync();
    return _box.get(key, defaultValue: defaultValue);
  }

  /// Updates an existing value or creates a new one.
  ///
  /// This is functionally equivalent to [save] but semantically indicates
  /// an update operation.
  ///
  /// Parameters:
  /// * [key] - The key to update
  /// * [value] - The new value to store
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  /// * [HiveError] if the update operation fails
  ///
  /// Example:
  /// ```dart
  /// await StorageService.update('user_name', 'Jane Doe');
  /// ```
  static Future<void> update(String key, dynamic value) async {
    await save(key, value);
  }

  /// Deletes a key-value pair from storage.
  ///
  /// If the key doesn't exist, this operation completes without error.
  ///
  /// Parameters:
  /// * [key] - The key to delete
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  /// * [HiveError] if the delete operation fails
  ///
  /// Example:
  /// ```dart
  /// await StorageService.delete('temporary_data');
  /// ```
  static Future<void> delete(String key) async {
    await _ensureInitialized();
    await _box.delete(key);
  }

  /// Removes all key-value pairs from storage.
  ///
  /// **Warning:** This operation is irreversible and will delete all stored data.
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  /// * [HiveError] if the clear operation fails
  ///
  /// Example:
  /// ```dart
  /// await StorageService.clear();
  /// ```
  static Future<void> clear() async {
    await _ensureInitialized();
    await _box.clear();
  }

  /// Checks whether a key exists in storage.
  ///
  /// Parameters:
  /// * [key] - The key to check
  ///
  /// Returns:
  /// * `true` if the key exists, `false` otherwise
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  ///
  /// Example:
  /// ```dart
  /// if (StorageService.exists('user_preferences')) {
  ///   // Handle existing preferences
  /// }
  /// ```
  static bool exists(String key) {
    _ensureInitializedSync();
    return _box.containsKey(key);
  }

  /// Retrieves all keys currently stored.
  ///
  /// Returns:
  /// * A list of all string keys in storage
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  ///
  /// Example:
  /// ```dart
  /// List<String> keys = StorageService.getAllKeys();
  /// print('Stored keys: $keys');
  /// ```
  static List<String> getAllKeys() {
    _ensureInitializedSync();
    return _box.keys.cast<String>().toList();
  }

  /// Retrieves all values currently stored.
  ///
  /// Returns:
  /// * A list of all values in storage (order matches [getAllKeys])
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  ///
  /// Example:
  /// ```dart
  /// List<dynamic> values = StorageService.getAllValues();
  /// print('Stored values: $values');
  /// ```
  static List<dynamic> getAllValues() {
    _ensureInitializedSync();
    return _box.values.toList();
  }

  /// Gets the number of key-value pairs in storage.
  ///
  /// Returns:
  /// * The total count of stored items
  ///
  /// Throws:
  /// * [Exception] if the service is not initialized
  ///
  /// Example:
  /// ```dart
  /// int count = StorageService.length;
  /// print('Total items: $count');
  /// ```
  static int get length {
    _ensureInitializedSync();
    return _box.length;
  }

  /// Internal method to ensure the service is initialized before async operations.
  ///
  /// Automatically initializes the service if not already done.
  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  /// Internal method to ensure the service is initialized for synchronous operations.
  ///
  /// Throws an exception if the service hasn't been initialized, as sync operations
  /// cannot trigger initialization.
  ///
  /// Throws:
  /// * [Exception] with Vietnamese message if not initialized
  static void _ensureInitializedSync() {
    if (!_initialized) {
      throw Exception(
        'StorageService chưa được khởi tạo. Gọi StorageService.init() trước.',
      );
    }
  }

  /// Closes the storage service and releases resources.
  ///
  /// After calling this method, the service must be reinitialized before use.
  /// This is typically called when the app is being disposed.
  ///
  /// Throws:
  /// * [HiveError] if the close operation fails
  ///
  /// Example:
  /// ```dart
  /// await StorageService.close();
  /// ```
  static Future<void> close() async {
    if (_initialized) {
      await _box.close();
      _initialized = false;
    }
  }
}
