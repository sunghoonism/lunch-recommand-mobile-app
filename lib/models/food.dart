class Food {
  final int? id;
  final String name;
  final String category;
  final String? restaurantName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime date;
  final String? weather;
  final double? temperature;
  final double? windSpeed;
  final int rating;

  Food({
    this.id,
    required this.name,
    required this.category,
    this.restaurantName,
    this.address,
    this.latitude,
    this.longitude,
    required this.date,
    this.weather,
    this.temperature,
    this.windSpeed,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'restaurantName': restaurantName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'date': date.toIso8601String(),
      'weather': weather,
      'temperature': temperature,
      'windSpeed': windSpeed,
      'rating': rating,
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      restaurantName: map['restaurantName'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      date: DateTime.parse(map['date']),
      weather: map['weather'],
      temperature: map['temperature'],
      windSpeed: map['windSpeed'],
      rating: map['rating'],
    );
  }
} 