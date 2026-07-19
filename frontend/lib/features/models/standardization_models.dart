class CompanySummaryModel {
  final double companyAveragePerformance;
  final double companyAveragePotential;
  final int totalManagers;
  final int managersRequiringCalibration;
  final double evaluationCompletionRate;
  final double overallStandardizationScore;

  CompanySummaryModel({
    required this.companyAveragePerformance,
    required this.companyAveragePotential,
    required this.totalManagers,
    required this.managersRequiringCalibration,
    required this.evaluationCompletionRate,
    required this.overallStandardizationScore,
  });

  factory CompanySummaryModel.fromJson(Map<String, dynamic> json) {
    return CompanySummaryModel(
      companyAveragePerformance: (json['companyAveragePerformance'] as num? ?? 0.0).toDouble(),
      companyAveragePotential: (json['companyAveragePotential'] as num? ?? 0.0).toDouble(),
      totalManagers: json['totalManagers'] as int? ?? 0,
      managersRequiringCalibration: json['managersRequiringCalibration'] as int? ?? 0,
      evaluationCompletionRate: (json['evaluationCompletionRate'] as num? ?? 0.0).toDouble(),
      overallStandardizationScore: (json['overallStandardizationScore'] as num? ?? 0.0).toDouble(),
    );
  }
}

class ManagerCalibrationModel {
  final String managerName;
  final String department;
  final int employeesEvaluated;
  final double averagePerformanceRating;
  final double averagePotentialRating;
  final double differenceFromCompanyAverage;
  final String calibrationStatus;
  final String consistencyStatus;
  final int standardizationScore;
  final String scoreStatus;
  final Map<int, double> ratingDistribution;

  ManagerCalibrationModel({
    required this.managerName,
    required this.department,
    required this.employeesEvaluated,
    required this.averagePerformanceRating,
    required this.averagePotentialRating,
    required this.differenceFromCompanyAverage,
    required this.calibrationStatus,
    required this.consistencyStatus,
    required this.standardizationScore,
    required this.scoreStatus,
    required this.ratingDistribution,
  });

  factory ManagerCalibrationModel.fromJson(Map<String, dynamic> json) {
    final Map<int, double> distribution = {};
    final rawDist = json['ratingDistribution'] as Map<String, dynamic>? ?? {};
    rawDist.forEach((key, val) {
      final parsedKey = int.tryParse(key) ?? 0;
      if (parsedKey > 0) {
        distribution[parsedKey] = (val as num? ?? 0.0).toDouble();
      }
    });

    return ManagerCalibrationModel(
      managerName: json['managerName'] as String? ?? 'N/A',
      department: json['department'] as String? ?? 'N/A',
      employeesEvaluated: json['employeesEvaluated'] as int? ?? 0,
      averagePerformanceRating: (json['averagePerformanceRating'] as num? ?? 0.0).toDouble(),
      averagePotentialRating: (json['averagePotentialRating'] as num? ?? 0.0).toDouble(),
      differenceFromCompanyAverage: (json['differenceFromCompanyAverage'] as num? ?? 0.0).toDouble(),
      calibrationStatus: json['calibrationStatus'] as String? ?? 'Balanced',
      consistencyStatus: json['consistencyStatus'] as String? ?? 'Healthy Distribution',
      standardizationScore: json['standardizationScore'] as int? ?? 100,
      scoreStatus: json['scoreStatus'] as String? ?? 'Excellent',
      ratingDistribution: distribution,
    );
  }
}

class DepartmentSummaryModel {
  final String departmentName;
  final double averagePerformance;
  final double averagePotential;
  final double completionRate;
  final int employeesEvaluated;

  DepartmentSummaryModel({
    required this.departmentName,
    required this.averagePerformance,
    required this.averagePotential,
    required this.completionRate,
    required this.employeesEvaluated,
  });

  factory DepartmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return DepartmentSummaryModel(
      departmentName: json['departmentName'] as String? ?? 'N/A',
      averagePerformance: (json['averagePerformance'] as num? ?? 0.0).toDouble(),
      averagePotential: (json['averagePotential'] as num? ?? 0.0).toDouble(),
      completionRate: (json['completionRate'] as num? ?? 0.0).toDouble(),
      employeesEvaluated: json['employeesEvaluated'] as int? ?? 0,
    );
  }
}
