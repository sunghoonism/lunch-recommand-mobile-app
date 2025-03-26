import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'controllers/recommendation_controller.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 애드몹 초기화
  // iOS에서는 코드에서 앱 ID를 설정해야 함
  if (Platform.isIOS) {
    MobileAds.instance.initialize().then((initializationStatus) {
      // iOS에서 앱 ID 설정
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: []),
      );
    });
  } else {
    // Android에서는 매니페스트에서 설정
    MobileAds.instance.initialize();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecommendationController(),
      child: MaterialApp(
        title: '점심 추천 앱',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansKrTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ko', 'KR'),
        home: const HomeScreen(),
      ),
    );
  }
}
