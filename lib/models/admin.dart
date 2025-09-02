import 'user.dart';

enum ReportStatus {
  pending,
  inProgress,
  resolved,
  dismissed,
}

class Report {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String title;
  final String description;
  final DateTime createdAt;
  ReportStatus status;
  String? adminResponse;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.title,
    required this.description,
    required this.createdAt,
    this.status =
        ReportStatus.pending,
    this.adminResponse,
  });
}

class AdminUser
    extends
        User {
  final String adminId;
  final List<
    String
  >
  permissions;

  AdminUser({
    required super.username,
    required super.email,
    required super.password,
    required this.adminId,
    this.permissions = const [
      'manage_users',
      'manage_reports',
    ],
  }) : super(
         type:
             UserType.admin,
       );
}
