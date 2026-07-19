class MetricsModel {
  final int totalEmployees;
  final int totalManagers;
  final int activeReviewCycles;
  final int submittedEvaluations;

  MetricsModel({
    required this.totalEmployees,
    required this.totalManagers,
    required this.activeReviewCycles,
    required this.submittedEvaluations,
  });

  factory MetricsModel.fromJson(Map<String, dynamic> json) {
    return MetricsModel(
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      totalManagers: json['totalManagers'] as int? ?? 0,
      activeReviewCycles: json['activeReviewCycles'] as int? ?? 0,
      submittedEvaluations: json['submittedEvaluations'] as int? ?? 0,
    );
  }
}
