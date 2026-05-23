import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/partner_model.dart';

class PartnersRepository {
  final SupabaseClient _client;
  PartnersRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  PartnerId resolvePartnerId(Map<String, dynamic> json, String currentUserId) {
    final userA = json['user_a_id'] as String;
    final userB = json['user_b_id'] as String;
    final partnerId = userA == currentUserId ? userB : userA;
    return PartnerId._(partnerId: partnerId, userAId: userA, userBId: userB);
  }

  Future<PartnerModel> sendPartnerRequest(String partnerUsername) async {
    final code = _generateInviteCode();
    final userId = currentUserId!;

    final partner = await _client.from('users').select('id, username').eq('username', partnerUsername).maybeSingle();
    if (partner == null) throw Exception('User not found');

    final partnerId = partner['id'] as String;

    final response = await _client.from('partners').insert({
      'user_a_id': userId,
      'user_b_id': partnerId,
      'status': 'pending',
      'invite_code': code,
    }).select().single();

    return PartnerModel.fromJson(
      {...response, 'partner_username': partner['username']},
      currentUserId: userId,
    );
  }

  Future<void> acceptPartnerRequest(String partnerUserId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partners').update({'status': 'active'})
        .or('and(user_a_id.eq.$partnerUserId,user_b_id.eq.$uid),and(user_a_id.eq.$uid,user_b_id.eq.$partnerUserId)');
  }

  Future<void> rejectPartnerRequest(String partnerUserId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partners').delete()
        .or('and(user_a_id.eq.$partnerUserId,user_b_id.eq.$uid),and(user_a_id.eq.$uid,user_b_id.eq.$partnerUserId)');
  }

  Future<void> removePartner(String partnerUserId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partners').delete()
        .or('and(user_a_id.eq.$partnerUserId,user_b_id.eq.$uid),and(user_a_id.eq.$uid,user_b_id.eq.$partnerUserId)');
  }

  Future<List<PartnerModel>> getPartners() async {
    final userId = currentUserId!;
    final response = await _client.from('partners').select()
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId');

    final result = <PartnerModel>[];
    for (final json in response) {
      final pid = resolvePartnerId(json, userId);
      String username = 'Unknown';
      try {
        final user = await _client.from('users').select('username').eq('id', pid.partnerId).maybeSingle();
        username = (user?['username'] as String?) ?? 'Unknown';
      } catch (_) {}
      result.add(PartnerModel.fromJson({...json, 'partner_username': username}, currentUserId: userId));
    }
    return result;
  }

  Stream<List<PartnerModel>> watchPartners() {
    final userId = currentUserId!;
    return _client.from('partners').stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final result = <PartnerModel>[];
          for (final json in data) {
            if (json['user_a_id'] != userId && json['user_b_id'] != userId) continue;
            final pid = resolvePartnerId(json, userId);
            String username = 'Unknown';
            try {
              final user = await _client.from('users').select('username').eq('id', pid.partnerId).maybeSingle();
              username = (user?['username'] as String?) ?? 'Unknown';
            } catch (_) {}
            result.add(PartnerModel.fromJson({...json, 'partner_username': username}, currentUserId: userId));
          }
          return result;
        });
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(8, (i) => chars[(now ~/ (i + 1)) % chars.length]).join();
  }
}

class PartnerId {
  final String partnerId;
  final String userAId;
  final String userBId;
  PartnerId._({required this.partnerId, required this.userAId, required this.userBId});
}