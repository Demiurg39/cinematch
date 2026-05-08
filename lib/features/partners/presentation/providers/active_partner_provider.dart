import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/partner_model.dart';
import 'partners_provider.dart';

part 'active_partner_provider.g.dart';

@riverpod
class ActivePartnerNotifier extends _$ActivePartnerNotifier {
  @override
  Future<PartnerModel?> build() async {
    final partners = await ref.read(partnersRepositoryProvider).getPartners();
    return partners.where((p) => p.status == PartnerStatus.active).firstOrNull;
  }

  Future<void> setActivePartner(PartnerModel partner) async {
    state = AsyncData(partner);
  }

  void clearActivePartner() {
    state = const AsyncData(null);
  }
}
