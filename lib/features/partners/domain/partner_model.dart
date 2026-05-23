enum PartnerStatus { pending, active, blocked }

class PartnerModel {
  final String id;
  final String partnerId;
  final String partnerUsername;
  final PartnerStatus status;
  final String? inviteCode;
  final DateTime linkedAt;

  const PartnerModel({
    required this.id,
    required this.partnerId,
    required this.partnerUsername,
    required this.status,
    this.inviteCode,
    required this.linkedAt,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    final userA = json['user_a_id'] as String;
    final userB = json['user_b_id'] as String;
    final partnerId = userA == currentUserId ? userB : userA;

    return PartnerModel(
      id: json['id'] as String,
      partnerId: partnerId,
      partnerUsername: json['partner_username'] as String? ?? 'Unknown',
      status: PartnerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PartnerStatus.pending,
      ),
      inviteCode: json['invite_code'] as String?,
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'] as String)
          : DateTime.now(),
    );
  }
}
