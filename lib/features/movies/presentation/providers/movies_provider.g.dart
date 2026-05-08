// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$moviesRepositoryHash() => r'7449b0daab2a00ccb213222d128c60c746887715';

/// See also [moviesRepository].
@ProviderFor(moviesRepository)
final moviesRepositoryProvider = AutoDisposeProvider<MoviesRepository>.internal(
  moviesRepository,
  name: r'moviesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$moviesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MoviesRepositoryRef = AutoDisposeProviderRef<MoviesRepository>;
String _$popularMoviesNotifierHash() =>
    r'994c47056526b2f770b335281f37e171e378e203';

/// See also [PopularMoviesNotifier].
@ProviderFor(PopularMoviesNotifier)
final popularMoviesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      PopularMoviesNotifier,
      List<MovieModel>
    >.internal(
      PopularMoviesNotifier.new,
      name: r'popularMoviesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$popularMoviesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PopularMoviesNotifier = AutoDisposeAsyncNotifier<List<MovieModel>>;
String _$movieSearchNotifierHash() =>
    r'd82f7c6b9af71fade390f2302a7a18294dd09219';

/// See also [MovieSearchNotifier].
@ProviderFor(MovieSearchNotifier)
final movieSearchNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      MovieSearchNotifier,
      List<MovieModel>
    >.internal(
      MovieSearchNotifier.new,
      name: r'movieSearchNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$movieSearchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MovieSearchNotifier = AutoDisposeAsyncNotifier<List<MovieModel>>;
String _$cachedMoviesNotifierHash() =>
    r'908368353d964ab356afccd0d9a49b151a758117';

/// See also [CachedMoviesNotifier].
@ProviderFor(CachedMoviesNotifier)
final cachedMoviesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      CachedMoviesNotifier,
      List<MovieModel>
    >.internal(
      CachedMoviesNotifier.new,
      name: r'cachedMoviesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cachedMoviesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CachedMoviesNotifier = AutoDisposeAsyncNotifier<List<MovieModel>>;
String _$watchProvidersNotifierHash() =>
    r'7cb0f939d624820bfda8bad40c7561ab66d6c3ae';

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

abstract class _$WatchProvidersNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  late final int tmdbId;

  FutureOr<Map<String, dynamic>?> build(int tmdbId);
}

/// See also [WatchProvidersNotifier].
@ProviderFor(WatchProvidersNotifier)
const watchProvidersNotifierProvider = WatchProvidersNotifierFamily();

/// See also [WatchProvidersNotifier].
class WatchProvidersNotifierFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [WatchProvidersNotifier].
  const WatchProvidersNotifierFamily();

  /// See also [WatchProvidersNotifier].
  WatchProvidersNotifierProvider call(int tmdbId) {
    return WatchProvidersNotifierProvider(tmdbId);
  }

  @override
  WatchProvidersNotifierProvider getProviderOverride(
    covariant WatchProvidersNotifierProvider provider,
  ) {
    return call(provider.tmdbId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchProvidersNotifierProvider';
}

/// See also [WatchProvidersNotifier].
class WatchProvidersNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          WatchProvidersNotifier,
          Map<String, dynamic>?
        > {
  /// See also [WatchProvidersNotifier].
  WatchProvidersNotifierProvider(int tmdbId)
    : this._internal(
        () => WatchProvidersNotifier()..tmdbId = tmdbId,
        from: watchProvidersNotifierProvider,
        name: r'watchProvidersNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchProvidersNotifierHash,
        dependencies: WatchProvidersNotifierFamily._dependencies,
        allTransitiveDependencies:
            WatchProvidersNotifierFamily._allTransitiveDependencies,
        tmdbId: tmdbId,
      );

  WatchProvidersNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tmdbId,
  }) : super.internal();

  final int tmdbId;

  @override
  FutureOr<Map<String, dynamic>?> runNotifierBuild(
    covariant WatchProvidersNotifier notifier,
  ) {
    return notifier.build(tmdbId);
  }

  @override
  Override overrideWith(WatchProvidersNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: WatchProvidersNotifierProvider._internal(
        () => create()..tmdbId = tmdbId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tmdbId: tmdbId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    WatchProvidersNotifier,
    Map<String, dynamic>?
  >
  createElement() {
    return _WatchProvidersNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchProvidersNotifierProvider && other.tmdbId == tmdbId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tmdbId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchProvidersNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<Map<String, dynamic>?> {
  /// The parameter `tmdbId` of this provider.
  int get tmdbId;
}

class _WatchProvidersNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          WatchProvidersNotifier,
          Map<String, dynamic>?
        >
    with WatchProvidersNotifierRef {
  _WatchProvidersNotifierProviderElement(super.provider);

  @override
  int get tmdbId => (origin as WatchProvidersNotifierProvider).tmdbId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
