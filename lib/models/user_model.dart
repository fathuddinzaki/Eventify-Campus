class UserModel {
  final String uid;
  final String name;
  final String email;
  final String nim; // Student ID
  final String major; // Major/Department

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.nim,
    required this.major,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'nim': nim,
      'major': major,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      nim: map['nim'] ?? '',
      major: map['major'] ?? '',
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? nim,
    String? major,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      major: major ?? this.major,
    );
  }
}
