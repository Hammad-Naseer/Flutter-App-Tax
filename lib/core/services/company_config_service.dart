// lib/core/services/company_config_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage company configuration in local storage
class CompanyConfigService {
  static const String _configKey = 'company_configuration';
  static const String _logoUrlKey = 'company_logo_url';

  /// Save company configuration to local storage
  static Future<void> saveConfiguration(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save full config as JSON
      await prefs.setString(_configKey, jsonEncode(config));
      
      // Save logo URL separately for quick access
      final logoUrl = config['bus_logo_url']?.toString() ?? '';
      if (logoUrl.isNotEmpty) {
        await prefs.setString(_logoUrlKey, logoUrl);
      }
      
      print('✅ Company configuration saved to local storage');
    } catch (e) {
      print('❌ Error saving company configuration: $e');
    }
  }

  /// Get company configuration from local storage
  static Future<Map<String, dynamic>?> getConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null && configJson.isNotEmpty) {
        return jsonDecode(configJson) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('❌ Error loading company configuration: $e');
      return null;
    }
  }

  /// Get company logo URL from local storage
  static Future<String?> getLogoUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_logoUrlKey);
    } catch (e) {
      print('❌ Error loading company logo URL: $e');
      return null;
    }
  }

  /// Clear company configuration from local storage (on logout)
  static Future<void> clearConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
      await prefs.remove(_logoUrlKey);
      print('✅ Company configuration cleared from local storage');
    } catch (e) {
      print('❌ Error clearing company configuration: $e');
    }
  }

  /// Check if configuration exists in local storage
  static Future<bool> hasConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_configKey);
    } catch (e) {
      return false;
    }
  }
}

