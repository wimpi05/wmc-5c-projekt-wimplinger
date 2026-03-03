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
    return Passenger(
      id: json['passenger_id'],
      rideId: json['ride_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      status: json['status'] ?? 'joined',
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  bool get isCancelled => status == 'cancelled'; 
}