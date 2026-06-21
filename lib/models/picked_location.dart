import 'package:latlong2/latlong.dart';

/// Hasil sementara dari pemilih lokasi peta (LocationPickerScreen).
///
/// Bukan model Firestore — tidak punya `toMap`/`fromMap`. Hanya dipakai untuk
/// mengembalikan koordinat + alamat dari layar peta ke step-3. Yang disimpan
/// ke Firestore nantinya adalah `point.latitude`/`point.longitude` (kanonik)
/// dan `address` (sekadar tampilan).
class PickedLocation {
  final LatLng point;
  final String address;

  const PickedLocation({required this.point, required this.address});
}
