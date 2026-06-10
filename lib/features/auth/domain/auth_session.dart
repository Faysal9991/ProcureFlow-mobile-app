import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.userName,
    required this.email,
    required this.companyId,
    required this.companyName,
    required this.roles,
    this.departmentName,
    this.permissions = const [],
    this.mustChangePassword = false,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
      departmentName: json['departmentName'] as String?,
      permissions: ((json['permissions'] as List<dynamic>?) ?? const [])
          .cast<String>(),
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }

  final String accessToken;
  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final String companyName;
  final List<String> roles;
  final String? departmentName;
  final List<String> permissions;
  final bool mustChangePassword;

  String get primaryRole => roles.isEmpty ? 'employee' : roles.first;

  bool hasPermission(String permission) =>
      isCompanyAdmin ||
      permissions.contains('*') ||
      permissions.contains(permission);

  bool hasAnyPermission(Iterable<String> permissionsToCheck) {
    if (isCompanyAdmin || permissions.contains('*')) {
      return true;
    }
    return permissionsToCheck.any(permissions.contains);
  }

  bool hasRole(String roleToCheck) {
    final expected = _normalizeRole(roleToCheck);
    return roles.any((role) => _normalizeRole(role) == expected);
  }

  bool hasAnyRole(Iterable<String> rolesToCheck) {
    return rolesToCheck.any(hasRole);
  }

  bool get isCompanyAdmin {
    return hasAnyRole(const ['COMPANY_ADMIN', 'ADMIN']);
  }

  bool get canApprove =>
      hasAnyRole(const [
        'MANAGER',
        'COMPANY_ADMIN',
        'PROCUREMENT',
        'FINANCE',
      ]) ||
      hasPermission('purchase_requests.approve') ||
      hasPermission('approvals.manage');

  bool get canCreatePurchaseOrder =>
      hasRole('PROCUREMENT') ||
      hasPermission('purchase_orders.create') ||
      hasPermission('purchase_orders.manage');

  bool get canTrackFinance =>
      hasRole('FINANCE') ||
      hasPermission('finance.view') ||
      hasPermission('finance.manage');

  String _normalizeRole(String role) {
    return role.trim().toUpperCase().replaceAll('-', '_');
  }

  AuthSession copyWith({
    String? accessToken,
    String? userId,
    String? userName,
    String? email,
    String? companyId,
    String? companyName,
    List<String>? roles,
    String? departmentName,
    List<String>? permissions,
    bool? mustChangePassword,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      roles: roles ?? this.roles,
      departmentName: departmentName ?? this.departmentName,
      permissions: permissions ?? this.permissions,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'userId': userId,
    'userName': userName,
    'email': email,
    'companyId': companyId,
    'companyName': companyName,
    'roles': roles,
    'departmentName': departmentName,
    'permissions': permissions,
    'mustChangePassword': mustChangePassword,
  };

  @override
  List<Object?> get props => [
    accessToken,
    userId,
    userName,
    email,
    companyId,
    companyName,
    roles,
    departmentName,
    permissions,
    mustChangePassword,
  ];
}
