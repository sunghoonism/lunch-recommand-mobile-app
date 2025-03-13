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
      
      return similarWeather || similarTemperature;
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
    
    // 날씨 기반 기본 추천
    if (currentWeather.temperature > 25) {
      foodName = '냉면';
      foodCategory = '한식';
      reason = '더운 날씨에 시원한 냉면을 추천합니다.';
    } else if (currentWeather.temperature < 10) {
      foodName = '김치찌개';
      foodCategory = '한식';
      reason = '추운 날씨에 따뜻한 김치찌개를 추천합니다.';
    } else if (currentWeather.condition.contains('비')) {
      foodName = '부대찌개';
      foodCategory = '한식';
      reason = '비 오는 날에는 얼큰한 부대찌개가 좋습니다.';
    } else {
      foodName = '비빔밥';
      foodCategory = '한식';
      reason = '균형 잡힌 한 끼 식사로 비빔밥을 추천합니다.';
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