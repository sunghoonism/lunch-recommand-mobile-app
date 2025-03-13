import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/recommendation.dart';
import '../models/weather.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/recommendation_service.dart';

class RecommendationController with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final RecommendationService _recommendationService = RecommendationService();
  
  Recommendation? _currentRecommendation;
  Weather? _currentWeather;
  bool _isLoading = false;
  String? _errorMessage;
  
  Recommendation? get currentRecommendation => _currentRecommendation;
  Weather? get currentWeather => _currentWeather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // 추천 생성
  Future<void> generateRecommendation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 1. 현재 위치 가져오기
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _errorMessage = '위치 정보를 가져올 수 없습니다.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // 2. 현재 날씨 정보 가져오기
      final weather = await _weatherService.getCurrentWeather(
        position.latitude,
        position.longitude,
      );
      
      if (weather == null) {
        _errorMessage = '날씨 정보를 가져올 수 없습니다.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _currentWeather = weather;
      
      // 3. 추천 생성
      final recommendation = await _recommendationService.recommendFood(weather);
      
      if (recommendation == null) {
        _errorMessage = '추천을 생성할 수 없습니다.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // 4. 추천 결과 저장
      await _databaseService.insertRecommendation(recommendation);
      
      _currentRecommendation = recommendation;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 특정 시간대의 날씨 정보 가져오기
  Future<Weather?> getWeatherForTime(DateTime time) async {
    try {
      // 현재 위치 가져오기
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _errorMessage = '위치 정보를 가져올 수 없습니다.';
        notifyListeners();
        return null;
      }
      
      // 특정 시간대의 날씨 정보 가져오기
      final weather = await _weatherService.getWeatherForTime(
        position.latitude,
        position.longitude,
        time,
      );
      
      if (weather == null) {
        _errorMessage = '날씨 정보를 가져올 수 없습니다.';
        notifyListeners();
      }
      
      return weather;
    } catch (e) {
      _errorMessage = '날씨 정보 가져오기 실패: $e';
      notifyListeners();
      return null;
    }
  }
  
  // 식사 기록 저장
  Future<bool> saveFoodRecord(Food food) async {
    try {
      await _databaseService.insertFood(food);
      return true;
    } catch (e) {
      _errorMessage = '식사 기록 저장 실패: $e';
      notifyListeners();
      return false;
    }
  }
  
  // 식사 기록 수정
  Future<bool> updateFoodRecord(Food food) async {
    try {
      await _databaseService.updateFood(food);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '식사 기록 수정 실패: $e';
      notifyListeners();
      return false;
    }
  }
  
  // 식사 기록 삭제
  Future<bool> deleteFoodRecord(int id) async {
    try {
      await _databaseService.deleteFood(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '식사 기록 삭제 실패: $e';
      notifyListeners();
      return false;
    }
  }
  
  // 특정 ID의 식사 기록 가져오기
  Future<Food?> getFoodById(int id) async {
    try {
      return await _databaseService.getFoodById(id);
    } catch (e) {
      _errorMessage = '식사 기록 조회 실패: $e';
      notifyListeners();
      return null;
    }
  }
  
  // 추천 기록 삭제
  Future<bool> deleteRecommendation(int id) async {
    try {
      await _databaseService.deleteRecommendation(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '추천 기록 삭제 실패: $e';
      notifyListeners();
      return false;
    }
  }
  
  // 최근 식사 기록 가져오기
  Future<List<Food>> getRecentFoods() async {
    try {
      final now = DateTime.now();
      final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
      return await _databaseService.getFoodsByDateRange(oneMonthAgo, now);
    } catch (e) {
      _errorMessage = '최근 식사 기록 가져오기 실패: $e';
      notifyListeners();
      return [];
    }
  }
  
  // 모든 식사 기록 가져오기
  Future<List<Food>> getAllFoods() async {
    try {
      return await _databaseService.getFoods();
    } catch (e) {
      _errorMessage = '식사 기록 가져오기 실패: $e';
      notifyListeners();
      return [];
    }
  }
  
  // 최근 추천 기록 가져오기
  Future<List<Recommendation>> getRecentRecommendations() async {
    try {
      return await _databaseService.getRecentRecommendations(10);
    } catch (e) {
      _errorMessage = '최근 추천 기록 가져오기 실패: $e';
      notifyListeners();
      return [];
    }
  }
} 