import 'package:cloud_firestore/cloud_firestore.dart';

/// Version snapshot of government constitution
/// Stored in: governments/{govId}/versions/{versionId}
class GovernmentVersionModel {
  final String id;
  final String governmentId;
  final int versionNumber;
  final DateTime createdAt;
  final String createdBy; // UID
  final String? proposalId; // Which proposal created this version
  
  // Snapshot of constitutional fields
  final Map<String, dynamic> snapshot;
  
  // What changed in this version
  final List<String> changesSummary;

  GovernmentVersionModel({
    required this.id,
    required this.governmentId,
    required this.versionNumber,
    required this.createdAt,
    required this.createdBy,
    this.proposalId,
    required this.snapshot,
    required this.changesSummary,
  });

  factory GovernmentVersionModel.fromJson(Map<String, dynamic> json) {
    return GovernmentVersionModel(
      id: json['id'] as String,
      governmentId: json['governmentId'] as String,
      versionNumber: json['versionNumber'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] as String,
      proposalId: json['proposalId'] as String?,
      snapshot: Map<String, dynamic>.from(json['snapshot'] as Map),
      changesSummary: List<String>.from(json['changesSummary'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'governmentId': governmentId,
      'versionNumber': versionNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'proposalId': proposalId,
      'snapshot': snapshot,
      'changesSummary': changesSummary,
    };
  }
}
