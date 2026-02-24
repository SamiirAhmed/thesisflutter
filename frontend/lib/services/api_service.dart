import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API service for the University Student Appeal & Complaint System.
///
/// All API calls go through this class.
/// Base URL:
///   - Android emulator  → http://10.0.2.2:8000
///   - Real device       → http://YOUR_PC_IP:8000  (change [_baseUrl] only)
class ApiService {
  static String _currentBaseUrl = 'http://10.0.2.2:8000';
  static const String _fallbackBaseUrl = 'http://127.0.0.1:8000';
  static const String _keyBaseUrl = 'api_base_url';

  /// Returns the effective base URL (either from storage or hardcoded default).
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyBaseUrl);
    if (stored != null && stored.isNotEmpty) {
      _currentBaseUrl = stored;
    }
    return _currentBaseUrl;
  }

  /// Updates and persists a new base URL.
  static Future<void> setBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, newUrl.trim());
    _currentBaseUrl = newUrl.trim();
  }

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const String _keyToken = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyUserId = 'auth_user_id';

  // ─────────────────────────────────────────────────────────────────────────
  // Auth
  // ─────────────────────────────────────────────────────────────────────────

  /// Login via POST /api_login.php.
  /// Automatically tries multiple local URLs if the primary one fails.
  static Future<Map<String, dynamic>> login(String userId, String pin) async {
    final primaryUrl = await getBaseUrl();

    // List of potential local server addresses to try (Self-healing)
    final candidateUrls = [
      'http://10.241.250.3:8000', // 1. Current PC IP (Prioritized for speed)
      primaryUrl, // 2. Last working URL
      'http://10.0.2.2:8000', // 3. Android Emulator
      'http://127.0.0.1:8000', // 4. Localhost
      _fallbackBaseUrl, // 5. Fallback
    ];

    // Remove duplicates to avoid redundant calls
    final uniqueUrls = candidateUrls.toSet().toList();

    Map<String, dynamic> lastResult = {
      'success': false,
      'message': 'Unable to connect to server.',
    };

    for (String url in uniqueUrls) {
      if (url.isEmpty) continue;

      final result = await _doLogin(url, userId, pin);
      if (result['success'] == true) {
        // SUCCESS! Save this working URL as the primary for future sessions
        if (url != primaryUrl) {
          await setBaseUrl(url);
        }
        return result;
      }
      lastResult = result;
    }

    return lastResult;
  }

  /// Private helper for the actual HTTP call
  static Future<Map<String, dynamic>> _doLogin(
    String url,
    String userId,
    String pin,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$url/api/v1/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'user_id': userId.trim(),
              'pin': pin,
              'channel': 'APP',
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Slightly longer timeout for Laravel

      // Guard: some PHP errors return HTML
      if (response.body.trim().startsWith('<')) {
        return {
          'success': false,
          'message': 'Server error. Please contact the administrator.',
        };
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && decoded['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, decoded['token'] ?? '');
        // Store user_id specifically for the profile API
        await prefs.setString(
          _keyUserId,
          decoded['data']['user_id'].toString(),
        );
        // Store only the `data` object — that is the user payload
        await prefs.setString(_keyUserData, jsonEncode(decoded['data']));
        return {'success': true, 'data': decoded};
      }

      return {
        'success': false,
        'message': decoded['message'] ?? 'Login failed. Please try again.',
      };
    } on Exception catch (e) {
      final message = e.toString();
      return {
        'success': false,
        'isConnectionError': true,
        'message': 'Connection error. Check your internet or server.\n$message',
      };
    }
  }

  /// Logout - locally clears storage
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch the full user profile. Routes to api_student.php or api_teacher.php based on role.
  static Future<Map<String, dynamic>> fetchMe() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Not logged in.'};
      }

      final userData = await getLocalUserData();
      if (userData == null) {
        return {'success': false, 'message': 'User role not found.'};
      }

      final baseUrl = await getBaseUrl();
      final headers = await _authHeaders(token);
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/me'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.body.trim().startsWith('<')) {
        return {'success': false, 'message': 'Profile service unavailable.'};
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && decoded['success'] == true) {
        return {'success': true, 'profile': decoded['profile']};
      }

      return {
        'success': false,
        'message': decoded['message'] ?? 'Failed to load profile.',
      };
    } on Exception catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Exam Appeal
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch student subjects for the current semester.
  static Future<Map<String, dynamic>> getExamSubjects() async {
    try {
      final token = await _getToken();
      final baseUrl = await getBaseUrl();
      final headers = await _authHeaders(token ?? '');

      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/exam/subjects'), headers: headers)
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Submit an exam appeal.
  static Future<Map<String, dynamic>> submitExamAppeal(
    List<Map<String, dynamic>> selectedSubjects,
  ) async {
    try {
      final token = await _getToken();
      final baseUrl = await getBaseUrl();
      final headers = await _authHeaders(token ?? '');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/exam/submit'),
            headers: headers,
            body: jsonEncode({'selected_subjects': selectedSubjects}),
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Track appeal status by reference number.
  static Future<Map<String, dynamic>> trackExamAppeal(
    String referenceNo,
  ) async {
    try {
      final token = await _getToken();
      final baseUrl = await getBaseUrl();
      final headers = await _authHeaders(token ?? '');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/exam/track?reference_no=$referenceNo'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Local storage helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns locally cached user data (saved at login time).
  static Future<Map<String, dynamic>?> getLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyUserData);
    if (stored == null) return null;
    return jsonDecode(stored) as Map<String, dynamic>;
  }

  /// Returns true if there is a non-empty token stored locally.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<Map<String, String>> _authHeaders(String token) async {
    final userId = await _getUserId();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'X-USER-ID': userId ?? '',
    };
  }

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }
}
