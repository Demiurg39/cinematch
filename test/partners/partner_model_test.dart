import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/partners/domain/partner_model.dart';

void main() {
  group('PartnerModel', () {
    test('fromJson creates PartnerModel as user_a', () {
      final json = {
        'id': 'partner-123',
        'user_a_id': 'current-user',
        'user_b_id': 'user-456',
        'partner_username': 'johndoe',
        'status': 'active',
        'invite_code': 'ABC12345',
        'linked_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json, currentUserId: 'current-user');

      expect(partner.id, 'partner-123');
      expect(partner.partnerId, 'user-456');
      expect(partner.partnerUsername, 'johndoe');
      expect(partner.status, PartnerStatus.active);
      expect(partner.inviteCode, 'ABC12345');
    });

    test('fromJson creates PartnerModel as user_b', () {
      final json = {
        'id': 'partner-123',
        'user_a_id': 'user-456',
        'user_b_id': 'current-user',
        'partner_username': 'johndoe',
        'status': 'active',
        'invite_code': 'ABC12345',
        'linked_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json, currentUserId: 'current-user');

      expect(partner.id, 'partner-123');
      expect(partner.partnerId, 'user-456');
      expect(partner.partnerUsername, 'johndoe');
      expect(partner.status, PartnerStatus.active);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'partner-123',
        'user_a_id': 'current-user',
        'user_b_id': 'user-456',
        'status': 'pending',
        'linked_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json, currentUserId: 'current-user');

      expect(partner.id, 'partner-123');
      expect(partner.partnerUsername, 'Unknown');
      expect(partner.inviteCode, null);
    });

    test('fromJson defaults to pending status', () {
      final json = {
        'id': 'partner-123',
        'user_a_id': 'current-user',
        'user_b_id': 'user-456',
        'partner_username': 'janedoe',
        'linked_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json, currentUserId: 'current-user');

      expect(partner.status, PartnerStatus.pending);
    });
  });
}