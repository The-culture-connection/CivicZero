import 'package:cloud_firestore/cloud_firestore.dart';

/// Active law in a government
/// Stored in: governments/{govId}/laws/{lawId}
class LawModel {
  final String id;
  final String governmentId;
  final String proposalId; // Which proposal created this law
  final String title;
  final String summary;
  final String? enforcement;
  final String type; // policy, regulation, resolution, ordinance
  final String status; // active, repealed, amended
  final DateTime enactedAt;
  final String enactedBy; // UID

  LawModel({
    required this.id,
    required this.governmentId,
    required this.proposalId,
    required this.title,
    required this.summary,
    this.enforcement,
    required this.type,
    this.status = 'active',
    required this.enactedAt,
    required this.enactedBy,
  });

  factory LawModel.fromJson(Map<String, dynamic> json) {
    return LawModel(
      id: json['id'] as String,
      governmentId: json['governmentId'] as String,
      proposalId: json['proposalId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      enforcement: json['enforcement'] as String?,
      type: json['type'] as String,
      status: json['status'] as String? ?? 'active',
      enactedAt: (json['enactedAt'] as Timestamp).toDate(),
      enactedBy: json['enactedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'governmentId': governmentId,
      'proposalId': proposalId,
      'title': title,
      'summary': summary,
      'enforcement': enforcement,
      'type': type,
      'status': status,
      'enactedAt': Timestamp.fromDate(enactedAt),
      'enactedBy': enactedBy,
    };
  }
}
