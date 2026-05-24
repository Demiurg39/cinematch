import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/partner_analytics_repository.dart';
import '../../domain/genre_harmony_data.dart';

part 'partner_analytics_provider.g.dart';

@riverpod
PartnerAnalyticsRepository partnerAnalyticsRepository(PartnerAnalyticsRepositoryRef ref) {
  return PartnerAnalyticsRepository();
}

@riverpod
class TogetherHistory extends _$TogetherHistory {
  @override
  Future<List> build(String partnerLinkId) async {
    return ref.read(partnerAnalyticsRepositoryProvider).getTogetherHistory(partnerLinkId);
  }
}

@riverpod
class GenreHarmony extends _$GenreHarmony {
  @override
  Future<GenreHarmonyData> build(String partnerLinkId, {required String partnerId}) async {
    return ref.read(partnerAnalyticsRepositoryProvider).getIndividualGenreHarmony(
      partnerLinkId: partnerLinkId,
      partnerId: partnerId,
    );
  }
}

@riverpod
class TimeSpent extends _$TimeSpent {
  @override
  Future<Duration> build(String partnerLinkId) async {
    return ref.read(partnerAnalyticsRepositoryProvider).getTimeSpent(partnerLinkId);
  }
}