import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static const String _groupingKey = 'groupingOption';
  static const String _viewTypeKey = 'viewType';

  // Save the selected grouping state
  static Future<void> saveGroupingState(String groupingOption) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupingKey, groupingOption);
  }

  // Save the selected view type (ListView or GridView)
  static Future<void> saveViewType(bool isListView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_viewTypeKey, isListView);
  }

  // Retrieve the saved grouping state
  static Future<String?> getGroupingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groupingKey) ?? 'none';  // Default value if not set
  }

  // Retrieve the saved view type
  static Future<bool> getViewType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_viewTypeKey) ?? true;  // Default to ListView if not set
  }
}