class TeamEmployeeModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? department;
  final String reviewStatus; // "PENDING" or "COMPLETED"

  TeamEmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.department,
    required this.reviewStatus,
  });

  factory TeamEmployeeModel.fromJson(Map<String, dynamic> json) {
    return TeamEmployeeModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      department: json['department'] as String?,
      reviewStatus: json['reviewStatus'] as String? ?? 'PENDING',
    );
  }
}
