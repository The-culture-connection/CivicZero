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
  
  // Section 4: Representation & Elections
  final String representationModel;
  final List<String> votingEligibility;
  final List<String> officeEligibility;
  final String electionMethod;
  final String termLength;
  final bool termLimits;
  
  // Section 5: Lawmaking
  final List<String> lawProposers;
  final String passageRules;
  final List<String> reviewMechanisms;
  
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
  
  // Additional metadata
  final int memberCount;
  final List<String> memberIds;

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
    required this.representationModel,
    required this.votingEligibility,
    required this.officeEligibility,
    required this.electionMethod,
    required this.termLength,
    required this.termLimits,
    required this.lawProposers,
    required this.passageRules,
    required this.reviewMechanisms,
    required this.enforcementAuthority,
    required this.consequenceTypes,
    required this.enforcementDiscretion,
    required this.amendmentDifficulty,
    required this.changeTriggers,
    required this.metrics,
    required this.trackedOutcomes,
    this.memberCount = 1,
    this.memberIds = const [],
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
      representationModel: json['representationModel'] as String,
      votingEligibility: List<String>.from(json['votingEligibility'] as List),
      officeEligibility: List<String>.from(json['officeEligibility'] as List),
      electionMethod: json['electionMethod'] as String,
      termLength: json['termLength'] as String,
      termLimits: json['termLimits'] as bool,
      lawProposers: List<String>.from(json['lawProposers'] as List),
      passageRules: json['passageRules'] as String,
      reviewMechanisms: List<String>.from(json['reviewMechanisms'] as List),
      enforcementAuthority: json['enforcementAuthority'] as String,
      consequenceTypes: List<String>.from(json['consequenceTypes'] as List),
      enforcementDiscretion: json['enforcementDiscretion'] as String,
      amendmentDifficulty: json['amendmentDifficulty'] as String,
      changeTriggers: List<String>.from(json['changeTriggers'] as List),
      metrics: Map<String, double>.from(json['metrics'] as Map),
      trackedOutcomes: List<String>.from(json['trackedOutcomes'] as List),
      memberCount: json['memberCount'] as int? ?? 1,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
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
      'representationModel': representationModel,
      'votingEligibility': votingEligibility,
      'officeEligibility': officeEligibility,
      'electionMethod': electionMethod,
      'termLength': termLength,
      'termLimits': termLimits,
      'lawProposers': lawProposers,
      'passageRules': passageRules,
      'reviewMechanisms': reviewMechanisms,
      'enforcementAuthority': enforcementAuthority,
      'consequenceTypes': consequenceTypes,
      'enforcementDiscretion': enforcementDiscretion,
      'amendmentDifficulty': amendmentDifficulty,
      'changeTriggers': changeTriggers,
      'metrics': metrics,
      'trackedOutcomes': trackedOutcomes,
      'memberCount': memberCount,
      'memberIds': memberIds,
    };
  }
}
