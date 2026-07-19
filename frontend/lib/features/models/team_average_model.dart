class TeamAverageModel {
  final double averagePerformance;
  final double averagePotential;
  final int numberOfEmployeesEvaluated;

  TeamAverageModel({
    required this.averagePerformance,
    required this.averagePotential,
    required this.numberOfEmployeesEvaluated,
  });

  factory TeamAverageModel.fromJson(Map<String, dynamic> json) {
    return TeamAverageModel(
      averagePerformance: (json['averagePerformance'] as num? ?? 0.0).toDouble(),
      averagePotential: (json['averagePotential'] as num? ?? 0.0).toDouble(),
      numberOfEmployeesEvaluated: json['numberOfEmployeesEvaluated'] as int? ?? 0,
    );
  }
}
