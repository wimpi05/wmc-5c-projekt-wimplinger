class Group {
  final int id;
  final String name;
  final String code;
  final int ownerUserId;
  final int membersCount;
  final bool isOwner;
  final String? currentUserRole;

  Group({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerUserId,
    required this.membersCount,
    required this.isOwner,
    this.currentUserRole,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      ownerUserId: json['owner_user_id'] as int,
      membersCount: (json['members_count'] ?? 0) as int,
      isOwner: (json['is_owner'] == 1) || (json['is_owner'] == true),
      currentUserRole: json['current_user_role'] as String?,
    );
  }
}
