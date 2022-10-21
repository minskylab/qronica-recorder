import 'package:universal_html/html.dart';

class LocalStorageHelper {
  static Storage localStorage = window.localStorage;

  static void saveValue(String key, String value) {
    localStorage[key] = value;
  }

  static String getValue(String key, {String defaultValue = ''}) {
    return localStorage[key] ?? defaultValue;
  }

  static void removeValue(String key) {
    localStorage.remove(key);
  }

  static void clearAll() {
    localStorage.clear();
  }
}
