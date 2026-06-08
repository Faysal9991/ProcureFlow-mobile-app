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
    );
  }

  final String accessToken;
  final String userId;
  final String userName;
  final String email;
  final String companyId;
  final String companyName;
  final List<String> roles;

  String get primaryRole => roles.isEmpty ? 'employee' : roles.first;

  bool get canApprove => roles.contains('manager');

  bool get canCreatePurchaseOrder => roles.contains('procurement');

  bool get canTrackFinance => roles.contains('finance');

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'userId': userId,
    'userName': userName,
    'email': email,
    'companyId': companyId,
    'companyName': companyName,
    'roles': roles,
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
  ];
}
