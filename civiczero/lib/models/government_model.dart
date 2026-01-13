import 'package:cloud_firestore/cloud_firestore.dart';

class GovernmentModel {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  
  // Section 0: Scope
  final String scope; // "local", "regional", "national"
  
  // Section 1: Purpose & Preamble
  final List<String> purpose;
  final Map<String, double> principles;
  final String preambleMode;
  final String preambleText;
  
  // Section 2: Rights & Obligations
  final List<String> rightsCategories;
  final List<String> rightsLimits;
  final List<String> citizenObligations;
  
  // Section 3: Structure
  final List<String> branches;
  final String checksAndBalances;
  
  // Section 4: Role System (CONSOLIDATED from Representation & Elections)
  final List<String> enabledRoles;
  final Map<String, Map<String, dynamic>> rolePowers; // role -> {power -> config}
  final Map<String, Map<String, dynamic>> roleTransitions; // from_role -> {to_role -> method}
  final Map<String, String> roleDurations; // role -> duration_type
  
  // Section 5: Lawmaking SOP (ENHANCED)
  final List<String> proposalTypes;
  final Map<String, Map<String, dynamic>> lawmakingSOP; // proposal_type -> {debate, vote, threshold, etc}
  final Map<String, dynamic> forkRules;
  final Map<String, dynamic> simulationTriggers;
  
  // Section 6: Enforcement
  final String enforcementAuthority;
  final List<String> consequenceTypes;
  final String enforcementDiscretion;
  
  // Section 7: Change & Evolution
  final String amendmentDifficulty;
  final List<String> changeTriggers;
  
  // Section 8: Metrics
  final Map<String, double> metrics;
  final List<String> trackedOutcomes;
  
  // NEW: Blueprint Seed
  final String? blueprintSeed;
  
  // NEW: Budget Allocation (must total 100)
  final Map<String, int> budgetWeights;
  
  // NEW: Custom Institutions
  final List<Map<String, dynamic>> customInstitutions;
  
  // NEW: Crisis Stress Test Responses
  final Map<String, String> stressResponses;
  
  // NEW: Participation Culture
  final String participationCulture;
  final String decisionLatency;
  
  // Additional metadata
  final int memberCount; // Performance cache only - truth is in members subcollection

  GovernmentModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.scope,
    required this.purpose,
    required this.principles,
    required this.preambleMode,
    required this.preambleText,
    required this.rightsCategories,
    required this.rightsLimits,
    required this.citizenObligations,
    required this.branches,
    required this.checksAndBalances,
    required this.enabledRoles,
    required this.rolePowers,
    required this.roleTransitions,
    required this.roleDurations,
    required this.proposalTypes,
    required this.lawmakingSOP,
    required this.forkRules,
    required this.simulationTriggers,
    required this.enforcementAuthority,
    required this.consequenceTypes,
    required this.enforcementDiscretion,
    required this.amendmentDifficulty,
    required this.changeTriggers,
    required this.metrics,
    required this.trackedOutcomes,
    this.blueprintSeed,
    required this.budgetWeights,
    required this.customInstitutions,
    required this.stressResponses,
    required this.participationCulture,
    required this.decisionLatency,
    this.memberCount = 1,
  });

  factory GovernmentModel.fromJson(Map<String, dynamic> json) {
    return GovernmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      scope: json['scope'] as String,
      purpose: List<String>.from(json['purpose'] as List),
      principles: Map<String, double>.from(json['principles'] as Map),
      preambleMode: json['preambleMode'] as String,
      preambleText: json['preambleText'] as String,
      rightsCategories: List<String>.from(json['rightsCategories'] as List),
      rightsLimits: List<String>.from(json['rightsLimits'] as List),
      citizenObligations: List<String>.from(json['citizenObligations'] as List),
      branches: List<String>.from(json['branches'] as List),
      checksAndBalances: json['checksAndBalances'] as String,
      enabledRoles: List<String>.from(json['enabledRoles'] as List? ?? ['visitor', 'member']),
      rolePowers: Map<String, Map<String, dynamic>>.from(
        (json['rolePowers'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)))
      ),
      roleTransitions: Map<String, Map<String, dynamic>>.from(
        (json['roleTransitions'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)))
      ),
      roleDurations: Map<String, String>.from(json['roleDurations'] as Map? ?? {}),
      proposalTypes: List<String>.from(json['proposalTypes'] as List? ?? ['new_law']),
      lawmakingSOP: Map<String, Map<String, dynamic>>.from(
        (json['lawmakingSOP'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)))
      ),
      forkRules: Map<String, dynamic>.from(json['forkRules'] as Map? ?? {}),
      simulationTriggers: Map<String, dynamic>.from(json['simulationTriggers'] as Map? ?? {}),
      enforcementAuthority: json['enforcementAuthority'] as String,
      consequenceTypes: List<String>.from(json['consequenceTypes'] as List),
      enforcementDiscretion: json['enforcementDiscretion'] as String,
      amendmentDifficulty: json['amendmentDifficulty'] as String,
      changeTriggers: List<String>.from(json['changeTriggers'] as List),
      metrics: Map<String, double>.from(json['metrics'] as Map),
      trackedOutcomes: List<String>.from(json['trackedOutcomes'] as List),
      blueprintSeed: json['blueprintSeed'] as String?,
      budgetWeights: Map<String, int>.from(json['budgetWeights'] as Map? ?? {}),
      customInstitutions: List<Map<String, dynamic>>.from(json['customInstitutions'] as List? ?? []),
      stressResponses: Map<String, String>.from(json['stressResponses'] as Map? ?? {}),
      participationCulture: json['participationCulture'] as String? ?? 'balanced',
      decisionLatency: json['decisionLatency'] as String? ?? 'medium',
      memberCount: json['memberCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'scope': scope,
      'purpose': purpose,
      'principles': principles,
      'preambleMode': preambleMode,
      'preambleText': preambleText,
      'rightsCategories': rightsCategories,
      'rightsLimits': rightsLimits,
      'citizenObligations': citizenObligations,
      'branches': branches,
      'checksAndBalances': checksAndBalances,
      'enabledRoles': enabledRoles,
      'rolePowers': rolePowers,
      'roleTransitions': roleTransitions,
      'roleDurations': roleDurations,
      'proposalTypes': proposalTypes,
      'lawmakingSOP': lawmakingSOP,
      'forkRules': forkRules,
      'simulationTriggers': simulationTriggers,
      'enforcementAuthority': enforcementAuthority,
      'consequenceTypes': consequenceTypes,
      'enforcementDiscretion': enforcementDiscretion,
      'amendmentDifficulty': amendmentDifficulty,
      'changeTriggers': changeTriggers,
      'metrics': metrics,
      'trackedOutcomes': trackedOutcomes,
      'blueprintSeed': blueprintSeed,
      'budgetWeights': budgetWeights,
      'customInstitutions': customInstitutions,
      'stressResponses': stressResponses,
      'participationCulture': participationCulture,
      'decisionLatency': decisionLatency,
      'memberCount': memberCount,
    };
  }
}
