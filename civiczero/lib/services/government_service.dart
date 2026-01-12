import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civiczero/models/government_model.dart';

class GovernmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new government
  Future<String> createGovernment(GovernmentModel government) async {
    try {
      final docRef = await _firestore.collection('Governments').add(government.toJson());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create government: $e';
    }
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

  // Get governments user has joined
  Stream<List<GovernmentModel>> getJoinedGovernments(String userId) {
    return _firestore
        .collection('Governments')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GovernmentModel.fromJson(data);
      }).toList();
    });
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

  // Join a government
  Future<void> joinGovernment(String governmentId, String userId) async {
    try {
      await _firestore.collection('Governments').doc(governmentId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw 'Failed to join government: $e';
    }
  }

  // Leave a government
  Future<void> leaveGovernment(String governmentId, String userId) async {
    try {
      await _firestore.collection('Governments').doc(governmentId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw 'Failed to leave government: $e';
    }
  }

  // Check if user is member
  Future<bool> isMember(String governmentId, String userId) async {
    try {
      final gov = await getGovernment(governmentId);
      return gov?.memberIds.contains(userId) ?? false;
    } catch (e) {
      return false;
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
