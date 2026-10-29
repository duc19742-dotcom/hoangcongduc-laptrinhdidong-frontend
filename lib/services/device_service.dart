import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

class DeviceService {
  static Future<Position> position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException(
        'GPS đang tắt. Hãy bật Vị trí trên điện thoại rồi thử lại.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const ApiException(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy mở cài đặt ứng dụng để cấp lại.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const ApiException(
        'Cần quyền vị trí để chia sẻ GPS khi chấm công.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
  }
}
