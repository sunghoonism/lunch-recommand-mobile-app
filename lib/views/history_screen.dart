import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/recommendation_controller.dart';
import '../models/food.dart';
import '../models/recommendation.dart';
import 'food_edit_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Food> _foods = [];
  List<Recommendation> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = Provider.of<RecommendationController>(context, listen: false);
      
      // 식사 기록 로드
      final foods = await controller.getAllFoods();
      
      // 추천 기록 로드
      final recommendations = await controller.getRecentRecommendations();
      
      setState(() {
        _foods = foods;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '식사 기록'),
            Tab(text: '추천 기록'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFoodHistoryTab(),
                    _buildRecommendationHistoryTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
        tooltip: '새로고침',
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? '알 수 없는 오류가 발생했습니다'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodHistoryTab() {
    if (_foods.isEmpty) {
      return const Center(
        child: Text('식사 기록이 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: _foods.length,
      itemBuilder: (context, index) {
        final food = _foods[index];
        return Dismissible(
          key: Key('food_${food.id}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteFoodConfirmDialog(food);
          },
          onDismissed: (direction) {
            setState(() {
              _foods.removeAt(index);
            });
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () => _navigateToFoodEdit(food),
              child: ListTile(
                leading: _getFoodCategoryIconFromFood(food),
                title: Text(food.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (food.restaurantName != null)
                      Text(food.restaurantName!),
                    Text(DateFormat('yyyy년 MM월 dd일').format(food.date)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < food.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationHistoryTab() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Text('추천 기록이 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return Dismissible(
          key: Key('recommendation_${index}'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteRecommendationConfirmDialog();
          },
          onDismissed: (direction) async {
            // 추천 기록 삭제
            if (recommendation.id != null) {
              await Provider.of<RecommendationController>(context, listen: false)
                  .deleteRecommendation(recommendation.id!);
            }
            setState(() {
              _recommendations.removeAt(index);
            });
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getFoodCategoryIcon(recommendation),
                      const SizedBox(width: 8),
                      Text(
                        recommendation.foodName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MM/dd HH:mm').format(recommendation.timestamp),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (recommendation.restaurantName != null) ...[
                    const SizedBox(height: 8),
                    Text(recommendation.restaurantName!),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    recommendation.reason,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 식사 기록 수정 화면으로 이동
  Future<void> _navigateToFoodEdit(Food food) async {
    if (food.id == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodEditScreen(foodId: food.id!),
      ),
    );
    
    if (result == true) {
      // 수정 또는 삭제 후 데이터 다시 로드
      _loadData();
    }
  }

  // 식사 기록 삭제 확인 다이얼로그
  Future<bool> _showDeleteFoodConfirmDialog(Food food) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('식사 기록 삭제'),
          content: Text('${food.name} 기록을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                if (food.id != null) {
                  await Provider.of<RecommendationController>(context, listen: false)
                      .deleteFoodRecord(food.id!);
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 추천 기록 삭제 확인 다이얼로그
  Future<bool> _showDeleteRecommendationConfirmDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('추천 기록 삭제'),
          content: const Text('이 추천 기록을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 음식 카테고리에 따른 아이콘 반환
  Widget _getFoodCategoryIcon(Recommendation recommendation) {
    String iconPath;
    
    // 카테고리 정보가 있는 경우 카테고리 기반으로 아이콘 설정
    if (recommendation.foodCategory != null) {
      switch (recommendation.foodCategory) {
        case '한식':
          iconPath = 'assets/icons/korean_food.svg';
          break;
        case '중식':
          iconPath = 'assets/icons/chinese_food.svg';
          break;
        case '일식':
          iconPath = 'assets/icons/japanese_food.svg';
          break;
        case '양식':
          iconPath = 'assets/icons/western_food.svg';
          break;
        case '분식':
          iconPath = 'assets/icons/snack_food.svg';
          break;
        case '패스트푸드':
          iconPath = 'assets/icons/fast_food.svg';
          break;
        case '카페/디저트':
          iconPath = 'assets/icons/cafe_dessert.svg';
          break;
        default:
          iconPath = 'assets/icons/default_food.svg';
          break;
      }
    } 
    // 카테고리 정보가 없는 경우 기본 아이콘 설정
    else {
      iconPath = 'assets/icons/default_food.svg';
    }
    
    return SvgPicture.asset(
      iconPath,
      width: 24,
      height: 24,
    );
  }

  // 식사 기록의 카테고리에 따른 아이콘 반환
  Widget _getFoodCategoryIconFromFood(Food food) {
    String iconPath;
    Color backgroundColor;
    
    // 카테고리 기반으로 아이콘 설정
    switch (food.category) {
      case '한식':
        iconPath = 'assets/icons/korean_food.svg';
        backgroundColor = Colors.red[50]!;
        break;
      case '중식':
        iconPath = 'assets/icons/chinese_food.svg';
        backgroundColor = Colors.orange[50]!;
        break;
      case '일식':
        iconPath = 'assets/icons/japanese_food.svg';
        backgroundColor = Colors.blue[50]!;
        break;
      case '양식':
        iconPath = 'assets/icons/western_food.svg';
        backgroundColor = Colors.brown[50]!;
        break;
      case '분식':
        iconPath = 'assets/icons/snack_food.svg';
        backgroundColor = Colors.deepOrange[50]!;
        break;
      case '패스트푸드':
        iconPath = 'assets/icons/fast_food.svg';
        backgroundColor = Colors.amber[50]!;
        break;
      case '카페/디저트':
        iconPath = 'assets/icons/cafe_dessert.svg';
        backgroundColor = Colors.brown[50]!;
        break;
      default:
        iconPath = 'assets/icons/default_food.svg';
        backgroundColor = Colors.deepPurple[50]!;
        break;
    }
    
    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: SvgPicture.asset(
        iconPath,
        width: 20,
        height: 20,
      ),
    );
  }
} 