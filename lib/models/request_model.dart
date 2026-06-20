import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String? id;
  final String userId;
  final String category;
  final String title;
  final String description;
  final String duration;
  final String mode;
  final String location;
  final String date;
  final String time;
  final int budget;
  final String status;
  final DateTime? createdAt;

  RequestModel({
    this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.duration,
    required this.mode,
    required this.location,
    required this.date,
    required this.time,
    required this.budget,
    this.status = 'menunggu',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'title': title,
      'description': description,
      'duration': duration,
      'mode': mode,
      'location': location,
      'date': date,
      'time': time,
      'budget': budget,
      'status': status,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  factory RequestModel.fromMap(String id, Map<String, dynamic> map) {
    return RequestModel(
      id: id,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? '',
      mode: map['mode'] ?? 'Tatap Muka',
      location: map['location'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      budget: map['budget'] ?? 0,
      status: map['status'] ?? 'menunggu',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // ─── Kalkulasi biaya ───────────────────────────────────────────────────────
  int get biayaLayanan {
    switch (duration) {
      case '< 1 jam':
        return 10000;
      case '1-2 jam':
        return 17000;
      case '2-4 jam':
        return 30000;
      case '1 hari':
        return 80000;
      case '2-3 hari':
        return 150000;
      default:
        return 17000;
    }
  }

  int get platformFee => (biayaLayanan * 0.1).round();
  int get extraFee => mode == 'Tatap Muka' ? 3000 : 0;
  int get totalEstimasi => biayaLayanan + platformFee + extraFee;

  // ─── Copy with ────────────────────────────────────────────────────────────
  RequestModel copyWith({
    String? category,
    String? title,
    String? description,
    String? duration,
    String? mode,
    String? location,
    String? date,
    String? time,
    int? budget,
    String? status,
  }) {
    return RequestModel(
      id: id,
      userId: userId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      mode: mode ?? this.mode,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}