class ManagerMetricsModel {
  final int assignedEmployees;
  final int pendingEvaluations;
  final int submittedEvaluations;
  final String activeReviewCycleTitle;

  ManagerMetricsModel({
    required this.assignedEmployees,
    required this.pendingEvaluations,
    required this.submittedEvaluations,
    required this.activeReviewCycleTitle,
  });

  factory ManagerMetricsModel.fromJson(Map<String, dynamic> json) {
    return ManagerMetricsModel(
      assignedEmployees: json['assignedEmployees'] as int? ?? 0,
      pendingEvaluations: json['pendingEvaluations'] as int? ?? 0,
      submittedEvaluations: json['submittedEvaluations'] as int? ?? 0,
      activeReviewCycleTitle: json['activeReviewCycleTitle'] as String? ?? 'No Active Cycle',
    );
  }
}
