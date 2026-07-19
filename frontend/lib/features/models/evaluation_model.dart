class EvaluationModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final int managerId;
  final String managerName;
  final int reviewCycleId;
  final String reviewCycleTitle;
  final int performanceRating;
  final int potentialRating;
  final String? managerComments;
  final String submittedDate;

  EvaluationModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.managerId,
    required this.managerName,
    required this.reviewCycleId,
    required this.reviewCycleTitle,
    required this.performanceRating,
    required this.potentialRating,
    this.managerComments,
    required this.submittedDate,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: json['id'] as int,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String? ?? 'N/A',
      managerId: json['managerId'] as int,
      managerName: json['managerName'] as String? ?? 'N/A',
      reviewCycleId: json['reviewCycleId'] as int,
      reviewCycleTitle: json['reviewCycleTitle'] as String? ?? 'N/A',
      performanceRating: json['performanceRating'] as int,
      potentialRating: json['potentialRating'] as int,
      managerComments: json['managerComments'] as String?,
      submittedDate: json['submittedDate'] as String,
    );
  }
}
