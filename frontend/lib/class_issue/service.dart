import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'models.dart';

class ClassIssueService {
  static Future<String> _getApiUrl(String action) async {
    final baseUrl = await ApiService.getBaseUrl();
    return '$baseUrl/api_class_issues.php?action=$action';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final userId = prefs.getString('auth_user_id') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-USER-ID': userId,
    };
  }

  /// Get allowed categories (from categories table)
  static Future<List<ClassIssueType>> getIssueTypes() async {
    try {
      final url = await _getApiUrl('get_categories');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'];
          return data.map((item) => ClassIssueType.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getMyClasses() async {
    try {
      final url = await _getApiUrl('get_my_classes');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitIssue(
    int catNo,
    String description,
    int? clsNo,
  ) async {
    try {
      final url = await _getApiUrl('submit_issue');
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'cat_no': catNo,
          'description': description,
          'cls_no': clsNo,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<ClassroomIssue>> getMyIssues() async {
    try {
      final url = await _getApiUrl('get_my_issues');
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'];
          return data.map((item) => ClassroomIssue.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<IssueTracking>> getTracking(int complaintId) async {
    try {
      final url = await _getApiUrl('get_tracking') + '&id=$complaintId';
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final List data = decoded['data'];
          return data.map((item) => IssueTracking.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
