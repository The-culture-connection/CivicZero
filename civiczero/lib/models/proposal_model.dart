import 'package:cloud_firestore/cloud_firestore.dart';

/// Proposal for changes to government (laws, governance structure, etc.)
/// Stored in: governments/{govId}/proposals/{proposalId}
class ProposalModel {
  final String id;
  final String governmentId;
  final String type; // new_law, amendment, repeal, governance_change, emergency
  final String? category; // For governance_change: roles_and_permissions, structure, etc.
  final String status; // draft, submitted, debating, voting, passed, rejected, executed
  final String createdBy; // UID (AUTHORITY)
  final String creatorUsername; // Username (DISPLAY)
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Proposal content
  final String title;
  final String rationale;
  final List<ProposalChange> changes; // For governance changes
  
  // SOP snapshot (frozen at creation - prevents mid-flight rule changes)
  final Map<String, dynamic> sopSnapshot;
  
  // Voting data
  final int votesFor;
  final int votesAgainst;
  final int votesAbstain;
  final DateTime? votingStarted;
  final DateTime? votingEnds;
  
  // Execution
  final DateTime? executedAt;
  final String? executedBy; // UID
  
  ProposalModel({
    required this.id,
    required this.governmentId,
    required this.type,
    this.category,
    required this.status,
    required this.createdBy,
    required this.creatorUsername,
    required this.createdAt,
    this.updatedAt,
    required this.title,
    required this.rationale,
    required this.changes,
    required this.sopSnapshot,
    this.votesFor = 0,
    this.votesAgainst = 0,
    this.votesAbstain = 0,
    this.votingStarted,
    this.votingEnds,
    this.executedAt,
    this.executedBy,
  });

  factory ProposalModel.fromJson(Map<String, dynamic> json) {
    return ProposalModel(
      id: json['id'] as String,
      governmentId: json['governmentId'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      status: json['status'] as String,
      createdBy: json['createdBy'] as String,
      creatorUsername: json['creatorUsername'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null ? (json['updatedAt'] as Timestamp).toDate() : null,
      title: json['title'] as String,
      rationale: json['rationale'] as String,
      changes: (json['changes'] as List)
          .map((e) => ProposalChange.fromJson(e as Map<String, dynamic>))
          .toList(),
      sopSnapshot: Map<String, dynamic>.from(json['sopSnapshot'] as Map),
      votesFor: json['votesFor'] as int? ?? 0,
      votesAgainst: json['votesAgainst'] as int? ?? 0,
      votesAbstain: json['votesAbstain'] as int? ?? 0,
      votingStarted: json['votingStarted'] != null ? (json['votingStarted'] as Timestamp).toDate() : null,
      votingEnds: json['votingEnds'] != null ? (json['votingEnds'] as Timestamp).toDate() : null,
      executedAt: json['executedAt'] != null ? (json['executedAt'] as Timestamp).toDate() : null,
      executedBy: json['executedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Use local variables to allow null promotion
    final updatedAtValue = updatedAt;
    final votingStartedValue = votingStarted;
    final votingEndsValue = votingEnds;
    final executedAtValue = executedAt;
    
    return {
      'id': id,
      'governmentId': governmentId,
      'type': type,
      'category': category,
      'status': status,
      'createdBy': createdBy,
      'creatorUsername': creatorUsername,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAtValue != null ? Timestamp.fromDate(updatedAtValue) : null,
      'title': title,
      'rationale': rationale,
      'changes': changes.map((e) => e.toJson()).toList(),
      'sopSnapshot': sopSnapshot,
      'votesFor': votesFor,
      'votesAgainst': votesAgainst,
      'votesAbstain': votesAbstain,
      'votingStarted': votingStartedValue != null ? Timestamp.fromDate(votingStartedValue) : null,
      'votingEnds': votingEndsValue != null ? Timestamp.fromDate(votingEndsValue) : null,
      'executedAt': executedAtValue != null ? Timestamp.fromDate(executedAtValue) : null,
      'executedBy': executedBy,
    };
  }
}

/// Individual change in a governance proposal
class ProposalChange {
  final String op; // set, remove, add
  final String path; // e.g., "rolePowers.member.proposeLaws"
  final dynamic value;
  
  ProposalChange({
    required this.op,
    required this.path,
    required this.value,
  });

  factory ProposalChange.fromJson(Map<String, dynamic> json) {
    return ProposalChange(
      op: json['op'] as String,
      path: json['path'] as String,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'op': op,
      'path': path,
      'value': value,
    };
  }
}
