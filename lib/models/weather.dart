class Weather {
  final String condition; // 맑음, 흐림, 비, 눈 등
  final double temperature; // 섭씨 온도
  final double windSpeed; // 풍속 (m/s)
  final double humidity; // 습도 (%)
  final DateTime timestamp; // 날씨 정보 시간

  Weather({
    required this.condition,
    required this.temperature,
    required this.windSpeed,
    required this.humidity,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'temperature': temperature,
      'windSpeed': windSpeed,
      'humidity': humidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      condition: map['condition'],
      temperature: map['temperature'],
      windSpeed: map['windSpeed'],
      humidity: map['humidity'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
} 