import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../controllers/recommendation_controller.dart';
import '../models/recommendation.dart';
import '../models/weather.dart';
import 'food_input_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 추천 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecommendationController>(context, listen: false)
          .generateRecommendation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 점심 추천'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<RecommendationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return _buildLoadingView();
          } else if (controller.errorMessage != null) {
            return _buildErrorView(controller.errorMessage!);
          } else if (controller.currentRecommendation != null) {
            return _buildRecommendationView(
              controller.currentRecommendation!,
              controller.currentWeather,
            );
          } else {
            return _buildEmptyView();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FoodInputScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '오늘 먹은 음식 기록하기',
        // backgroundColor: Color.fromARGB(255, 223, 201, 211),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SpinKitDoubleBounce(
            color: Colors.blue,
            size: 60.0,
          ),
          SizedBox(height: 20),
          Text('추천 메뉴를 찾는 중...', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(errorMessage, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Provider.of<RecommendationController>(context, listen: false)
                  .generateRecommendation();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('추천 정보가 없습니다', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Provider.of<RecommendationController>(context, listen: false)
                  .generateRecommendation();
            },
            child: const Text('추천 받기'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationView(Recommendation recommendation, Weather? weather) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (weather != null) _buildWeatherInfo(recommendation, weather),
            const SizedBox(height: 30),
            const Text(
              '오늘의 추천 메뉴',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildFoodCard(recommendation),
            const SizedBox(height: 20),
            Text(
              recommendation.reason,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Provider.of<RecommendationController>(context, listen: false)
                    .generateRecommendation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다른 메뉴 추천받기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(Recommendation recommendation, Weather weather) {
    IconData weatherIcon;
    Color weatherColor;

    // 날씨 아이콘 설정
    if (weather.condition.contains('비')) {
      weatherIcon = Icons.grain;
      weatherColor = Colors.blue;
    } else if (weather.condition.contains('눈')) {
      weatherIcon = Icons.ac_unit;
      weatherColor = Colors.lightBlue;
    } else if (weather.condition.contains('소나기')) {
      weatherIcon = Icons.beach_access;
      weatherColor = Colors.blueAccent;
    } else {
      // 기본값은 맑음으로 처리
      weatherIcon = Icons.wb_sunny;
      weatherColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  recommendation.address ?? '현재 날씨',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(weatherIcon, size: 40, color: weatherColor),
                    const SizedBox(height: 8),
                    Text(weather.condition, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    const Text('기온', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('풍속', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.windSpeed.toStringAsFixed(1)}m/s',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(Recommendation recommendation) {
    // 카테고리에 따른 아이콘 및 색상 설정
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
    } else {
      iconPath = 'assets/icons/default_food.svg';
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 100,
              height: 100,
            ),
            // const SizedBox(height: 10),
            Text(
              recommendation.foodName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (recommendation.restaurantName != null) ...[
              const SizedBox(height: 7),
              Text(
                recommendation.restaurantName!,
                style: const TextStyle(fontSize: 20, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 