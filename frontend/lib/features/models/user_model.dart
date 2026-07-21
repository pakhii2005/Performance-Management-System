class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? department;
  final String? managerName;
  final int? managerId;
  final int? employeeCount;
  final bool? passwordResetRequired;
  final bool? enabled;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.department,
    this.managerName,
    this.managerId,
    this.employeeCount,
    this.passwordResetRequired,
    this.enabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'EMPLOYEE',
      department: json['department'] as String?,
      managerName: json['managerName'] as String?,
      managerId: json['managerId'] as int? ?? (json['manager'] as Map<String, dynamic>?)?['id'] as int?,
      employeeCount: json['employeeCount'] as int?,
      passwordResetRequired: json['passwordResetRequired'] as bool?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'department': department,
      'managerName': managerName,
      'managerId': managerId,
      'employeeCount': employeeCount,
      'passwordResetRequired': passwordResetRequired,
      'enabled': enabled,
    };
  }
}
