import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

import '../../features/models/user_model.dart';
import '../../features/models/metrics_model.dart';
import '../../features/models/review_cycle_model.dart';
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

  /// Performs a health check request to the backend.
  /// Returns `true` if backend returns 200 OK and status "Backend Running".
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

  /// Authenticates user credentials. Returns [UserModel] or throws an exception on failure.
  Future<UserModel> login(String email, String password) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/login');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(body);
    } else if (response.statusCode == 401) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['message'] ?? 'Invalid email or password');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Invalid email or password');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// Retrieves CEO overview dashboard metrics counters.
  Future<MetricsModel> getCeoMetrics() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/ceo/metrics');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return MetricsModel.fromJson(body);
    } else {
      throw Exception('Failed to load metrics');
    }
  }

  /// Retrieves employee users list.
  Future<List<UserModel>> getEmployees() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/employees');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load employees');
    }
  }

  /// Retrieves manager users list.
  Future<List<UserModel>> getManagers() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/managers');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load managers');
    }
  }

  /// Retrieves all review cycles list.
  Future<List<ReviewCycleModel>> getReviewCycles() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/review-cycles');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => ReviewCycleModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load review cycles');
    }
  }

  /// Submits and registers a new Review Cycle.
  Future<ReviewCycleModel> createReviewCycle({
    required String title,
    required String description,
    required String startDate,
    required String endDate,
    required String status,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/review-cycles');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ReviewCycleModel.fromJson(body);
    } else {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['message'] ?? 'Failed to create review cycle');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to create review cycle');
      }
    }
  }

  /// Retrieves all submitted evaluations.
  Future<List<EvaluationModel>> getEvaluations() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/evaluations');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => EvaluationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load evaluations');
    }
  }

  /// Retrieves Manager overview dashboard metrics counters.
  Future<ManagerMetricsModel> getManagerMetrics(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/manager/$managerId/metrics');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ManagerMetricsModel.fromJson(body);
    } else {
      throw Exception('Failed to load manager metrics');
    }
  }

  /// Retrieves employee reports list for a manager.
  Future<List<TeamEmployeeModel>> getManagerEmployees(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/manager/$managerId/employees');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => TeamEmployeeModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load team list');
    }
  }

  /// Retrieves evaluations submitted by a manager.
  Future<List<EvaluationModel>> getManagerEvaluations(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/manager/$managerId/evaluations');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => EvaluationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load submitted reviews');
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
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
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
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return EvaluationModel.fromJson(body);
    } else {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['message'] ?? 'Unable to Submit Evaluation');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Unable to Submit Evaluation');
      }
    }
  }

  /// Retrieves employee user profile details.
  Future<UserModel> getEmployeeProfile(int employeeId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/employees/$employeeId/profile');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(body);
    } else {
      throw Exception('Failed to load employee profile');
    }
  }

  /// Retrieves evaluations specifically belonging to the employee.
  Future<List<EvaluationModel>> getEmployeeEvaluations(int employeeId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/employees/$employeeId/evaluations');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => EvaluationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Unable to Load Evaluations');
    }
  }

  /// Retrieves CEO overview dashboard talent matrix points.
  Future<List<TalentMatrixModel>> getTalentMatrix() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/talent-matrix');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => TalentMatrixModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load talent matrix');
    }
  }

  /// Retrieves Team average performance and potential ratings for manager evaluation workspace.
  Future<TeamAverageModel> getTeamAverage(int managerId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/team-average/$managerId');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return TeamAverageModel.fromJson(body);
    } else {
      throw Exception('Failed to load team average insights');
    }
  }

  /// Retrieves employee competency radar data points across review cycles.
  Future<List<RadarDataModel>> getEmployeePerformanceRadar(int employeeId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/employees/$employeeId/performance-radar');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => RadarDataModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load employee competency radar data');
    }
  }

  /// Retrieves company-wide performance calibration summary.
  Future<CompanySummaryModel> getCompanySummary() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/company-summary');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return CompanySummaryModel.fromJson(body);
    } else {
      throw Exception('Failed to load company calibration summary');
    }
  }

  /// Retrieves all managers calibration statistics.
  Future<List<ManagerCalibrationModel>> getManagerCalibration() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/manager-calibration');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => ManagerCalibrationModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load manager calibration statistics');
    }
  }

  /// Retrieves department performance summary metrics.
  Future<List<DepartmentSummaryModel>> getDepartmentSummary() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/department-summary');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((item) => DepartmentSummaryModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load department summaries');
    }
  }

  /// Retrieves executive observations and insights generated from evaluation calibrations.
  Future<List<String>> getExecutiveInsights() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/analytics/executive-insights');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return List<String>.from(list);
    } else {
      throw Exception('Failed to load executive insights');
    }
  }
}
