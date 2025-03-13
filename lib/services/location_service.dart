import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // 싱글톤 패턴 구현
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // 현재 위치 권한 확인 및 요청
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 거부된 경우 요청
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // 영구적으로 거부된 경우
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // 현재 위치 가져오기
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // 위도, 경도로 주소 가져오기
  Future<String?> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.administrativeArea} ${place.locality} ${place.subLocality} ${place.thoroughfare}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 