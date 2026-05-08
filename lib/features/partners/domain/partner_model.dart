enum PartnerStatus { pending, active, blocked }

class PartnerModel {
  final String id;
  final String partnerId;
  final String partnerUsername;
  final PartnerStatus status;
  final String? inviteCode;
  final DateTime createdAt;

  const PartnerModel({
    required this.id,
    required this.partnerId,
    required this.partnerUsername,
    required this.status,
    this.inviteCode,
    required this.createdAt,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String,
      partnerId: json['partner_id'] as String,
      partnerUsername: json['partner_username'] as String? ?? 'Unknown',
      status: PartnerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PartnerStatus.pending,
      ),
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'partner_id': partnerId,
        'partner_username': partnerUsername,
        'status': status.name,
        'invite_code': inviteCode,
        'created_at': createdAt.toIso8601String(),
      };
}
