import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/member_model.dart';
import 'package:civiczero/services/role_service.dart';

/// Government Service - Manages governments and membership
/// CRITICAL: Always uses UIDs for authority, usernames for display
class GovernmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService = RoleService();

  // Create a new government with founder as first member
  Future<String> createGovernment(GovernmentModel government, String creatorUid, String creatorUsername) async {
    try {
      // Create government document
      final docRef = await _firestore.collection('Governments').add(government.toJson());
      
      // Create founder member document in subcollection (UID-based authority!)
      await _createMemberDocument(
        governmentId: docRef.id,
        uid: creatorUid,
        username: creatorUsername,
        initialRoles: ['founder', 'member', 'voter', 'contributor'],
        method: 'creator',
      );
      
      return docRef.id;
    } catch (e) {
      throw 'Failed to create government: $e';
    }
  }

  // Create member document in government's members subcollection
  Future<void> _createMemberDocument({
    required String governmentId,
    required String uid,
    required String username,
    required List<String> initialRoles,
    required String method,
  }) async {
    final member = MemberModel(
      uid: uid,
      username: username,
      roles: initialRoles,
      joinedAt: DateTime.now(),
      roleHistory: initialRoles.map((role) => RoleHistoryEntry(
        role: role,
        assignedAt: DateTime.now(),
        method: method,
      )).toList(),
      eligibility: {for (var role in initialRoles) role: true},
      status: 'active',
    );

    await _firestore
        .collection('Governments')
        .doc(governmentId)
        .collection('members')
        .doc(uid) // Key by UID, not username!
        .set(member.toJson());
  }

  // Get all governments (Discovery)
  Stream<List<GovernmentModel>> getAllGovernments() {
    return _firestore
        .collection('Governments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GovernmentModel.fromJson(data);
      }).toList();
    });
  }

  // Get governments user has joined (via members subcollection with UID)
  Stream<List<GovernmentModel>> getJoinedGovernments(String uid) async* {
    // This is a simplified approach - in production, consider a user's governments collection
    // For now, we'll query governments where user is a member
    
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      try {
        final govSnapshot = await _firestore.collection('Governments').get();
        final joinedGovs = <GovernmentModel>[];
        
        for (final govDoc in govSnapshot.docs) {
          // Check if user is a member via subcollection (UID-based!)
          final memberDoc = await _firestore
              .collection('Governments')
              .doc(govDoc.id)
              .collection('members')
              .doc(uid) // Query by UID (AUTHORITY)
              .get();
          
          if (memberDoc.exists && memberDoc.data()?['status'] == 'active') {
            final data = govDoc.data();
            data['id'] = govDoc.id;
            joinedGovs.add(GovernmentModel.fromJson(data));
          }
        }
        
        yield joinedGovs;
      } catch (e) {
        yield [];
      }
    }
  }

  // Get single government by ID
  Future<GovernmentModel?> getGovernment(String governmentId) async {
    try {
      final doc = await _firestore.collection('Governments').doc(governmentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return GovernmentModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch government: $e';
    }
  }

  // Join a government (creates member document with UID as key)
  Future<void> joinGovernment({
    required String governmentId,
    required String uid,
    required String username,
  }) async {
    try {
      // Create member document (UID-based authority!)
      await _createMemberDocument(
        governmentId: governmentId,
        uid: uid,
        username: username,
        initialRoles: ['member'], // Auto-assign member role
        method: 'automatic',
      );
      
      // Increment member count on parent for performance
      await _firestore.collection('Governments').doc(governmentId).update({
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Failed to join government: $e';
    }
  }

  // Leave a government (removes member document)
  Future<void> leaveGovernment(String governmentId, String uid) async {
    try {
      // Delete member document (keyed by UID!)
      await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('members')
          .doc(uid)
          .delete();
      
      // Decrement member count
      await _firestore.collection('Governments').doc(governmentId).update({
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw 'Failed to leave government: $e';
    }
  }

  // Get member data for a user in a government (UID-based!)
  Future<MemberModel?> getMember(String governmentId, String uid) async {
    try {
      final doc = await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('members')
          .doc(uid) // Keyed by UID, not username!
          .get();
      
      if (doc.exists) {
        return MemberModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user is member (UID-based!)
  Future<bool> isMember(String governmentId, String uid) async {
    try {
      final member = await getMember(governmentId, uid);
      return member != null && member.status == 'active';
    } catch (e) {
      return false;
    }
  }

  // Get all members of a government (for display - includes usernames)
  Stream<List<MemberModel>> getMembers(String governmentId) {
    return _firestore
        .collection('Governments')
        .doc(governmentId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MemberModel.fromJson(doc.data());
      }).toList();
    });
  }

  // Assign a role to a member (UID-based authority!)
  Future<void> assignRole({
    required String governmentId,
    required String uid,
    required String role,
    required String method,
    String? assignedBy,
  }) async {
    try {
      final memberRef = _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('members')
          .doc(uid); // UID-based!
      
      final memberDoc = await memberRef.get();
      if (!memberDoc.exists) {
        throw 'User is not a member of this government';
      }
      
      final member = MemberModel.fromJson(memberDoc.data()!);
      
      // Add role if not already present
      if (!member.roles.contains(role)) {
        await memberRef.update({
          'roles': FieldValue.arrayUnion([role]),
          'roleHistory': FieldValue.arrayUnion([
            {
              'role': role,
              'assignedAt': Timestamp.now(),
              'method': method,
              'assignedBy': assignedBy,
            }
          ]),
          'eligibility.$role': true,
        });
      }
    } catch (e) {
      throw 'Failed to assign role: $e';
    }
  }

  // Remove a role from a member
  Future<void> removeRole({
    required String governmentId,
    required String uid,
    required String role,
  }) async {
    try {
      await _firestore
          .collection('Governments')
          .doc(governmentId)
          .collection('members')
          .doc(uid) // UID-based!
          .update({
        'roles': FieldValue.arrayRemove([role]),
      });
    } catch (e) {
      throw 'Failed to remove role: $e';
    }
  }

  // Update government metrics (for simulation)
  Future<void> updateMetrics(String governmentId, Map<String, double> newMetrics) async {
    try {
      await _firestore.collection('Governments').doc(governmentId).update({
        'metrics': newMetrics,
      });
    } catch (e) {
      throw 'Failed to update metrics: $e';
    }
  }
}
