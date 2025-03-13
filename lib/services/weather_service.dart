import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../config/secrets.dart';

class WeatherService {
  // 싱글톤 패턴 구현
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // 기상청 API 키 (secrets.dart 파일에서 가져옴)
  final String _apiKey = Secrets.weatherApiKey;
  
  // 기상청 API 기본 URL
  final String _baseUrl = 'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';
  final String _awsUrl = 'http://apis.data.go.kr/1360000/AsosHourlyInfoService';

  // 단기예보 조회 API 엔드포인트
  final String _forecastEndpoint = '/getUltraSrtNcst';
  final String _awsEndpoint = '/getWthrDataList';

  // 주요 도시 위치 및 지점 번호 정의
  final List<Map<String, dynamic>> _majorCities = [
    {'name': '서울', 'lat': 37.5665, 'lon': 126.9780, 'stnId': '108'},
    {'name': '인천', 'lat': 37.4563, 'lon': 126.7052, 'stnId': '112'},
    {'name': '수원', 'lat': 37.2636, 'lon': 127.0286, 'stnId': '119'},
    {'name': '대전', 'lat': 36.3504, 'lon': 127.3845, 'stnId': '133'},
    {'name': '대구', 'lat': 35.8714, 'lon': 128.6014, 'stnId': '143'},
    {'name': '부산', 'lat': 35.1796, 'lon': 129.0756, 'stnId': '159'},
    {'name': '광주', 'lat': 35.1595, 'lon': 126.8526, 'stnId': '156'},
    {'name': '제주', 'lat': 33.4996, 'lon': 126.5312, 'stnId': '184'},
  ];

