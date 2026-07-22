class ReviewCycleDetailsModel {
  final int id;
  final String title;
  final String? description;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;
  final int? managerId;
  final String? managerName;

  // Statistics
  final int totalEmployees;
  final int reviewsCompleted;
  final int reviewsPending;
  final int selfAssessmentsPending;
  final double completionPercentage;

  // Participating employees status list
  final List<ReviewCycleEmployeeStatusModel> employees;

  ReviewCycleDetailsModel({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    this.managerId,
    this.managerName,
    required this.totalEmployees,
    required this.reviewsCompleted,
    required this.reviewsPending,
    required this.selfAssessmentsPending,
    required this.completionPercentage,
    required this.employees,
  });

  factory ReviewCycleDetailsModel.fromJson(Map<String, dynamic> json) {
    var employeesList = json['employees'] as List<dynamic>? ?? [];
    List<ReviewCycleEmployeeStatusModel> parsedEmployees = employeesList
        .map((item) => ReviewCycleEmployeeStatusModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ReviewCycleDetailsModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      managerId: json['managerId'] as int?,
      managerName: json['managerName'] as String?,
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      reviewsCompleted: json['reviewsCompleted'] as int? ?? 0,
      reviewsPending: json['reviewsPending'] as int? ?? 0,
      selfAssessmentsPending: json['selfAssessmentsPending'] as int? ?? 0,
      completionPercentage: (json['completionPercentage'] as num? ?? 0.0).toDouble(),
      employees: parsedEmployees,
    );
  }
}

class ReviewCycleEmployeeStatusModel {
  final int employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String? department;
  final String reviewStatus;

  ReviewCycleEmployeeStatusModel({
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.department,
    required this.reviewStatus,
  });

  factory ReviewCycleEmployeeStatusModel.fromJson(Map<String, dynamic> json) {
    return ReviewCycleEmployeeStatusModel(
      employeeId: json['employeeId'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      department: json['department'] as String?,
      reviewStatus: json['reviewStatus'] as String? ?? 'Not Started',
    );
  }
}
