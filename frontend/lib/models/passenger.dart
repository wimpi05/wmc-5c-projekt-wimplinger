class Passenger {
  final int id; 
  final int rideId;
  final int userId;
  final String username;
  final String status; 
  final DateTime joinedAt;

  Passenger({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.username,
    required this.status,
    required this.joinedAt,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    final joinedRaw = json['joined_at']?.toString();

    return Passenger(
      id: (json['passenger_id'] ?? json['id']) as int,
      rideId: json['ride_id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] ?? 'Unknown',
      status: json['status'] ?? 'joined',
      joinedAt: (joinedRaw == null || joinedRaw.isEmpty)
          ? DateTime.now()
          : DateTime.parse(joinedRaw),
    );
  }

  bool get isCancelled => status == 'cancelled'; 
}