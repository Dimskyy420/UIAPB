class UserModel {
  final String uid;
  final String name;
  final String email;
  final String university;
  final String photoUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.university,
    this.photoUrl = '',
  });

  // Dari Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      university: map['university'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  // Ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'university': university,
      'photoUrl': photoUrl,
    };
  }
}