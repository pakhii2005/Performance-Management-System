import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../main.dart'; // To access global navigatorKey
import 'auth_storage.dart';

import '../../features/models/user_model.dart';
import '../../features/models/metrics_model.dart';
import '../../features/models/review_cycle_model.dart';
import '../../features/models/review_cycle_details_model.dart';
import '../../features/models/evaluation_model.dart';
import '../../features/models/manager_metrics_model.dart';
import '../../features/models/team_employee_model.dart';
import '../../features/models/talent_matrix_model.dart';
import '../../features/models/team_average_model.dart';
import '../../features/models/radar_data_model.dart';
import '../../features/models/standardization_models.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Performs health check (public endpoint).
  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthCheckEndpoint}');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['status'] == 'Backend Running';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends a request with auth verification, automatic header insertion,
  /// automatic token expiry checking/refreshing, and retry support on 401.
  Future<http.Response> _sendRequest(String method, Uri uri, {Map<String, String>? headers, dynamic body}) async {
    headers ??= {};
    headers['Content-Type'] = 'application/json';

    // 1. Check if token is expired and refresh if necessary
    final hasRefreshToken = await AuthStorage.getRefreshToken() != null;
    if (hasRefreshToken) {
      final isExpired = await AuthStorage.isTokenExpired();
      if (isExpired) {
        final success = await _refreshTokenFlow();
        if (!success) {
          await _handleLogoutAndRedirect();
          throw Exception('Session expired. Please log in again.');
        }
      }
    }

    // 2. Attach Authorization token
    final token = await AuthStorage.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    final reqBody = body != null ? jsonEncode(body) : null;

    try {
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      } else if (method == 'POST') {
        response = await _client.post(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 10));
      } else if (method == 'PUT') {
        response = await _client.put(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 10));
      } else if (method == 'DELETE') {
        response = await _client.delete(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 10));
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }

    // 3. Retry on 401 if a refresh succeeds
    if (response.statusCode == 401 && hasRefreshToken) {
      final success = await _refreshTokenFlow();
      if (success) {
        final newToken = await AuthStorage.getAccessToken();
        if (newToken != null) {
          headers['Authorization'] = 'Bearer $newToken';
        }
        try {
          if (method == 'GET') {
            response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10));
          } else if (method == 'POST') {
            response = await _client.post(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 10));
          } else if (method == 'PUT') {
            response = await _client.put(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 10));
          } else if (method == 'DELETE') {
            response = await _client.delete(uri, headers: headers, body: reqBody).timeout(const Duration(seconds: 10));
          }
        } catch (e) {
          throw Exception('Connection retry failed: $e');
        }
      } else {
        await _handleLogoutAndRedirect();
        throw Exception('Session expired. Please log in again.');
      }
    }

    // 4. Handle 403 Forbidden
    if (response.statusCode == 403) {
      throw Exception('Access denied. You do not have permission to view or perform this action.');
    }

    return response;
  }

  /// Flow to contact the refresh token endpoint and save new access credentials.
  Future<bool> _refreshTokenFlow() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/refresh');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = body['accessToken'] as String? ?? '';
        final newRefreshToken = body['refreshToken'] as String? ?? '';
        final expiresIn = body['expiresIn'] as int? ?? 3600;
        
        await AuthStorage.saveAccessToken(newAccessToken, expiresIn);
        // Refresh token might be updated as well
        await AuthStorage.saveSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          expiresInSeconds: expiresIn,
          user: (await AuthStorage.getUser())!,
        );
        return true;
      }
    } catch (_) {
      // Return false on refresh errors
    }
    return false;
  }

  /// Clears user credentials and forces navigation to the Login Screen.
  Future<void> _handleLogoutAndRedirect() async {
    await AuthStorage.clearSession();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  /// Extracts error message fields from server response.
  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] ?? 'An unexpected error occurred';
    } catch (_) {
      return 'Server error: ${response.statusCode}';
    }
  }

  /// Authenticates user credentials. Returns [UserModel] or throws on failure.
  Future<UserModel> login(String email, String password) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final user = UserModel.fromJson(body);
      final accessToken = body['accessToken'] as String? ?? '';
      final refreshToken = body['refreshToken'] as String? ?? '';
      final expiresIn = body['expiresIn'] as int? ?? 3600;

      await AuthStorage.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresInSeconds: expiresIn,
        user: user,
      );
      return user;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Register a new user (CEO only).
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String department,
    required String role,
    int? managerId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/register');
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'department': department,
      'role': role,
      if (managerId != null) 'managerId': managerId,
    };

    final response = await _sendRequest('POST', uri, body: body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Safely logs out from server and cleans local session storage.
  Future<void> logout() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/logout');
        await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Suppress connection failure during logout
      }
    }
    await AuthStorage.clearSession();
  }

  /// Retrieves CEO overview dashboard metrics counters.
  Future<MetricsModel> getCeoMetrics() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/ceo/metrics');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return MetricsModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves employee users list.
  Future<List<UserModel>> getEmployees() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/employees');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves manager users list.
  Future<List<UserModel>> getManagers() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/managers');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves all review cycles list.
  Future<List<ReviewCycleModel>> getReviewCycles() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/review-cycles');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => ReviewCycleModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Submits and registers a new Review Cycle.
  Future<ReviewCycleModel> createReviewCycle({
    required String title,
    required String description,
    required String startDate,
    required String endDate,
    required String status,
    int? managerId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/review-cycles');
    final body = {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      if (managerId != null) 'managerId': managerId,
    };
    final response = await _sendRequest('POST', uri, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ReviewCycleModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Updates an existing Review Cycle.
  Future<ReviewCycleModel> updateReviewCycle(
    int id, {
    required String title,
    required String description,
    required String startDate,
    required String endDate,
    required String status,
    int? managerId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/review-cycles/$id');
    final body = {
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'managerId': managerId,
    };
    final response = await _sendRequest('PUT', uri, body: body);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ReviewCycleModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves a detailed review cycle with metrics and employee status.
  Future<ReviewCycleDetailsModel> getReviewCycleDetails(int id) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/review-cycles/$id/details');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ReviewCycleDetailsModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves all submitted evaluations.
  Future<List<EvaluationModel>> getEvaluations() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/evaluations');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => EvaluationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves Manager overview dashboard metrics counters.
  Future<ManagerMetricsModel> getManagerMetrics(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/manager/$managerId/metrics');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ManagerMetricsModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves employee reports list for a manager.
  Future<List<TeamEmployeeModel>> getManagerEmployees(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/manager/$managerId/employees');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => TeamEmployeeModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves evaluations submitted by a manager.
  Future<List<EvaluationModel>> getManagerEvaluations(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/manager/$managerId/evaluations');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => EvaluationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Submits employee evaluation.
  Future<EvaluationModel> submitEvaluation({
    required int employeeId,
    required int managerId,
    required int reviewCycleId,
    required int performanceRating,
    required int potentialRating,
    required String managerComments,
    required int communicationScore,
    required int technicalSkillScore,
    required int problemSolvingScore,
    required int leadershipScore,
    required int teamworkScore,
    required int adaptabilityScore,
    required int customerFocusScore,
    required int innovationScore,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/evaluations');
    final body = {
      'employeeId': employeeId,
      'managerId': managerId,
      'reviewCycleId': reviewCycleId,
      'performanceRating': performanceRating,
      'potentialRating': potentialRating,
      'managerComments': managerComments,
      'communicationScore': communicationScore,
      'technicalSkillScore': technicalSkillScore,
      'problemSolvingScore': problemSolvingScore,
      'leadershipScore': leadershipScore,
      'teamworkScore': teamworkScore,
      'adaptabilityScore': adaptabilityScore,
      'customerFocusScore': customerFocusScore,
      'innovationScore': innovationScore,
    };
    final response = await _sendRequest('POST', uri, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return EvaluationModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves employee user profile details.
  Future<UserModel> getEmployeeProfile(int employeeId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/employees/$employeeId/profile');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves evaluations specifically belonging to the employee.
  Future<List<EvaluationModel>> getEmployeeEvaluations(int employeeId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/employees/$employeeId/evaluations');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => EvaluationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves CEO overview dashboard talent matrix points.
  Future<List<TalentMatrixModel>> getTalentMatrix() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/talent-matrix');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => TalentMatrixModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves Team average performance and potential ratings for manager evaluation workspace.
  Future<TeamAverageModel> getTeamAverage(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/team-average/$managerId');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return TeamAverageModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves employee competency radar data points across review cycles.
  Future<List<RadarDataModel>> getEmployeePerformanceRadar(int employeeId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/employees/$employeeId/performance-radar');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => RadarDataModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves company-wide performance calibration summary.
  Future<CompanySummaryModel> getCompanySummary() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/company-summary');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return CompanySummaryModel.fromJson(body);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves all managers calibration statistics.
  Future<List<ManagerCalibrationModel>> getManagerCalibration() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/manager-calibration');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => ManagerCalibrationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves department performance summary metrics.
  Future<List<DepartmentSummaryModel>> getDepartmentSummary() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/department-summary');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => DepartmentSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves executive observations and insights generated from evaluation calibrations.
  Future<List<String>> getExecutiveInsights() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/executive-insights');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return List<String>.from(list);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Retrieves list of users with optional search and filters.
  Future<List<UserModel>> getUsers({String? search, String? role, String? department, bool? enabled}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (department != null && department.isNotEmpty) queryParams['department'] = department;
    if (enabled != null) queryParams['enabled'] = enabled.toString();

    final queryString = Uri(queryParameters: queryParams).query;
    final urlPath = '/api/users${queryString.isNotEmpty ? '?$queryString' : ''}';
    final uri = Uri.parse('${ApiConstants.baseUrl}$urlPath');
    final response = await _sendRequest('GET', uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Create a new user (Manager or Employee).
  Future<UserModel> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    required String department,
    int? managerId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users');
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'role': role,
      'department': department,
      if (managerId != null) 'managerId': managerId,
    };
    final response = await _sendRequest('POST', uri, body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Updates user profile details (CEO only).
  Future<UserModel> updateUser(int id, {
    required String firstName,
    required String lastName,
    required String department,
    int? managerId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$id');
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'department': department,
      'managerId': managerId,
    };
    final response = await _sendRequest('PUT', uri, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Activates a user account (CEO only).
  Future<void> activateUser(int id) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$id/activate');
    final response = await _sendRequest('PATCH', uri);

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Deactivates a user account (CEO only).
  Future<void> deactivateUser(int id) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$id/deactivate');
    final response = await _sendRequest('PATCH', uri);

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Resets a user's password and returns the generated temporary password (CEO only).
  Future<String> resetUserPassword(int id) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$id/reset-password');
    final response = await _sendRequest('PATCH', uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['temporaryPassword'] as String;
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Assigns or reassigns an employee to a manager (CEO only).
  Future<void> assignUserManager(int id, int? managerId) async {
    final urlPath = '/api/users/$id/assign-manager${managerId != null ? '?managerId=$managerId' : ''}';
    final uri = Uri.parse('${ApiConstants.baseUrl}$urlPath');
    final response = await _sendRequest('PATCH', uri);

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Changes the logged-in user's password.
  Future<void> changeUserPassword(String currentPassword, String newPassword, String confirmNewPassword) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/change-password');
    final body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    };
    final response = await _sendRequest('POST', uri, body: body);

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }
}
