import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../controllers/recommendation_controller.dart';
import '../models/food.dart';
import '../models/recommendation.dart';
import '../config/secrets.dart';
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
  
  // 광고 관련 변수
  BannerAd? _foodBannerAd;
  BannerAd? _recommendationBannerAd;
  bool _isFoodAdLoaded = false;
  bool _isRecommendationAdLoaded = false;
  
  // 페이지네이션 관련 변수
  static const int _pageSize = 10;
  int _foodPage = 0;
  int _recommendationPage = 0;
  bool _hasMoreFoods = true;
  bool _hasMoreRecommendations = true;
  bool _isLoadingMoreFoods = false;
  bool _isLoadingMoreRecommendations = false;
  
  // 카테고리별 아이콘 색상 맵
  final Map<String, Color> _categoryColors = {
    '한식': Colors.red[50]!,
    '중식': Colors.orange[50]!,
    '일식': Colors.blue[50]!,
    '양식': Colors.brown[50]!,
    '분식': Colors.deepOrange[50]!,
    '패스트푸드': Colors.amber[50]!,
    '카페/디저트': Colors.brown[50]!,
  };
  
  // 카테고리별 아이콘 맵
  final Map<String, IconData> _categoryIcons = {
    '한식': Icons.rice_bowl,
    '중식': Icons.ramen_dining,
    '일식': Icons.set_meal,
    '양식': Icons.dinner_dining,
    '분식': Icons.bento,
    '패스트푸드': Icons.fastfood,
    '카페/디저트': Icons.icecream,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    
    // 탭 변경 리스너 추가
    _tabController.addListener(_handleTabChange);
    
    // 광고 초기화
    MobileAds.instance.initialize();
    _loadFoodBannerAd();
    _loadRecommendationBannerAd();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _foodBannerAd?.dispose();
    _recommendationBannerAd?.dispose();
    super.dispose();
  }
  
  // 식사 기록 탭 광고 로드
  void _loadFoodBannerAd() {
    _foodBannerAd = BannerAd(
      adUnitId: _getAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isFoodAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _foodBannerAd?.load();
  }
  
  // 추천 기록 탭 광고 로드
  void _loadRecommendationBannerAd() {
    _recommendationBannerAd = BannerAd(
      adUnitId: _getAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isRecommendationAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _recommendationBannerAd?.load();
  }
  
  // 광고 ID 가져오기 (테스트 ID 또는 실제 ID)
  String _getAdUnitId() {
    // 디버그 모드에서는 테스트 광고 ID 사용
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // 테스트 광고 ID
    }
    // 릴리즈 모드에서는 실제 광고 ID 사용
    return Secrets.adMobBannerAdUnitId;
  }
  
  // 탭 변경 처리
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // 스크롤 위치 초기화
      if (_tabController.index == 0 && _foods.isEmpty && !_isLoading) {
        _loadMoreFoods();
      } else if (_tabController.index == 1 && _recommendations.isEmpty && !_isLoading) {
        _loadMoreRecommendations();
      }
    }
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foodPage = 0;
      _recommendationPage = 0;
      _foods = [];
      _recommendations = [];
      _hasMoreFoods = true;
      _hasMoreRecommendations = true;
    });

    try {
      await _loadMoreFoods();
      
      // 현재 활성화된 탭이 추천 기록 탭이면 추천 데이터도 로드
      if (_tabController.index == 1) {
        await _loadMoreRecommendations();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }
  
  // 더 많은 식사 기록 로드
  Future<void> _loadMoreFoods() async {
    if (_isLoadingMoreFoods || !_hasMoreFoods) return;
    
    setState(() {
      _isLoadingMoreFoods = true;
    });
    
    try {
      final controller = Provider.of<RecommendationController>(context, listen: false);
      final newFoods = await controller.getFoodsByPage(_foodPage, _pageSize);
      
      setState(() {
        _foods.addAll(newFoods);
        _foodPage++;
        _hasMoreFoods = newFoods.length >= _pageSize;
        _isLoadingMoreFoods = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _isLoadingMoreFoods = false;
      });
    }
  }
  
  // 더 많은 추천 기록 로드
  Future<void> _loadMoreRecommendations() async {
    if (_isLoadingMoreRecommendations || !_hasMoreRecommendations) return;
    
    setState(() {
      _isLoadingMoreRecommendations = true;
    });
    
    try {
      final controller = Provider.of<RecommendationController>(context, listen: false);
      final newRecommendations = await controller.getRecommendationsByPage(_recommendationPage, _pageSize);
      
      setState(() {
        _recommendations.addAll(newRecommendations);
        _recommendationPage++;
        _hasMoreRecommendations = newRecommendations.length >= _pageSize;
        _isLoadingMoreRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _isLoadingMoreRecommendations = false;
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
        onPressed: _loadInitialData,
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
            onPressed: _loadInitialData,
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

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                _loadMoreFoods();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: _foods.length + (_hasMoreFoods ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _foods.length) {
                  return _buildLoadingIndicator();
                }
                
                final food = _foods[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: () => _navigateToFoodEdit(food),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // 간소화된 아이콘 표시
                          _buildSimpleCategoryIcon(food.category),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (food.restaurantName != null)
                                  Text(
                                    food.restaurantName!,
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                Text(
                                  DateFormat('yyyy년 MM월 dd일').format(food.date),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          // 별점 표시 최적화
                          _buildRatingStars(food.rating),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _showDeleteFoodConfirmDialog(food),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 광고 표시
        if (_isFoodAdLoaded && _foodBannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _foodBannerAd!.size.width.toDouble(),
            height: _foodBannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _foodBannerAd!),
          ),
      ],
    );
  }

  Widget _buildRecommendationHistoryTab() {
    if (_recommendations.isEmpty) {
      return const Center(
        child: Text('추천 기록이 없습니다'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                _loadMoreRecommendations();
              }
              return false;
            },
            child: ListView.builder(
              itemCount: _recommendations.length + (_hasMoreRecommendations ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _recommendations.length) {
                  return _buildLoadingIndicator();
                }
                
                final recommendation = _recommendations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 간소화된 아이콘 표시
                            _buildSimpleCategoryIcon(recommendation.foodCategory ?? '기타'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation.foodName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('MM/dd HH:mm').format(recommendation.timestamp),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteRecommendation(recommendation, index),
                              padding: const EdgeInsets.only(left: 8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        if (recommendation.restaurantName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            recommendation.restaurantName!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          recommendation.reason,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 광고 표시
        if (_isRecommendationAdLoaded && _recommendationBannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _recommendationBannerAd!.size.width.toDouble(),
            height: _recommendationBannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _recommendationBannerAd!),
          ),
      ],
    );
  }
  
  // 로딩 인디케이터 위젯
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      ),
    );
  }
  
  // 간소화된 카테고리 아이콘 위젯
  Widget _buildSimpleCategoryIcon(String category) {
    final color = _categoryColors[category] ?? Colors.grey[200]!;
    final icon = _categoryIcons[category] ?? Icons.restaurant;
    
    return CircleAvatar(
      backgroundColor: color,
      radius: 16,
      child: Icon(icon, size: 16, color: Colors.black87),
    );
  }
  
  // 최적화된 별점 표시 위젯
  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
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
      _loadInitialData();
    }
  }

  // 식사 기록 삭제 확인 다이얼로그
  Future<void> _showDeleteFoodConfirmDialog(Food food) async {
    final result = await showDialog<bool>(
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
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    
    if (result == true && food.id != null) {
      await Provider.of<RecommendationController>(context, listen: false)
          .deleteFoodRecord(food.id!);
      
      // UI에서 즉시 제거
      setState(() {
        _foods.removeWhere((item) => item.id == food.id);
      });
    }
  }

  // 추천 기록 삭제
  Future<void> _deleteRecommendation(Recommendation recommendation, int index) async {
    final result = await showDialog<bool>(
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
    
    if (result == true) {
      // UI에서 즉시 제거
      setState(() {
        _recommendations.removeAt(index);
      });
      
      // 백그라운드에서 데이터베이스 업데이트
      if (recommendation.id != null) {
        await Provider.of<RecommendationController>(context, listen: false)
            .deleteRecommendation(recommendation.id!);
      }
    }
  }
} 