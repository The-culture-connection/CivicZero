import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a member in a specific government
/// Stored in: governments/{govId}/members/{uid}
class MemberModel {
  final String uid; // Immutable user ID (AUTHORITY)
  final String username; // Display name (PRESENTATION)
  final List<String> roles; // Current roles in this government
  final DateTime joinedAt;
  final List<RoleHistoryEntry> roleHistory;
  final Map<String, bool> eligibility; // Computed eligibility for roles
  final String status; // active, suspended, banned

  MemberModel({
    required this.uid,
    required this.username,
    required this.roles,
    required this.joinedAt,
    required this.roleHistory,
    required this.eligibility,
    this.status = 'active',
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      uid: json['uid'] as String,
      username: json['username'] as String,
      roles: List<String>.from(json['roles'] as List),
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      roleHistory: (json['roleHistory'] as List)
          .map((e) => RoleHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      eligibility: Map<String, bool>.from(json['eligibility'] as Map),
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'roles': roles,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'roleHistory': roleHistory.map((e) => e.toJson()).toList(),
      'eligibility': eligibility,
      'status': status,
    };
  }

  /// Check if member has a specific role
  bool hasRole(String role) => roles.contains(role);

  /// Check if member can have multiple roles
  bool hasAnyRole(List<String> checkRoles) {
    return checkRoles.any((role) => roles.contains(role));
  }
}

/// Role history entry for audit trail
class RoleHistoryEntry {
  final String role;
  final DateTime assignedAt;
  final String method; // automatic, election, appointment, etc.
  final String? assignedBy; // UID of who assigned (if applicable)

  RoleHistoryEntry({
    required this.role,
    required this.assignedAt,
    required this.method,
    this.assignedBy,
  });

  factory RoleHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RoleHistoryEntry(
      role: json['role'] as String,
      assignedAt: (json['assignedAt'] as Timestamp).toDate(),
      method: json['method'] as String,
      assignedBy: json['assignedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'method': method,
      'assignedBy': assignedBy,
    };
  }
}
