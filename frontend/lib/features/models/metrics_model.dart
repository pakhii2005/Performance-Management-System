class MetricsModel {
  final int totalEmployees;
  final int totalManagers;
  final int activeReviewCycles;
  final int submittedEvaluations;
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;

  MetricsModel({
    required this.totalEmployees,
    required this.totalManagers,
    required this.activeReviewCycles,
    required this.submittedEvaluations,
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  factory MetricsModel.fromJson(Map<String, dynamic> json) {
    return MetricsModel(
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      totalManagers: json['totalManagers'] as int? ?? 0,
      activeReviewCycles: json['activeReviewCycles'] as int? ?? 0,
      submittedEvaluations: json['submittedEvaluations'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
      activeUsers: json['activeUsers'] as int? ?? 0,
      inactiveUsers: json['inactiveUsers'] as int? ?? 0,
    );
  }
}
