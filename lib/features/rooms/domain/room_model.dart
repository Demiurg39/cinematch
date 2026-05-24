enum RoomStatus { lobby, active, voting, matched, revealed, archived, completed }

class RoomModel {
  final String id;
  final String code;
  final String name;
  final String createdBy;
  final RoomStatus status;
  final int matchThreshold;
  final DateTime createdAt;
  final List<String> participantIds;
  final bool isPrivate;
  final DateTime? timerEndAt;
  final int maxParticipants;

  const RoomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.createdBy,
    required this.status,
    required this.matchThreshold,
    required this.createdAt,
    required this.participantIds,
    this.isPrivate = false,
    this.timerEndAt,
    this.maxParticipants = 4,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      status: RoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RoomStatus.lobby,
      ),
      matchThreshold: _parseThreshold(json['match_threshold']),
      createdAt: DateTime.parse(json['created_at'] as String),
      participantIds: (json['participant_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      isPrivate: json['is_private'] as bool? ?? false,
      timerEndAt: json['timer_end_at'] != null
          ? DateTime.parse(json['timer_end_at'] as String)
          : null,
      maxParticipants: json['max_participants'] as int? ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'created_by': createdBy,
        'status': status.name,
        'match_threshold': matchThreshold,
        'created_at': createdAt.toIso8601String(),
        'is_private': isPrivate,
        if (timerEndAt != null) 'timer_end_at': timerEndAt!.toIso8601String(),
      };

  static int _parseThreshold(dynamic value) {
    if (value == null) return 2;
    if (value is int) return value;
    if (value is String) {
      switch (value) {
        case 'unanimous': return 4;
        case 'majority': return 3;
        case 'half': return 2;
        case 'matched': return 1;
        default: return int.tryParse(value) ?? 2;
      }
    }
    return 2;
  }

  static String thresholdToDbValue(int threshold) {
    switch (threshold) {
      case 4: return 'unanimous';
      case 3: return 'majority';
      case 2: return 'half';
      case 1: return 'matched';
      default: return 'half';
    }
  }
}
