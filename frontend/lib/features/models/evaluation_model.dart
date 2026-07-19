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
  final int? communicationScore;
  final int? technicalSkillScore;
  final int? problemSolvingScore;
  final int? leadershipScore;
  final int? teamworkScore;
  final int? adaptabilityScore;
  final int? customerFocusScore;
  final int? innovationScore;
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
    this.communicationScore,
    this.technicalSkillScore,
    this.problemSolvingScore,
    this.leadershipScore,
    this.teamworkScore,
    this.adaptabilityScore,
    this.customerFocusScore,
    this.innovationScore,
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
      communicationScore: json['communicationScore'] as int?,
      technicalSkillScore: json['technicalSkillScore'] as int?,
      problemSolvingScore: json['problemSolvingScore'] as int?,
      leadershipScore: json['leadershipScore'] as int?,
      teamworkScore: json['teamworkScore'] as int?,
      adaptabilityScore: json['adaptabilityScore'] as int?,
      customerFocusScore: json['customerFocusScore'] as int?,
      innovationScore: json['innovationScore'] as int?,
      managerComments: json['managerComments'] as String?,
      submittedDate: json['submittedDate'] as String,
    );
  }
}
