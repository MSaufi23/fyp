import 'package:flutter/material.dart';

enum ReportStatus {
  pending,
  inProgress,
  resolved,
  rejected,
}

class Report {
  final String id;
  final String reporterUsername;
  final String reporterType; // 'user' or 'business'
  final String content;
  final DateTime timestamp;
  ReportStatus status;
  String? adminResponse;

  Report({
    required this.id,
    required this.reporterUsername,
    required this.reporterType,
    required this.content,
    required this.timestamp,
    this.status =
        ReportStatus.pending,
    this.adminResponse,
  });

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id':
          id,
      'reporterUsername':
          reporterUsername,
      'reporterType':
          reporterType,
      'content':
          content,
      'timestamp':
          timestamp.toIso8601String(),
      'status':
          status.toString(),
      'adminResponse':
          adminResponse,
    };
  }

  factory Report.fromMap(
    Map<
      dynamic,
      dynamic
    >
    map,
  ) {
    return Report(
      id:
          map['id']
              as String,
      reporterUsername:
          map['reporterUsername']
              as String,
      reporterType:
          map['reporterType']
              as String,
      content:
          map['content']
              as String,
      timestamp: DateTime.parse(
        map['timestamp']
            as String,
      ),
      status: ReportStatus.values.firstWhere(
        (
          e,
        ) =>
            e.toString() ==
            map['status'],
        orElse:
            () =>
                ReportStatus.pending,
      ),
      adminResponse:
          map['adminResponse']
              as String?,
    );
  }

  String get statusText {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }
}
