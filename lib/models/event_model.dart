import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String pic; // Penanggung Jawab
  final DateTime date;
  final String location;
  final String description;
  final String status; // "Aktif" / "Selesai"
  final String category; // "Akademik", "Organisasi", "Lomba", "Seminar"
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.name,
    required this.pic,
    required this.date,
    required this.location,
    required this.description,
    required this.status,
    required this.category,
    required this.createdAt,
  });

  // Convert to Map for Firestore/Local database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pic': pic,
      'date': Timestamp.fromDate(date), // Firestore Timestamp compatibility
      'location': location,
      'description': description,
      'status': status,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert to Map for local SQLite/SharedPreferences which cannot store Timestamp objects
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pic': pic,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'status': status,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create EventModel from Firestore Document Snapshot
  factory EventModel.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return EventModel(
      id: docId,
      name: map['name'] ?? '',
      pic: map['pic'] ?? '',
      date: parseDate(map['date']),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Aktif',
      category: map['category'] ?? 'Organisasi',
      createdAt: parseDate(map['createdAt']),
    );
  }

  // Create EventModel from JSON Map (Shared Preferences)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pic: json['pic'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Aktif',
      category: json['category'] ?? 'Organisasi',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  // CopyWith helper to modify models easily
  EventModel copyWith({
    String? id,
    String? name,
    String? pic,
    DateTime? date,
    String? location,
    String? description,
    String? status,
    String? category,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pic: pic ?? this.pic,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
