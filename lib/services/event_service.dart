import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream events from Firebase Firestore (real-time)
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Fetch events once
  Future<List<EventModel>> getEventsOnce() async {
    final snapshot = await _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // --- CRUD OPERATIONS ---

  // CREATE: Add new Event
  Future<void> addEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).set(event.toMap());
  }

  // UPDATE: Edit existing Event
  Future<void> updateEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.id).update(event.toMap());
  }

  // DELETE: Delete existing Event
  Future<void> deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).delete();
  }
}
