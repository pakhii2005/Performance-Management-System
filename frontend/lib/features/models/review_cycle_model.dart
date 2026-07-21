class ReviewCycleModel {
  final int id;
  final String title;
  final String? description;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;

  ReviewCycleModel({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory ReviewCycleModel.fromJson(Map<String, dynamic> json) {
    return ReviewCycleModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
