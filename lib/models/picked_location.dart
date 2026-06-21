import 'package:latlong2/latlong.dart';

class PickedLocation {
  final LatLng point;
  final String address;

  const PickedLocation({required this.point, required this.address});
}
