import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String? id;
  final String requestId;
  final String helperUid;
  final int hargaTawar;
  final int estimasiTotal;
  final String pesan;
  final String status; // 'menunggu' | 'diterima' | 'ditolak'
  final DateTime? createdAt;

  BidModel({
    this.id,
    required this.requestId,
    required this.helperUid,
    required this.hargaTawar,
    required this.estimasiTotal,
    required this.pesan,
    this.status = 'menunggu',
    this.createdAt,
  });

  factory BidModel.fromMap(String id, Map<String, dynamic> map) {
    return BidModel(
      id: id,
      requestId: map['requestId'] ?? '',
      helperUid: map['helperUid'] ?? '',
      hargaTawar: map['hargaTawar'] ?? 0,
      estimasiTotal: map['estimasiTotal'] ?? 0,
      pesan: map['pesan'] ?? '',
      status: map['status'] ?? 'menunggu',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'helperUid': helperUid,
      'hargaTawar': hargaTawar,
      'estimasiTotal': estimasiTotal,
      'pesan': pesan,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  BidModel copyWith({String? status}) {
    return BidModel(
      id: id,
      requestId: requestId,
      helperUid: helperUid,
      hargaTawar: hargaTawar,
      estimasiTotal: estimasiTotal,
      pesan: pesan,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}