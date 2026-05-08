import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/partners_repository.dart';
import '../../domain/partner_model.dart';

part 'partners_provider.g.dart';

@riverpod
PartnersRepository partnersRepository(PartnersRepositoryRef ref) {
  return PartnersRepository();
}

@riverpod
class PartnersNotifier extends _$PartnersNotifier {
  @override
  Stream<List<PartnerModel>> build() {
    return ref.read(partnersRepositoryProvider).watchPartners();
  }

  Future<void> sendRequest(String username) async {
    await ref.read(partnersRepositoryProvider).sendPartnerRequest(username);
  }

  Future<void> accept(String partnerId) async {
    await ref.read(partnersRepositoryProvider).acceptPartnerRequest(partnerId);
  }

  Future<void> reject(String partnerId) async {
    await ref.read(partnersRepositoryProvider).rejectPartnerRequest(partnerId);
  }

  Future<void> remove(String partnerId) async {
    await ref.read(partnersRepositoryProvider).removePartner(partnerId);
  }
}
