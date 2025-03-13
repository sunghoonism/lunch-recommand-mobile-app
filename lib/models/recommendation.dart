class Recommendation {
  final int? id;
  final String foodName;
  final String? foodCategory;
  final String? restaurantName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double confidence; // 추천 신뢰도 (0.0 ~ 1.0)
  final String reason; // 추천 이유
  final DateTime timestamp;

  Recommendation({
    this.id,
    required this.foodName,
    this.foodCategory,
    this.restaurantName,
    this.address,
    this.latitude,
    this.longitude,
    required this.confidence,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'foodCategory': foodCategory,
      'restaurantName': restaurantName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'confidence': confidence,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      id: map['id'],
      foodName: map['foodName'],
      foodCategory: map['foodCategory'],
      restaurantName: map['restaurantName'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      confidence: map['confidence'],
      reason: map['reason'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
} 