  // 현재 날씨 정보 가져오기
  Future<Weather?> getCurrentWeather(double latitude, double longitude) async {
    try {
      // 위경도를 기상청 격자 좌표로 변환
      final Map<String, int> grid = _convertToGrid(latitude, longitude);
      
      // 현재 날짜와 시간 정보
      final now = DateTime.now();
      DateTime targetDate;
      String baseTime;

      // 시간대별 API 요청 시간 설정
      if (now.hour == 0 && now.minute < 10) {
        // 00:00~00:10 => 전날 23:00 데이터 사용
        targetDate = now.subtract(const Duration(days: 1));
        baseTime = '2300';
      } else if (now.minute < 10) {
        // XX:00~XX:10 => 한 시간 전 데이터 사용
        targetDate = now;
        final prevHour = now.hour - 1;
        baseTime = prevHour < 10 ? '0${prevHour}00' : '${prevHour}00';
      } else {
        // XX:10~XX:59 => 현재 시간 데이터 사용
        targetDate = now;
        baseTime = now.hour < 10 ? '0${now.hour}00' : '${now.hour}00';
      }

      // 날짜 형식 변환
      final baseDate = targetDate.year.toString() +
          (targetDate.month < 10 ? '0${targetDate.month}' : '${targetDate.month}') +
          (targetDate.day < 10 ? '0${targetDate.day}' : '${targetDate.day}');

      // API 요청 URL 구성
      final queryParameters = {
        'serviceKey': _apiKey,
        'numOfRows': '10',
        'pageNo': '1',
        'dataType': 'JSON',
        'base_date': baseDate,
        'base_time': baseTime,
        'nx': grid['nx'].toString(),
        'ny': grid['ny'].toString(),
      };

      print("queryParameters: $queryParameters");

      final uri = Uri.parse('$_baseUrl$_forecastEndpoint').replace(
        queryParameters: queryParameters,
      );

      // API 요청
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        
        // 응답 데이터 파싱 (실제 기상청 API 응답 구조에 맞게 수정 필요)
        if (data['response']['header']['resultCode'] == '00') {
          final items = data['response']['body']['items']['item'];
          
          // 필요한 날씨 정보 추출
          String condition = '맑음'; // 기본값 설정
          double? temperature;
          double? windSpeed;
          double? humidity;
          
          for (var item in items) {
            switch (item['category']) {
              case 'PTY': // 강수형태
                final pty = int.parse(item['obsrValue']);
                if (pty == 1) condition = '비';
                else if (pty == 2) condition = '비/눈';
                else if (pty == 3) condition = '눈';
                else if (pty == 4) condition = '소나기';
                else condition = '맑음'; // 강수 없음(0)인 경우 맑음으로 설정
                break;
              case 'T1H': // 기온
                temperature = double.parse(item['obsrValue']);
                break;
              case 'WSD': // 풍속
                windSpeed = double.parse(item['obsrValue']);
                break;
              case 'REH': // 습도
                humidity = double.parse(item['obsrValue']);
                break;
            }
          }
          
          // 모든 필요한 정보가 있으면 Weather 객체 생성
          if (temperature != null && windSpeed != null && humidity != null) {
            return Weather(
              condition: condition,
              temperature: temperature,
              windSpeed: windSpeed,
              humidity: humidity,
              timestamp: now,
            );
          }
        }
      }
      
      return null;
    } catch (e) {
      print('날씨 정보 가져오기 오류: $e');
      return null;
    }
  }

  // 특정 시간대의 날씨 정보 가져오기
  Future<Weather?> getWeatherForTime(double latitude, double longitude, DateTime time) async {
    try {
      // 현재 날짜 확인
      final now = DateTime.now();
      final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
      
      // 오늘 날짜인 경우 초단기예보 API 사용
      if (isToday) {
        return await _getUltraSrtFcstWeather(latitude, longitude, time);
      } 
      // 과거 날짜인 경우 종관기상관측 API 사용
      else if (time.isBefore(now)) {
        return await _getHistoricalWeather(latitude, longitude, time);
      }
      // 미래 날짜인 경우 기본 날씨 정보 반환
      else {
        print('미래 날짜의 날씨 정보는 제공되지 않습니다.');
        return Weather(
          condition: '맑음',
          temperature: 20.0,
          windSpeed: 2.0,
          humidity: 50.0,
          timestamp: time,
        );
      }
    } catch (e) {
      print('특정 시간 날씨 정보 가져오기 오류: $e');
      // 오류 발생 시 기본 날씨 정보 반환
      return Weather(
        condition: '맑음',
        temperature: 20.0,
        windSpeed: 2.0,
        humidity: 50.0,
        timestamp: time,
      );
    }
  }

  // 초단기예보 API를 사용하여 오늘 날짜의 날씨 정보 가져오기
  Future<Weather?> _getUltraSrtFcstWeather(double latitude, double longitude, DateTime time) async {
    // 위경도를 기상청 격자 좌표로 변환
    final Map<String, int> grid = _convertToGrid(latitude, longitude);
    
    // 시간 설정
    DateTime targetDate = time;
    String baseTime;
    
    // 시간대별 API 요청 시간 설정
    if (time.hour == 0 && time.minute < 10) {
      // 00:00~00:10 => 전날 23:00 데이터 사용
      targetDate = time.subtract(const Duration(days: 1));
      baseTime = '2300';
    } else if (time.minute < 10) {
      // XX:00~XX:10 => 한 시간 전 데이터 사용
      final prevHour = time.hour - 1;
      baseTime = prevHour < 10 ? '0${prevHour}00' : '${prevHour}00';
    } else {
      // XX:10~XX:59 => 현재 시간 데이터 사용
      baseTime = time.hour < 10 ? '0${time.hour}00' : '${time.hour}00';
    }

    // 날짜 형식 변환
    final baseDate = targetDate.year.toString() +
        (targetDate.month < 10 ? '0${targetDate.month}' : '${targetDate.month}') +
        (targetDate.day < 10 ? '0${targetDate.day}' : '${targetDate.day}');

    // API 요청 URL 구성
    final queryParameters = {
      'serviceKey': _apiKey,
      'numOfRows': '10',
      'pageNo': '1',
      'dataType': 'JSON',
      'base_date': baseDate,
      'base_time': baseTime,
      'nx': grid['nx'].toString(),
      'ny': grid['ny'].toString(),
    };

    print("getUltraSrtFcstWeather queryParameters: $queryParameters");

    final uri = Uri.parse('$_baseUrl$_forecastEndpoint').replace(
      queryParameters: queryParameters,
    );

    // API 요청
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      
      // 응답 데이터 파싱
      if (data['response']['header']['resultCode'] == '00') {
        final items = data['response']['body']['items']['item'];
        
        // 필요한 날씨 정보 추출
        String condition = '맑음'; // 기본값 설정
        double? temperature;
        double? windSpeed;
        double? humidity;
        
        for (var item in items) {
          switch (item['category']) {
            case 'PTY': // 강수형태
              final pty = int.parse(item['obsrValue']);
              if (pty == 1) condition = '비';
              else if (pty == 2) condition = '비/눈';
              else if (pty == 3) condition = '눈';
              else if (pty == 4) condition = '소나기';
              else condition = '맑음'; // 강수 없음(0)인 경우 맑음으로 설정
              break;
            case 'T1H': // 기온
              temperature = double.parse(item['obsrValue']);
              break;
            case 'WSD': // 풍속
              windSpeed = double.parse(item['obsrValue']);
              break;
            case 'REH': // 습도
              humidity = double.parse(item['obsrValue']);
              break;
          }
        }
        
        // 모든 필요한 정보가 있으면 Weather 객체 생성
        if (temperature != null && windSpeed != null && humidity != null) {
          return Weather(
            condition: condition,
            temperature: temperature,
            windSpeed: windSpeed,
            humidity: humidity,
            timestamp: time,
          );
        }
      }
    }
    
    // API 요청 실패 시 null 반환
    print('초단기예보 API 요청 실패: 날씨 정보를 가져올 수 없습니다.');
    return null;
  }

  // 종관기상관측 API를 사용하여 과거 날짜의 날씨 정보 가져오기
  Future<Weather?> _getHistoricalWeather(double latitude, double longitude, DateTime time) async {
    // 가장 가까운 도시 찾기
    final nearestCity = _findNearestCity(latitude, longitude);
    print('가장 가까운 도시: ${nearestCity['name']}, 지점번호: ${nearestCity['stnId']}');
    
    // 시간 설정
    DateTime targetDate = time;
    String targetHour;
    
    // 시간대별 API 요청 시간 설정
    if (time.hour == 0 && time.minute < 10) {
      // 00:00~00:10 => 전날 23:00 데이터 사용
      targetDate = time.subtract(const Duration(days: 1));
      targetHour = '23';
    } else if (time.minute < 10) {
      // XX:00~XX:10 => 한 시간 전 데이터 사용
      final prevHour = time.hour - 1;
      targetHour = prevHour < 10 ? '0$prevHour' : '$prevHour';
    } else {
      // XX:10~XX:59 => 현재 시간 데이터 사용
      targetHour = time.hour < 10 ? '0${time.hour}' : '${time.hour}';
    }
    
    // 날짜 형식 변환
    final startDate = targetDate.year.toString() +
        (targetDate.month < 10 ? '0${targetDate.month}' : '${targetDate.month}') +
        (targetDate.day < 10 ? '0${targetDate.day}' : '${targetDate.day}');
    final endDate = startDate; // 같은 날짜로 설정
    
    // 시간 형식 변환
    final startTime = targetHour;
    final endTime = startTime; // 같은 시간으로 설정

    // API 요청 URL 구성
    final queryParameters = {
      'serviceKey': _apiKey,
      'numOfRows': '10',
      'pageNo': '1',
      'dataType': 'JSON',
      'dataCd': 'ASOS',
      'dateCd': 'HR',
      'startDt': startDate,
      'startHh': startTime,
      'endDt': endDate,
      'endHh': endTime,
      'stnIds': nearestCity['stnId'],
    };

    print("getHistoricalWeather queryParameters: $queryParameters");

    final uri = Uri.parse('$_awsUrl$_awsEndpoint').replace(
      queryParameters: queryParameters,
    );

    // API 요청
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      
      // 응답 데이터 파싱
      if (data['response']['header']['resultCode'] == '00') {
        try {
          final items = data['response']['body']['items']['item'];
          if (items.isNotEmpty) {
            final item = items[0];
            
            // 필요한 날씨 정보 추출
            String condition = '맑음'; // 기본값 설정
            double? temperature;
            double? windSpeed;
            double? humidity;
            
            // 강수량으로 날씨 상태 추정
            final rainfall = item['rn'] != null ? double.tryParse(item['rn'].toString()) ?? 0.0 : 0.0;
            if (rainfall > 0) {
              condition = '비';
            }
            
            // 기온
            temperature = item['ta'] != null ? double.tryParse(item['ta'].toString()) : null;
            
            // 풍속
            windSpeed = item['ws'] != null ? double.tryParse(item['ws'].toString()) : null;
            
            // 습도
            humidity = item['hm'] != null ? double.tryParse(item['hm'].toString()) : null;
            
            // 모든 필요한 정보가 있으면 Weather 객체 생성
            if (temperature != null && windSpeed != null && humidity != null) {
              return Weather(
                condition: condition,
                temperature: temperature,
                windSpeed: windSpeed,
                humidity: humidity,
                timestamp: time,
              );
            }
          }
        } catch (e) {
          print('종관기상관측 데이터 파싱 오류: $e');
        }
      }
    }
    
    // API 요청 실패 시 null 반환
    print('종관기상관측 API 요청 실패: 날씨 정보를 가져올 수 없습니다.');
    return null;
  }

  // 가장 가까운 도시 찾기 (사전 정의된 범위 사용)
  Map<String, dynamic> _findNearestCity(double latitude, double longitude) {
    // 서울 지역 (37.41~37.70, 126.77~127.18)
    if (latitude >= 37.41 && latitude <= 37.70 && 
        longitude >= 126.77 && longitude <= 127.18) {
      return _majorCities.firstWhere((city) => city['name'] == '서울');
    }
    
    // 인천 지역 (37.33~37.61, 126.36~126.80)
    if (latitude >= 37.33 && latitude <= 37.61 && 
        longitude >= 126.36 && longitude <= 126.80) {
      return _majorCities.firstWhere((city) => city['name'] == '인천');
    }
    
    // 수원 지역 (37.22~37.32, 126.95~127.05)
    if (latitude >= 37.22 && latitude <= 37.32 && 
        longitude >= 126.95 && longitude <= 127.05) {
      return _majorCities.firstWhere((city) => city['name'] == '수원');
    }
    
    // 대전 지역 (36.23~36.49, 127.25~127.52)
    if (latitude >= 36.23 && latitude <= 36.49 && 
        longitude >= 127.25 && longitude <= 127.52) {
      return _majorCities.firstWhere((city) => city['name'] == '대전');
    }
    
    // 대구 지역 (35.75~35.95, 128.45~128.75)
    if (latitude >= 35.75 && latitude <= 35.95 && 
        longitude >= 128.45 && longitude <= 128.75) {
      return _majorCities.firstWhere((city) => city['name'] == '대구');
    }
    
    // 부산 지역 (35.05~35.25, 128.95~129.25)
    if (latitude >= 35.05 && latitude <= 35.25 && 
        longitude >= 128.95 && longitude <= 129.25) {
      return _majorCities.firstWhere((city) => city['name'] == '부산');
    }
    
    // 광주 지역 (35.05~35.25, 126.75~127.00)
    if (latitude >= 35.05 && latitude <= 35.25 && 
        longitude >= 126.75 && longitude <= 127.00) {
      return _majorCities.firstWhere((city) => city['name'] == '광주');
    }
    
    // 제주 지역 (33.25~33.55, 126.35~126.65)
    if (latitude >= 33.25 && latitude <= 33.55 && 
        longitude >= 126.35 && longitude <= 126.65) {
      return _majorCities.firstWhere((city) => city['name'] == '제주');
    }
    
    // 어떤 범위에도 속하지 않으면 가장 가까운 도시 탐색
    print('미리 정의된 범위에 없는 좌표입니다. 최근접 도시를 계산합니다.');
    return _findNearestCityByDistance(latitude, longitude);
  }
  
  // 거리 계산을 통한 가장 가까운 도시 찾기 (보조 메서드)
  Map<String, dynamic> _findNearestCityByDistance(double latitude, double longitude) {
    double minDistance = double.infinity;
    Map<String, dynamic> nearestCity = _majorCities[0];
    
    for (var city in _majorCities) {
      final distance = _calculateDistance(
        latitude, longitude, city['lat'], city['lon']
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestCity = city;
      }
    }
    
    return nearestCity;
  }

  // 두 지점 간의 거리 계산 (Haversine 공식)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // 지구 반경 (km)
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance;
  }

  // 각도를 라디안으로 변환
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // 위경도를 기상청 격자 좌표로 변환
  Map<String, int> _convertToGrid(double lat, double lon) {
    const double RE = 6371.00877; // 지구 반경(km)
    const double GRID = 5.0; // 격자 간격(km)
    const double SLAT1 = 30.0; // 표준위도 1
    const double SLAT2 = 60.0; // 표준위도 2
    const double OLON = 126.0; // 기준점 경도
    const double OLAT = 38.0; // 기준점 위도
    const double XO = 43; // 기준점 X좌표
    const double YO = 136; // 기준점 Y좌표
    
    final double DEGRAD = pi / 180.0;
    final double re = RE / GRID;
    final double slat1 = SLAT1 * DEGRAD;
    final double slat2 = SLAT2 * DEGRAD;
    final double olon = OLON * DEGRAD;
    final double olat = OLAT * DEGRAD;
    
    double sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
    sn = log(cos(slat1) / cos(slat2)) / log(sn);
    double sf = tan(pi * 0.25 + slat1 * 0.5);
    sf = pow(sf, sn) * cos(slat1) / sn;
    double ro = tan(pi * 0.25 + olat * 0.5);
    ro = re * sf / pow(ro, sn);
    
    double ra = tan(pi * 0.25 + (lat) * DEGRAD * 0.5);
    ra = re * sf / pow(ra, sn);
    var theta = lon * DEGRAD - olon;
    if (theta > pi) theta -= 2.0 * pi;
    if (theta < -pi) theta += 2.0 * pi;
    theta *= sn;
    
    final nx = (ra * sin(theta) + XO + 0.5).floor();
    final ny = (ro - ra * cos(theta) + YO + 0.5).floor();
    
    return {
      'nx': nx,
      'ny': ny,
    };
  }
} 