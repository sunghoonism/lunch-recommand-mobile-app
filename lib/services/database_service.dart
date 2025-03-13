import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food.dart';
import '../models/recommendation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'lunch_recommender.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 버전 1에서 2로 업그레이드: recommendations 테이블에 foodCategory 필드 추가
      await db.execute('ALTER TABLE recommendations ADD COLUMN foodCategory TEXT');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        restaurantName TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        date TEXT NOT NULL,
        weather TEXT,
        temperature REAL,
        windSpeed REAL,
        rating INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recommendations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        foodName TEXT NOT NULL,
        foodCategory TEXT,
        restaurantName TEXT,
        address TEXT,
        latitude REAL,
        longitude REAL,
        confidence REAL NOT NULL,
        reason TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // 음식 데이터 추가
  Future<int> insertFood(Food food) async {
    final db = await database;
    return await db.insert('foods', food.toMap());
  }

  // 음식 데이터 수정
  Future<int> updateFood(Food food) async {
    final db = await database;
    return await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  // 음식 데이터 삭제
  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 특정 ID의 음식 데이터 가져오기
  Future<Food?> getFoodById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Food.fromMap(maps.first);
    }
    return null;
  }

  // 모든 음식 데이터 가져오기
  Future<List<Food>> getFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foods', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return Food.fromMap(maps[i]);
    });
  }

  // 특정 기간 내의 음식 데이터 가져오기
  Future<List<Food>> getFoodsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Food.fromMap(maps[i]);
    });
  }

  // 특정 날씨 조건의 음식 데이터 가져오기
  Future<List<Food>> getFoodsByWeather(String weather) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'weather = ?',
      whereArgs: [weather],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Food.fromMap(maps[i]);
    });
  }

  // 특정 온도 범위의 음식 데이터 가져오기
  Future<List<Food>> getFoodsByTemperatureRange(double minTemp, double maxTemp) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'temperature BETWEEN ? AND ?',
      whereArgs: [minTemp, maxTemp],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Food.fromMap(maps[i]);
    });
  }

  // 추천 결과 저장
  Future<int> insertRecommendation(Recommendation recommendation) async {
    final db = await database;
    return await db.insert('recommendations', recommendation.toMap());
  }

  // 추천 결과 삭제
  Future<int> deleteRecommendation(int id) async {
    final db = await database;
    return await db.delete(
      'recommendations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 최근 추천 결과 가져오기
  Future<List<Recommendation>> getRecentRecommendations(int limit) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recommendations',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) {
      return Recommendation.fromMap(maps[i]);
    });
  }
} 