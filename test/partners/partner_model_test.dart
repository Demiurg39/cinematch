import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/partners/domain/partner_model.dart';

void main() {
  group('PartnerModel', () {
    test('fromJson creates PartnerModel correctly', () {
      final json = {
        'id': 'partner-123',
        'partner_id': 'user-456',
        'partner_username': 'johndoe',
        'status': 'active',
        'invite_code': 'ABC12345',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json);

      expect(partner.id, 'partner-123');
      expect(partner.partnerId, 'user-456');
      expect(partner.partnerUsername, 'johndoe');
      expect(partner.status, PartnerStatus.active);
      expect(partner.inviteCode, 'ABC12345');
    });

    test('toJson creates correct map', () {
      final partner = PartnerModel(
        id: 'partner-123',
        partnerId: 'user-456',
        partnerUsername: 'johndoe',
        status: PartnerStatus.pending,
        inviteCode: 'XYZ98765',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = partner.toJson();

      expect(json['id'], 'partner-123');
      expect(json['partner_id'], 'user-456');
      expect(json['partner_username'], 'johndoe');
      expect(json['status'], 'pending');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'partner-123',
        'partner_id': 'user-456',
        'status': 'pending',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final partner = PartnerModel.fromJson(json);

      expect(partner.id, 'partner-123');
      expect(partner.partnerUsername, 'Unknown');
      expect(partner.inviteCode, null);
    });
  });
}
