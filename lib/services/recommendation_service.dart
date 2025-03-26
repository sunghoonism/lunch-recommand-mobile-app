import '../models/food.dart';
import '../models/weather.dart';
import '../models/recommendation.dart';
import 'database_service.dart';

class RecommendationService {
  // 싱글톤 패턴 구현
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // 현재 날씨와 사용자 기록을 기반으로 음식 추천
  Future<Recommendation?> recommendFood(Weather currentWeather) async {
    try {
      // 1. 사용자의 모든 식사 기록 가져오기
      final List<Food> allFoods = await _databaseService.getFoods();
      
      if (allFoods.isEmpty) {
        // 데이터가 없으면 기본 추천
        return _getDefaultRecommendation(currentWeather);
      }

      // 2. 현재 날씨와 비슷한 조건의 식사 기록 필터링
      final List<Food> similarWeatherFoods = _filterBySimilarWeather(
        allFoods, 
        currentWeather
      );
      
      // 3. 최근 일주일 내에 먹지 않은 음식 필터링
      final List<Food> notRecentlyEatenFoods = _filterNotRecentlyEaten(
        similarWeatherFoods.isEmpty ? allFoods : similarWeatherFoods
      );
      
      // 4. 평점이 높은 순으로 정렬
      notRecentlyEatenFoods.sort((a, b) => b.rating.compareTo(a.rating));
      
      // 5. 상위 3개 음식 중에서 랜덤으로 선택
      final topFoods = notRecentlyEatenFoods.take(3).toList();
      if (topFoods.isEmpty) {
        return _getDefaultRecommendation(currentWeather);
      }
      
      // 랜덤 선택 (간단한 구현을 위해 첫 번째 항목 선택)
      final selectedFood = topFoods[0];
      
      // 6. 추천 이유 생성
      String reason = _generateRecommendationReason(selectedFood, currentWeather);
      
      // 7. 추천 객체 생성 및 반환
      return Recommendation(
        foodName: selectedFood.name,
        foodCategory: selectedFood.category,
        restaurantName: selectedFood.restaurantName,
        address: selectedFood.address,
        latitude: selectedFood.latitude,
        longitude: selectedFood.longitude,
        confidence: 0.85, // 임의의 신뢰도 값
        reason: reason,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('추천 생성 오류: $e');
      return null;
    }
  }

  // 비슷한 날씨 조건의 음식 필터링
  List<Food> _filterBySimilarWeather(List<Food> foods, Weather currentWeather) {
    return foods.where((food) {
      // 날씨 정보가 없는 경우 제외
      if (food.weather == null || food.temperature == null) {
        return false;
      }
      
      // 비슷한 날씨 조건 (같은 날씨 상태 또는 비슷한 온도)
      bool similarWeather = food.weather == currentWeather.condition;
      bool similarTemperature = (food.temperature! - currentWeather.temperature).abs() <= 5.0;
      
      // 비슷한 풍속 조건 (풍속 차이가 2.0m/s 이하)
      bool similarWindSpeed = false;
      if (food.windSpeed != null) {
        similarWindSpeed = (food.windSpeed! - currentWeather.windSpeed).abs() <= 2.0;
      }
      
      return similarWeather || similarTemperature || similarWindSpeed;
    }).toList();
  }

  // 최근에 먹지 않은 음식 필터링 (일주일 이내)
  List<Food> _filterNotRecentlyEaten(List<Food> foods) {
    final oneWeekAgo = DateTime.now().subtract(Duration(days: 7));
    
    // 음식 이름별로 그룹화하여 가장 최근 날짜 찾기
    Map<String, DateTime> lastEatenDates = {};
    
    for (var food in foods) {
      if (!lastEatenDates.containsKey(food.name) || 
          food.date.isAfter(lastEatenDates[food.name]!)) {
        lastEatenDates[food.name] = food.date;
      }
    }
    
    // 일주일 이내에 먹지 않은 음식만 필터링
    return foods.where((food) {
      final lastEaten = lastEatenDates[food.name];
      return lastEaten != null && lastEaten.isBefore(oneWeekAgo);
    }).toList();
  }

  // 추천 이유 생성
  String _generateRecommendationReason(Food food, Weather currentWeather) {
    List<String> reasons = [];
    
    // 날씨 기반 이유
    if (food.weather == currentWeather.condition) {
      reasons.add('오늘과 비슷한 날씨에 즐겨 드셨던');
    }
    
    // 온도 기반 이유
    if (food.temperature != null && 
        (food.temperature! - currentWeather.temperature).abs() <= 3.0) {
      reasons.add('비슷한 온도에서 선호하셨던');
    }
    
    // 풍속 기반 이유
    if (food.windSpeed != null && 
        (food.windSpeed! - currentWeather.windSpeed).abs() <= 1.5) {
      reasons.add('비슷한 바람 세기에서 즐기셨던');
    }
    
    // 평점 기반 이유
    if (food.rating >= 4) {
      reasons.add('높은 평점을 주셨던');
    }
    
    if (reasons.isEmpty) {
      reasons.add('과거에 즐겨 드셨던');
    }
    
    return '${reasons.join(', ')} ${food.name}${food.restaurantName != null ? '(${food.restaurantName})' : ''}을(를) 추천합니다.';
  }

  // 기본 추천 (데이터가 없을 때)
  Recommendation _getDefaultRecommendation(Weather currentWeather) {
    String foodName;
    String foodCategory;
    String reason;
    
    // 높은 풍속인 경우 (5m/s 이상)
    if (currentWeather.windSpeed >= 5.0) {
      // 바람이 강할 때는 따뜻하고 든든한 음식이나 식사하기 쉬운 음식 추천
      final List<Map<String, String>> windyDayFoods = [
        {'name': '국밥', 'category': '한식', 'reason': '바람이 강한 날에는 따뜻한 국물이 있는 국밥이 좋습니다.'},
        {'name': '짜장면', 'category': '중식', 'reason': '바람이 강한 날에는 배달 음식인 짜장면이 편리합니다.'},
        {'name': '리조또', 'category': '양식', 'reason': '바람이 강한 날에는 따뜻하고 든든한 리조또가 좋습니다.'},
        {'name': '라멘', 'category': '일식', 'reason': '바람이 강한 날에는 따뜻한 국물이 있는 라멘이 좋습니다.'},
        {'name': '칼국수', 'category': '한식', 'reason': '바람이 강한 날에는 든든한 칼국수가 좋습니다.'},
      ];
      
      // 랜덤 선택
      final random = DateTime.now().millisecond % windyDayFoods.length;
      final selectedFood = windyDayFoods[random];
      
      foodName = selectedFood['name']!;
      foodCategory = selectedFood['category']!;
      reason = selectedFood['reason']!;
    }
    // 날씨 기반 기본 추천
    else if (currentWeather.temperature > 25) {
      // 더운 날씨에는 시원한 음식 추천
      final List<Map<String, String>> hotDayFoods = [
        {'name': '냉면', 'category': '한식', 'reason': '더운 날씨에 시원한 냉면을 추천합니다.'},
        {'name': '콩국수', 'category': '한식', 'reason': '더운 날씨에 시원한 콩국수를 추천합니다.'},
        {'name': '냉모밀', 'category': '일식', 'reason': '더운 날씨에 시원한 냉모밀을 추천합니다.'},
        {'name': '빙수', 'category': '카페/디저트', 'reason': '더운 날씨에 시원한 빙수를 추천합니다.'},
        {'name': '샐러드', 'category': '양식', 'reason': '더운 날씨에 가볍게 먹기 좋은 샐러드를 추천합니다.'},
      ];
      
      // 랜덤 선택
      final random = DateTime.now().millisecond % hotDayFoods.length;
      final selectedFood = hotDayFoods[random];
      
      foodName = selectedFood['name']!;
      foodCategory = selectedFood['category']!;
      reason = selectedFood['reason']!;
    } else if (currentWeather.temperature < 10) {
      // 추운 날씨에는 따뜻한 음식 추천
      final List<Map<String, String>> coldDayFoods = [
        {'name': '김치찌개', 'category': '한식', 'reason': '추운 날씨에 따뜻한 김치찌개를 추천합니다.'},
        {'name': '마라탕', 'category': '중식', 'reason': '추운 날씨에 얼큰한 마라탕을 추천합니다.'},
        {'name': '우동', 'category': '일식', 'reason': '추운 날씨에 따뜻한 우동을 추천합니다.'},
        {'name': '스튜', 'category': '양식', 'reason': '추운 날씨에 따뜻한 스튜를 추천합니다.'},
        {'name': '된장찌개', 'category': '한식', 'reason': '추운 날씨에 따뜻한 된장찌개를 추천합니다.'},
      ];
      
      // 랜덤 선택
      final random = DateTime.now().millisecond % coldDayFoods.length;
      final selectedFood = coldDayFoods[random];
      
      foodName = selectedFood['name']!;
      foodCategory = selectedFood['category']!;
      reason = selectedFood['reason']!;
    } else if (currentWeather.condition.contains('비')) {
      // 비 오는 날에는 따뜻하고 얼큰한 음식 추천
      final List<Map<String, String>> rainyDayFoods = [
        {'name': '부대찌개', 'category': '한식', 'reason': '비 오는 날에는 얼큰한 부대찌개가 좋습니다.'},
        {'name': '짬뽕', 'category': '중식', 'reason': '비 오는 날에는 얼큰한 짬뽕이 좋습니다.'},
        {'name': '라멘', 'category': '일식', 'reason': '비 오는 날에는 얼큰한 라멘이 좋습니다.'},
        {'name': '감자탕', 'category': '한식', 'reason': '비 오는 날에는 따뜻한 감자탕이 좋습니다.'},
        {'name': '육개장', 'category': '한식', 'reason': '비 오는 날에는 얼큰한 육개장이 좋습니다.'},
      ];
      
      // 랜덤 선택
      final random = DateTime.now().millisecond % rainyDayFoods.length;
      final selectedFood = rainyDayFoods[random];
      
      foodName = selectedFood['name']!;
      foodCategory = selectedFood['category']!;
      reason = selectedFood['reason']!;
    } else {
      // 일반적인 날씨에는 다양한 음식 추천
      final List<Map<String, String>> normalDayFoods = [
        {'name': '비빔밥', 'category': '한식', 'reason': '균형 잡힌 한 끼 식사로 비빔밥을 추천합니다.'},
        {'name': '치킨', 'category': '패스트푸드', 'reason': '언제 먹어도 맛있는 치킨을 추천합니다.'},
        {'name': '파스타', 'category': '양식', 'reason': '간편하고 맛있는 파스타를 추천합니다.'},
        {'name': '초밥', 'category': '일식', 'reason': '신선한 초밥으로 기분 전환을 추천합니다.'},
        {'name': '샌드위치', 'category': '양식', 'reason': '간편하게 먹을 수 있는 샌드위치를 추천합니다.'},
      ];
      
      // 랜덤 선택
      final random = DateTime.now().millisecond % normalDayFoods.length;
      final selectedFood = normalDayFoods[random];
      
      foodName = selectedFood['name']!;
      foodCategory = selectedFood['category']!;
      reason = selectedFood['reason']!;
    }
    
    return Recommendation(
      foodName: foodName,
      foodCategory: foodCategory,
      confidence: 0.7,
      reason: reason,
      timestamp: DateTime.now(),
    );
  }
} 