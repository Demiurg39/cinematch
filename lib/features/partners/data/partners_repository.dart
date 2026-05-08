import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/partner_model.dart';

class PartnersRepository {
  final SupabaseClient _client;
  PartnersRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<PartnerModel> sendPartnerRequest(String partnerUsername) async {
    final code = _generateInviteCode();
    final userId = currentUserId!;

    final partner = await _client.from('users').select().eq('username', partnerUsername).maybeSingle();
    if (partner == null) throw Exception('User not found');

    final response = await _client.from('partners').insert({
      'user_id': userId,
      'partner_id': partner['id'],
      'partner_username': partnerUsername,
      'status': 'pending',
      'invite_code': code,
    }).select().single();

    return PartnerModel.fromJson(response);
  }

  Future<void> acceptPartnerRequest(String partnerId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partners').update({'status': 'active'})
        .eq('partner_id', partnerId).eq('user_id', uid);
  }

  Future<void> rejectPartnerRequest(String partnerId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partners').delete()
        .eq('partner_id', partnerId).eq('user_id', uid);
  }

  Future<void> removePartner(String partnerId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partners').delete()
        .or('and(partner_id.eq.$partnerId,user_id.eq.$uid),and(user_id.eq.$partnerId,partner_id.eq.$uid)');
  }

  Future<List<PartnerModel>> getPartners() async {
    final userId = currentUserId!;
    final response = await _client.from('partners').select()
        .or('user_id.eq.$userId,partner_id.eq.$userId');
    return response.map((json) => PartnerModel.fromJson(json)).toList();
  }

  Stream<List<PartnerModel>> watchPartners() {
    final userId = currentUserId!;
    return _client.from('partners').stream(primaryKey: ['id']).eq('user_id', userId)
        .map((data) => data.map((json) => PartnerModel.fromJson(json)).toList());
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(8, (i) => chars[(now ~/ (i + 1)) % chars.length]).join();
  }
}
