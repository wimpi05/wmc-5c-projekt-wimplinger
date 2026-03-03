class Ride {
  final int id;
  final int driverUserId;
  final String driverUsername; 
  final String startName;
  final String endName;
  final DateTime departTime;
  final int seatsTotal;
  final int seatsOccupied;
  final double? distanceKm;
  final String? note;
  final double? pricePerSeat;
  final DateTime createdAt;

  Ride({
    required this.id,
    required this.driverUserId,
    required this.driverUsername,
    required this.startName,
    required this.endName,
    required this.departTime,
    required this.seatsTotal,
    required this.seatsOccupied,
    this.distanceKm,
    this.note,
    this.pricePerSeat,
    required this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      driverUserId: json['driver_user_id'],
      driverUsername: json['driver_username'] ?? 'Unknown',
      startName: json['start_name'],
      endName: json['end_name'],
      departTime: DateTime.parse(json['depart_time']),
      seatsTotal: json['seats_total'],
      seatsOccupied: json['seats_occupied'] ?? 0,
      distanceKm: json['distance_km']?.toDouble(),
      note: json['note'],
      pricePerSeat: json['price_per_seat']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  Ride copyWith({
    int? id,
    int? driverUserId,
    String? driverUsername,
    String? startName,
    String? endName,
    DateTime? departTime,
    int? seatsTotal,
    int? seatsOccupied,
    double? distanceKm,
    String? note,
    double? pricePerSeat,
    DateTime? createdAt,
  }) {
    return Ride(
      id: id ?? this.id,
      driverUserId: driverUserId ?? this.driverUserId,
      driverUsername: driverUsername ?? this.driverUsername,
      startName: startName ?? this.startName,
      endName: endName ?? this.endName,
      departTime: departTime ?? this.departTime,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsOccupied: seatsOccupied ?? this.seatsOccupied,
      distanceKm: distanceKm ?? this.distanceKm,
      note: note ?? this.note,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get seatsAvailable => seatsTotal - seatsOccupied; 
  
  double get occupancyRate => seatsTotal > 0 ? seatsOccupied / seatsTotal : 0; 

  bool get isFull => seatsOccupied >= seatsTotal; 

  bool get isToday {
    final now = DateTime.now();
    return departTime.year == now.year &&
        departTime.month == now.month &&
        departTime.day == now.day;
  } 

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_user_id': driverUserId,
      'start_name': startName,
      'end_name': endName,
      'depart_time': departTime.toIso8601String(),
      'seats_total': seatsTotal,
      'distance_km': distanceKm,
      'note': note,
      'price_per_seat': pricePerSeat,
    };
  }
}