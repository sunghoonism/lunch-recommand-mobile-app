import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/recommendation_controller.dart';
import '../models/food.dart';
import '../services/location_service.dart';

class FoodInputScreen extends StatefulWidget {
  const FoodInputScreen({Key? key}) : super(key: key);

  @override
  State<FoodInputScreen> createState() => _FoodInputScreenState();
}

class _FoodInputScreenState extends State<FoodInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  
  String _selectedCategory = '한식';
  int _rating = 3;
  bool _isLoading = false;
  String? _currentAddress;
  double? _latitude;
  double? _longitude;
  DateTime _selectedDate = DateTime.now();
  String _mealTime = '점심'; // 기본값은 점심
  
  final List<String> _categories = [
    '한식', '중식', '일식', '양식', '분식', 
    '패스트푸드', '카페/디저트', '기타'
  ];
  
  final List<String> _mealTimes = ['아침', '점심', '저녁'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initMealTime();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  // 현재 시간에 따라 식사 시간대 초기화
  void _initMealTime() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour < 11) {
      _mealTime = '아침';
    } else if (hour < 17) {
      _mealTime = '점심';
    } else {
      _mealTime = '저녁';
    }
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // 주소 가져오기
        _currentAddress = await locationService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );
      }
    } catch (e) {
      print('위치 정보 가져오기 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 날짜 선택 다이얼로그 표시
  Future<void> _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: '식사 날짜 선택',
        cancelText: '취소',
        confirmText: '선택',
        locale: const Locale('ko', 'KR'),
      );
      
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    } catch (e) {
      print('날짜 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('날짜 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 식사 시간대에 따른 날씨 정보 시간 설정
  DateTime _getWeatherTimeForMeal(DateTime date, String mealTime) {
    switch (mealTime) {
      case '아침':
        return DateTime(date.year, date.month, date.day, 7); // 오전 7시
      case '점심':
        return DateTime(date.year, date.month, date.day, 12); // 오후 12시
      case '저녁':
        return DateTime(date.year, date.month, date.day, 19); // 오후 7시
      default:
        return date;
    }
  }

  // 음식 기록 저장
  Future<void> _saveFood() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 식사 시간대에 따른 날씨 정보 시간 설정
        final weatherTime = _getWeatherTimeForMeal(_selectedDate, _mealTime);
        
        // 해당 시간대의 날씨 정보 가져오기
        final weather = await Provider.of<RecommendationController>(context, listen: false)
            .getWeatherForTime(weatherTime);
        
        if (weather == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장 실패. 날씨 정보를 가져올 수 없습니다.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return; // 날씨 정보가 없으면 저장 중단
        }
        
        final food = Food(
          name: _foodNameController.text.trim(),
          category: _selectedCategory,
          restaurantName: _restaurantNameController.text.trim().isNotEmpty 
              ? _restaurantNameController.text.trim() 
              : null,
          address: _currentAddress,
          latitude: _latitude,
          longitude: _longitude,
          date: _selectedDate,
          weather: weather.condition,
          temperature: weather.temperature,
          windSpeed: weather.windSpeed,
          rating: _rating,
        );

        final success = await Provider.of<RecommendationController>(context, listen: false)
            .saveFoodRecord(food);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('식사 기록이 저장되었습니다')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('식사 기록 저장에 실패했습니다'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식사 기록하기'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘 먹은 음식을 기록해주세요',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 날짜 선택 버튼
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                '날짜: ${DateFormat('yyyy년 MM월 dd일').format(_selectedDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 식사 시간대 선택
                      DropdownButtonFormField<String>(
                        value: _mealTime,
                        decoration: const InputDecoration(
                          labelText: '식사 시간대',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        items: _mealTimes.map((mealTime) {
                          return DropdownMenuItem(
                            value: mealTime,
                            child: Text(mealTime),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _mealTime = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 음식 이름 입력
                      TextFormField(
                        controller: _foodNameController,
                        decoration: const InputDecoration(
                          labelText: '음식 이름',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '음식 이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 음식 카테고리 선택
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: '카테고리 (아이콘 표시용)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 식당 이름 입력 (선택 사항)
                      TextFormField(
                        controller: _restaurantNameController,
                        decoration: const InputDecoration(
                          labelText: '식당 이름 (선택 사항)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 평점 입력
                      const Text(
                        '평점',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      
                      // 저장 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveFood,
                          child: const Text(
                            '저장하기',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 현재 위치 표시
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '현재 위치',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _currentAddress ?? '위치 정보를 가져올 수 없습니다',
                                      style: TextStyle(
                                        color: _currentAddress != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('위치 새로고침'),
                                onPressed: _getCurrentLocation,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 