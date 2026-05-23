import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/partner_analytics_repository.dart';

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
  Future<Map<String, double>> build(String partnerLinkId) async {
    return ref.read(partnerAnalyticsRepositoryProvider).getGenreHarmony(partnerLinkId);
  }
}

@riverpod
class TimeSpent extends _$TimeSpent {
  @override
  Future<Duration> build(String partnerLinkId) async {
    return ref.read(partnerAnalyticsRepositoryProvider).getTimeSpent(partnerLinkId);
  }
}