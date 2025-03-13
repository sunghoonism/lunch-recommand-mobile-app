import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/recommendation_controller.dart';
import '../models/food.dart';

class FoodEditScreen extends StatefulWidget {
  final int foodId;

  const FoodEditScreen({Key? key, required this.foodId}) : super(key: key);

  @override
  State<FoodEditScreen> createState() => _FoodEditScreenState();
}

class _FoodEditScreenState extends State<FoodEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  
  String _selectedCategory = '한식';
  int _rating = 3;
  bool _isLoading = true;
  Food? _food;
  DateTime _selectedDate = DateTime.now();
  
  final List<String> _categories = [
    '한식', '중식', '일식', '양식', '분식', 
    '패스트푸드', '카페/디저트', '기타'
  ];

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  // 음식 데이터 로드
  Future<void> _loadFoodData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final food = await Provider.of<RecommendationController>(context, listen: false)
          .getFoodById(widget.foodId);
      
      if (food != null) {
        setState(() {
          _food = food;
          _foodNameController.text = food.name;
          _selectedCategory = food.category;
          _restaurantNameController.text = food.restaurantName ?? '';
          _rating = food.rating;
          _selectedDate = food.date;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식사 기록을 찾을 수 없습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
      Navigator.pop(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 음식 기록 수정
  Future<void> _updateFood() async {
    if (_formKey.currentState!.validate() && _food != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedFood = Food(
          id: _food!.id,
          name: _foodNameController.text.trim(),
          category: _selectedCategory,
          restaurantName: _restaurantNameController.text.trim().isNotEmpty 
              ? _restaurantNameController.text.trim() 
              : null,
          address: _food!.address,
          latitude: _food!.latitude,
          longitude: _food!.longitude,
          date: _selectedDate,
          weather: _food!.weather,
          temperature: _food!.temperature,
          windSpeed: _food!.windSpeed,
          rating: _rating,
        );

        final success = await Provider.of<RecommendationController>(context, listen: false)
            .updateFoodRecord(updatedFood);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('식사 기록이 수정되었습니다')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('식사 기록 수정에 실패했습니다')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
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
        title: const Text('식사 기록 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmDialog(),
            tooltip: '삭제',
          ),
        ],
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
                      if (_food != null) ...[
                        // 날짜 표시 (수정 불가)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.shade200, // 비활성화된 느낌을 주기 위한 배경색
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 12),
                                  Text(
                                    '날짜: ${DateFormat('yyyy년 MM월 dd일').format(_selectedDate)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '날짜와 시각에 따라 날씨가 달라지므로 수정할 수 없습니다.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
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
                      const SizedBox(height: 24),
                      
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
                          onPressed: _updateFood,
                          child: const Text(
                            '수정하기',
                            style: TextStyle(fontSize: 18),
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

  // 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('식사 기록 삭제'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('이 식사 기록을 삭제하시겠습니까?'),
                Text('삭제된 기록은 복구할 수 없습니다.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFood();
              },
            ),
          ],
        );
      },
    );
  }

  // 음식 기록 삭제
  Future<void> _deleteFood() async {
    if (_food == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<RecommendationController>(context, listen: false)
          .deleteFoodRecord(_food!.id!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식사 기록이 삭제되었습니다')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식사 기록 삭제에 실패했습니다')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}