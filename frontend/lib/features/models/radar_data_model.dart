class RadarDataModel {
  final String reviewCycle;
  final int reviewCycleId;
  final Map<String, int> competencyScores;
  final int performanceRating;
  final int potentialRating;
  final String? managerComments;
  final String reviewDate;

  RadarDataModel({
    required this.reviewCycle,
    required this.reviewCycleId,
    required this.competencyScores,
    required this.performanceRating,
    required this.potentialRating,
    this.managerComments,
    required this.reviewDate,
  });

  factory RadarDataModel.fromJson(Map<String, dynamic> json) {
    final scoresMap = Map<String, dynamic>.from(json['competencyScores'] ?? {});
    final Map<String, int> castedScores = {};
    scoresMap.forEach((key, value) {
      castedScores[key] = value as int? ?? 0;
    });

    return RadarDataModel(
      reviewCycle: json['reviewCycle'] as String? ?? 'N/A',
      reviewCycleId: json['reviewCycleId'] as int? ?? 0,
      competencyScores: castedScores,
      performanceRating: json['performanceRating'] as int? ?? 0,
      potentialRating: json['potentialRating'] as int? ?? 0,
      managerComments: json['managerComments'] as String?,
      reviewDate: json['reviewDate'] as String? ?? '',
    );
  }
}
