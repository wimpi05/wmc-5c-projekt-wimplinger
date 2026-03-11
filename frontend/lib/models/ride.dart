class Ride {
  final int id;
  final int driverUserId;
  final int? groupId;
  final String? groupName;
  final String driverUsername; 
  final String startName;
  final String endName;
  final DateTime departTime;
  final int seatsTotal;
  final int seatsOccupied;
  final double? distanceKm;
  final String? note;
  final double? pricePerSeat;
  final bool currentUserJoined;
  final DateTime createdAt;

  Ride({
    required this.id,
    required this.driverUserId,
    this.groupId,
    this.groupName,
    required this.driverUsername,
    required this.startName,
    required this.endName,
    required this.departTime,
    required this.seatsTotal,
    required this.seatsOccupied,
    this.distanceKm,
    this.note,
    this.pricePerSeat,
    this.currentUserJoined = false,
    required this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      driverUserId: json['driver_user_id'],
      groupId: json['group_id'],
      groupName: json['group_name'],
      driverUsername: json['driver_username'] ?? 'Unknown',
      startName: json['start_name'],
      endName: json['end_name'],
      departTime: DateTime.parse(json['depart_time']),
      seatsTotal: json['seats_total'],
      seatsOccupied: json['seats_occupied'] ?? 0,
      distanceKm: json['distance_km']?.toDouble(),
      note: json['note'],
      pricePerSeat: json['price_per_seat']?.toDouble(),
      currentUserJoined: json['current_user_joined'] == 1 || json['current_user_joined'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  Ride copyWith({
    int? id,
    int? driverUserId,
    int? groupId,
    String? groupName,
    String? driverUsername,
    String? startName,
    String? endName,
    DateTime? departTime,
    int? seatsTotal,
    int? seatsOccupied,
    double? distanceKm,
    String? note,
    double? pricePerSeat,
    bool? currentUserJoined,
    DateTime? createdAt,
  }) {
    return Ride(
      id: id ?? this.id,
      driverUserId: driverUserId ?? this.driverUserId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      driverUsername: driverUsername ?? this.driverUsername,
      startName: startName ?? this.startName,
      endName: endName ?? this.endName,
      departTime: departTime ?? this.departTime,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsOccupied: seatsOccupied ?? this.seatsOccupied,
      distanceKm: distanceKm ?? this.distanceKm,
      note: note ?? this.note,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      currentUserJoined: currentUserJoined ?? this.currentUserJoined,
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
      'group_id': groupId,
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