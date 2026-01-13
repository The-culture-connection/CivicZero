import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/models/government_model.dart';

/// Proposal Service - Manages proposals lifecycle
/// CRITICAL: All governance changes must go through proposals!
class ProposalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new proposal (UID-based authority!)
  Future<String> createProposal({
    required String governmentId,
    required String creatorUid,
    required String creatorUsername,
    required String type,
    String? category,
    required String title,
    required String rationale,
    required List<ProposalChange> changes,
    required Map<String, dynamic> sopSnapshot,
    int voteDurationHours = 48,
  }) async {
    try {
      final proposal = ProposalModel(
        id: '',
        governmentId: governmentId,
        type: type,
        category: category,
        status: 'submitted',
        createdBy: creatorUid, // UID = AUTHORITY
        creatorUsername: creatorUsername, // Username = DISPLAY
        createdAt: DateTime.now(),
        title: title,
        rationale: rationale,
        changes: changes,
        sopSnapshot: sopSnapshot,
        voteDurationHours: voteDurationHours,
      );

      final docRef = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .add(proposal.toJson());

      return docRef.id;
    } catch (e) {
      throw 'Failed to create proposal: $e';
    }
  }

  /// Get all proposals for a government
  Stream<List<ProposalModel>> getProposals(String governmentId) {
    return _firestore
        .collection('Governments')
        .doc(governmentId)
        .collection('proposals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProposalModel.fromJson(data);
      }).toList();
    });
  }

  /// Get proposals by status
  Stream<List<ProposalModel>> getProposalsByStatus(String governmentId, String status) {
    return _firestore
        .collection('Governments')
        .doc(governmentId)
        .collection('proposals')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProposalModel.fromJson(data);
      }).toList();
    });
  }

  /// Validate governance change proposal before execution
  Future<ValidationResult> validateGovernanceChange({
    required GovernmentModel government,
    required ProposalModel proposal,
  }) async {
    final errors = <String>[];

    for (final change in proposal.changes) {
      // Rule 1: enabledRoles gates everything
      if (change.path.startsWith('rolePowers.')) {
        final role = change.path.split('.')[1];
        if (!government.enabledRoles.contains(role)) {
          errors.add('Cannot modify powers for disabled role: $role');
        }
      }

      // Rule 2: votingBody must be satisfiable
      if (change.path == 'enabledRoles' && change.op == 'remove') {
        final roleToRemove = change.value as String;
        if (roleToRemove == 'voter') {
          // Check if any SOP requires eligible_voters
          final hasVoterDependency = government.lawmakingSOP.values
              .any((sop) => sop['votingBody'] == 'eligible_voters');
          if (hasVoterDependency) {
            errors.add('Cannot disable voter role - required by voting procedures');
          }
        }
      }

      // Rule 3: beElected requires election mechanism
      if (change.path.endsWith('.beElected') && change.value == true) {
        if (!government.proposalTypes.contains('election') && 
            !government.proposalTypes.contains('appointment')) {
          errors.add('beElected=true requires election or appointment proposal types');
        }
      }

      // Rule 4: editDocs "direct" is constitutional power
      if (change.path.endsWith('.editDocs') && change.value == 'direct') {
        // This is OK but should be logged as high-impact change
        // In production, require supermajority for this
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Execute a passed governance change proposal
  Future<void> executeGovernanceChange({
    required String governmentId,
    required String proposalId,
    required String executorUid,
  }) async {
    try {
      final proposalDoc = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .doc(proposalId)
          .get();

      if (!proposalDoc.exists) {
        throw 'Proposal not found';
      }

      final proposal = ProposalModel.fromJson({
        ...proposalDoc.data()!,
        'id': proposalDoc.id,
      });

      if (proposal.status != 'passed') {
        throw 'Can only execute passed proposals';
      }

      // Get government
      final govDoc = await _firestore.collection('Governments').doc(governmentId).get();
      if (!govDoc.exists) throw 'Government not found';

      final govData = govDoc.data()!;
      final government = GovernmentModel.fromJson({...govData, 'id': governmentId});

      // Validate changes
      final validation = await validateGovernanceChange(
        government: government,
        proposal: proposal,
      );

      if (!validation.isValid) {
        throw 'Validation failed: ${validation.errors.join(', ')}';
      }

      // Apply changes atomically
      final updates = <String, dynamic>{};
      for (final change in proposal.changes) {
        switch (change.op) {
          case 'set':
            updates[change.path] = change.value;
            break;
          case 'remove':
            // Firestore doesn't support nested deletes easily
            // Store null or use FieldValue.delete()
            updates[change.path] = FieldValue.delete();
            break;
          case 'add':
            if (change.path.endsWith('Roles') || change.path.endsWith('Types')) {
              updates[change.path] = FieldValue.arrayUnion([change.value]);
            }
            break;
        }
      }

      // Update government document
      await _firestore.collection('Governments').doc(governmentId).update(updates);

      // Mark proposal as executed
      await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .doc(proposalId)
          .update({
        'status': 'executed',
        'executedAt': FieldValue.serverTimestamp(),
        'executedBy': executorUid,
      });

      // Create audit event
      await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('auditLog')
          .add({
        'type': 'governance_change_executed',
        'proposalId': proposalId,
        'executedBy': executorUid,
        'timestamp': FieldValue.serverTimestamp(),
        'changes': proposal.changes.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      throw 'Failed to execute proposal: $e';
    }
  }

  /// Update proposal status (e.g., submit, start voting, etc.)
  Future<void> updateStatus(String governmentId, String proposalId, String newStatus) async {
    await _firestore
        .collection('Governments')
        .doc(governmentId)
        .collection('proposals')
        .doc(proposalId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Start voting on a proposal (auto-push to voting)
  Future<void> startVoting(String governmentId, String proposalId, int durationHours) async {
    final now = DateTime.now();
    // If durationHours is 0, use 30 seconds for testing
    final votingEnds = durationHours == 0 
        ? now.add(const Duration(seconds: 30))
        : now.add(Duration(hours: durationHours));
    
    await _firestore
        .collection('Governments')
        .doc(governmentId)
        .collection('proposals')
        .doc(proposalId)
        .update({
      'status': 'voting',
      'votingStarted': Timestamp.fromDate(now),
      'votingEnds': Timestamp.fromDate(votingEnds),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cast vote on proposal (UID-based!)
  Future<void> castVote({
    required String governmentId,
    required String proposalId,
    required String voterUid,
    required String voterUsername,
    required String choice, // 'for', 'against', 'abstain'
  }) async {
    try {
      // Create vote document (UID = AUTHORITY)
      await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .doc(proposalId)
          .collection('votes')
          .doc(voterUid) // Keyed by UID to prevent double voting!
          .set({
        'voterUid': voterUid, // AUTHORITY
        'voterUsername': voterUsername, // DISPLAY
        'choice': choice,
        'castAt': FieldValue.serverTimestamp(),
      });

      // Update vote counts
      final increment = FieldValue.increment(1);
      final field = choice == 'for' ? 'votesFor' : 
                    choice == 'against' ? 'votesAgainst' : 'votesAbstain';
      
      await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .doc(proposalId)
          .update({field: increment});

      // Check if vote should close and tally results
      await _checkAndTallyVote(governmentId, proposalId);
    } catch (e) {
      throw 'Failed to cast vote: $e';
    }
  }

  /// Check if voting is complete and tally results
  Future<void> _checkAndTallyVote(String governmentId, String proposalId) async {
    try {
      final proposalDoc = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .doc(proposalId)
          .get();

      if (!proposalDoc.exists) return;

      final proposal = ProposalModel.fromJson({
        ...proposalDoc.data()!,
        'id': proposalDoc.id,
      });

      // Check if voting period ended
      if (proposal.votingEnds != null && DateTime.now().isAfter(proposal.votingEnds!)) {
        await _tallyAndExecute(governmentId, proposal);
      }
    } catch (e) {
      // Silent fail for now
    }
  }

  /// Tally votes and determine if proposal passed
  Future<void> _tallyAndExecute(String governmentId, ProposalModel proposal) async {
    if (proposal.status != 'voting') return;

    final totalVotes = proposal.votesFor + proposal.votesAgainst + proposal.votesAbstain;
    if (totalVotes == 0) {
      // No votes, reject
      await updateStatus(governmentId, proposal.id, 'rejected');
      return;
    }

    // Calculate if threshold met based on SOP
    final threshold = proposal.sopSnapshot['threshold'] as String? ?? 'simple_majority';
    final votesFor = proposal.votesFor;
    final votesAgainst = proposal.votesAgainst;
    
    bool passed = false;
    switch (threshold) {
      case 'simple_majority':
        passed = votesFor > votesAgainst;
        break;
      case 'supermajority_66':
        passed = totalVotes > 0 && (votesFor / totalVotes) >= 0.66;
        break;
      case 'supermajority_75':
        passed = totalVotes > 0 && (votesFor / totalVotes) >= 0.75;
        break;
      case 'consensus':
        passed = votesAgainst == 0 && votesFor > 0;
        break;
      case 'quorum_majority':
        // Simple implementation: requires majority
        passed = votesFor > votesAgainst;
        break;
      default:
        passed = votesFor > votesAgainst;
    }

    if (passed) {
      await updateStatus(governmentId, proposal.id, 'passed');
      // Auto-execute governance changes
      if (proposal.type == 'governance_change' || proposal.changes.isNotEmpty) {
        await executeGovernanceChange(
          governmentId: governmentId,
          proposalId: proposal.id,
          executorUid: 'system', // System auto-execution
        );
      } else {
        await updateStatus(governmentId, proposal.id, 'executed');
      }
    } else {
      await updateStatus(governmentId, proposal.id, 'rejected');
    }
  }

  /// Check voting status on all active proposals (background job)
  Future<void> checkVotingDeadlines(String governmentId) async {
    try {
      final snapshot = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .where('status', isEqualTo: 'voting')
          .get();

      final now = DateTime.now();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final votingEnds = data['votingEnds'] as Timestamp?;
        
        if (votingEnds != null && now.isAfter(votingEnds.toDate())) {
          final proposal = ProposalModel.fromJson({...data, 'id': doc.id});
          await _tallyAndExecute(governmentId, proposal);
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get pending proposals for a specific section/category
  Future<int> getPendingProposalsForSection(String governmentId, String section) async {
    try {
      final snapshot = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .where('category', isEqualTo: section)
          .where('status', whereIn: ['submitted', 'debating', 'voting'])
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user has voted (UID-based!)
  Future<bool> hasVoted(String governmentId, String proposalId, String voterUid) async {
    try {
      final voteDoc = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('proposals')
          .doc(proposalId)
          .collection('votes')
          .doc(voterUid) // Check by UID
          .get();
      return voteDoc.exists;
    } catch (e) {
      return false;
    }
  }
}

/// Validation result for governance changes
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}
