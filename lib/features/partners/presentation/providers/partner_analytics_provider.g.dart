// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$partnerAnalyticsRepositoryHash() =>
    r'e192ef360f50d0c6820ab8711e572a85f47e6408';

/// See also [partnerAnalyticsRepository].
@ProviderFor(partnerAnalyticsRepository)
final partnerAnalyticsRepositoryProvider =
    AutoDisposeProvider<PartnerAnalyticsRepository>.internal(
      partnerAnalyticsRepository,
      name: r'partnerAnalyticsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$partnerAnalyticsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartnerAnalyticsRepositoryRef =
    AutoDisposeProviderRef<PartnerAnalyticsRepository>;
String _$togetherHistoryHash() => r'9575be8f341e329cb2b9f3eef6ab4d392a56abf2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$TogetherHistory
    extends BuildlessAutoDisposeAsyncNotifier<List> {
  late final String partnerLinkId;

  FutureOr<List> build(String partnerLinkId);
}

/// See also [TogetherHistory].
@ProviderFor(TogetherHistory)
const togetherHistoryProvider = TogetherHistoryFamily();

/// See also [TogetherHistory].
class TogetherHistoryFamily extends Family<AsyncValue<List>> {
  /// See also [TogetherHistory].
  const TogetherHistoryFamily();

  /// See also [TogetherHistory].
  TogetherHistoryProvider call(String partnerLinkId) {
    return TogetherHistoryProvider(partnerLinkId);
  }

  @override
  TogetherHistoryProvider getProviderOverride(
    covariant TogetherHistoryProvider provider,
  ) {
    return call(provider.partnerLinkId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'togetherHistoryProvider';
}

/// See also [TogetherHistory].
class TogetherHistoryProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TogetherHistory, List> {
  /// See also [TogetherHistory].
  TogetherHistoryProvider(String partnerLinkId)
    : this._internal(
        () => TogetherHistory()..partnerLinkId = partnerLinkId,
        from: togetherHistoryProvider,
        name: r'togetherHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$togetherHistoryHash,
        dependencies: TogetherHistoryFamily._dependencies,
        allTransitiveDependencies:
            TogetherHistoryFamily._allTransitiveDependencies,
        partnerLinkId: partnerLinkId,
      );

  TogetherHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.partnerLinkId,
  }) : super.internal();

  final String partnerLinkId;

  @override
  FutureOr<List> runNotifierBuild(covariant TogetherHistory notifier) {
    return notifier.build(partnerLinkId);
  }

  @override
  Override overrideWith(TogetherHistory Function() create) {
    return ProviderOverride(
      origin: this,
      override: TogetherHistoryProvider._internal(
        () => create()..partnerLinkId = partnerLinkId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        partnerLinkId: partnerLinkId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TogetherHistory, List>
  createElement() {
    return _TogetherHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TogetherHistoryProvider &&
        other.partnerLinkId == partnerLinkId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, partnerLinkId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TogetherHistoryRef on AutoDisposeAsyncNotifierProviderRef<List> {
  /// The parameter `partnerLinkId` of this provider.
  String get partnerLinkId;
}

class _TogetherHistoryProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TogetherHistory, List>
    with TogetherHistoryRef {
  _TogetherHistoryProviderElement(super.provider);

  @override
  String get partnerLinkId => (origin as TogetherHistoryProvider).partnerLinkId;
}

String _$genreHarmonyHash() => r'92cc20681f7adc7abde95111acb7153bd51e22ce';

abstract class _$GenreHarmony
    extends BuildlessAutoDisposeAsyncNotifier<GenreHarmonyData> {
  late final String partnerLinkId;
  late final String partnerId;

  FutureOr<GenreHarmonyData> build(
    String partnerLinkId, {
    required String partnerId,
  });
}

/// See also [GenreHarmony].
@ProviderFor(GenreHarmony)
const genreHarmonyProvider = GenreHarmonyFamily();

/// See also [GenreHarmony].
class GenreHarmonyFamily extends Family<AsyncValue<GenreHarmonyData>> {
  /// See also [GenreHarmony].
  const GenreHarmonyFamily();

  /// See also [GenreHarmony].
  GenreHarmonyProvider call(String partnerLinkId, {required String partnerId}) {
    return GenreHarmonyProvider(partnerLinkId, partnerId: partnerId);
  }

  @override
  GenreHarmonyProvider getProviderOverride(
    covariant GenreHarmonyProvider provider,
  ) {
    return call(provider.partnerLinkId, partnerId: provider.partnerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'genreHarmonyProvider';
}

/// See also [GenreHarmony].
class GenreHarmonyProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<GenreHarmony, GenreHarmonyData> {
  /// See also [GenreHarmony].
  GenreHarmonyProvider(String partnerLinkId, {required String partnerId})
    : this._internal(
        () => GenreHarmony()
          ..partnerLinkId = partnerLinkId
          ..partnerId = partnerId,
        from: genreHarmonyProvider,
        name: r'genreHarmonyProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$genreHarmonyHash,
        dependencies: GenreHarmonyFamily._dependencies,
        allTransitiveDependencies:
            GenreHarmonyFamily._allTransitiveDependencies,
        partnerLinkId: partnerLinkId,
        partnerId: partnerId,
      );

  GenreHarmonyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.partnerLinkId,
    required this.partnerId,
  }) : super.internal();

  final String partnerLinkId;
  final String partnerId;

  @override
  FutureOr<GenreHarmonyData> runNotifierBuild(covariant GenreHarmony notifier) {
    return notifier.build(partnerLinkId, partnerId: partnerId);
  }

  @override
  Override overrideWith(GenreHarmony Function() create) {
    return ProviderOverride(
      origin: this,
      override: GenreHarmonyProvider._internal(
        () => create()
          ..partnerLinkId = partnerLinkId
          ..partnerId = partnerId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        partnerLinkId: partnerLinkId,
        partnerId: partnerId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<GenreHarmony, GenreHarmonyData>
  createElement() {
    return _GenreHarmonyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GenreHarmonyProvider &&
        other.partnerLinkId == partnerLinkId &&
        other.partnerId == partnerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, partnerLinkId.hashCode);
    hash = _SystemHash.combine(hash, partnerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GenreHarmonyRef on AutoDisposeAsyncNotifierProviderRef<GenreHarmonyData> {
  /// The parameter `partnerLinkId` of this provider.
  String get partnerLinkId;

  /// The parameter `partnerId` of this provider.
  String get partnerId;
}

class _GenreHarmonyProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<GenreHarmony, GenreHarmonyData>
    with GenreHarmonyRef {
  _GenreHarmonyProviderElement(super.provider);

  @override
  String get partnerLinkId => (origin as GenreHarmonyProvider).partnerLinkId;
  @override
  String get partnerId => (origin as GenreHarmonyProvider).partnerId;
}

String _$timeSpentHash() => r'08a8a35ed9a6e1c3cf4f838a07e4fe075d076153';

abstract class _$TimeSpent extends BuildlessAutoDisposeAsyncNotifier<Duration> {
  late final String partnerLinkId;

  FutureOr<Duration> build(String partnerLinkId);
}

/// See also [TimeSpent].
@ProviderFor(TimeSpent)
const timeSpentProvider = TimeSpentFamily();

/// See also [TimeSpent].
class TimeSpentFamily extends Family<AsyncValue<Duration>> {
  /// See also [TimeSpent].
  const TimeSpentFamily();

  /// See also [TimeSpent].
  TimeSpentProvider call(String partnerLinkId) {
    return TimeSpentProvider(partnerLinkId);
  }

  @override
  TimeSpentProvider getProviderOverride(covariant TimeSpentProvider provider) {
    return call(provider.partnerLinkId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'timeSpentProvider';
}

/// See also [TimeSpent].
class TimeSpentProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TimeSpent, Duration> {
  /// See also [TimeSpent].
  TimeSpentProvider(String partnerLinkId)
    : this._internal(
        () => TimeSpent()..partnerLinkId = partnerLinkId,
        from: timeSpentProvider,
        name: r'timeSpentProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$timeSpentHash,
        dependencies: TimeSpentFamily._dependencies,
        allTransitiveDependencies: TimeSpentFamily._allTransitiveDependencies,
        partnerLinkId: partnerLinkId,
      );

  TimeSpentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.partnerLinkId,
  }) : super.internal();

  final String partnerLinkId;

  @override
  FutureOr<Duration> runNotifierBuild(covariant TimeSpent notifier) {
    return notifier.build(partnerLinkId);
  }

  @override
  Override overrideWith(TimeSpent Function() create) {
    return ProviderOverride(
      origin: this,
      override: TimeSpentProvider._internal(
        () => create()..partnerLinkId = partnerLinkId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        partnerLinkId: partnerLinkId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TimeSpent, Duration> createElement() {
    return _TimeSpentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimeSpentProvider && other.partnerLinkId == partnerLinkId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, partnerLinkId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TimeSpentRef on AutoDisposeAsyncNotifierProviderRef<Duration> {
  /// The parameter `partnerLinkId` of this provider.
  String get partnerLinkId;
}

class _TimeSpentProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TimeSpent, Duration>
    with TimeSpentRef {
  _TimeSpentProviderElement(super.provider);

  @override
  String get partnerLinkId => (origin as TimeSpentProvider).partnerLinkId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
