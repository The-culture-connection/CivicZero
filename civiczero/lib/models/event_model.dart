import 'package:cloud_firestore/cloud_firestore.dart';

/// Published event in a government
/// Stored in: governments/{govId}/events/{eventId}
class EventModel {
  final String id;
  final String governmentId;
  final String proposalId; // Which proposal created this event
  final String title;
  final String description;
  final String type; // assembly, livestream, panel, townhall, workshop
  final DateTime eventDateTime;
  final String? location;
  final String? host;
  final int? capacity;
  final String status; // scheduled, in_progress, completed, cancelled
  final DateTime publishedAt;
  final String publishedBy; // UID
  final List<String> attendeeUids; // RSVPs

  EventModel({
    required this.id,
    required this.governmentId,
    required this.proposalId,
    required this.title,
    required this.description,
    required this.type,
    required this.eventDateTime,
    this.location,
    this.host,
    this.capacity,
    this.status = 'scheduled',
    required this.publishedAt,
    required this.publishedBy,
    this.attendeeUids = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      governmentId: json['governmentId'] as String,
      proposalId: json['proposalId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      eventDateTime: (json['eventDateTime'] as Timestamp).toDate(),
      location: json['location'] as String?,
      host: json['host'] as String?,
      capacity: json['capacity'] as int?,
      status: json['status'] as String? ?? 'scheduled',
      publishedAt: (json['publishedAt'] as Timestamp).toDate(),
      publishedBy: json['publishedBy'] as String,
      attendeeUids: List<String>.from(json['attendeeUids'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'governmentId': governmentId,
      'proposalId': proposalId,
      'title': title,
      'description': description,
      'type': type,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'location': location,
      'host': host,
      'capacity': capacity,
      'status': status,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'publishedBy': publishedBy,
      'attendeeUids': attendeeUids,
    };
  }
}
