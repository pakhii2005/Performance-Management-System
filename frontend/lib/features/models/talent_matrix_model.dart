class TalentMatrixModel {
  final String employeeName;
  final String department;
  final String managerName;
  final int performanceRating;
  final int potentialRating;
  final String reviewCycle;

  TalentMatrixModel({
    required this.employeeName,
    required this.department,
    required this.managerName,
    required this.performanceRating,
    required this.potentialRating,
    required this.reviewCycle,
  });

  factory TalentMatrixModel.fromJson(Map<String, dynamic> json) {
    return TalentMatrixModel(
      employeeName: json['employeeName'] as String? ?? 'N/A',
      department: json['department'] as String? ?? 'N/A',
      managerName: json['managerName'] as String? ?? 'N/A',
      performanceRating: json['performanceRating'] as int? ?? 1,
      potentialRating: json['potentialRating'] as int? ?? 1,
      reviewCycle: json['reviewCycle'] as String? ?? 'N/A',
    );
  }
}
