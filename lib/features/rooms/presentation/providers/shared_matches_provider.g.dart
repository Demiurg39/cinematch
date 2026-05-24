// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_matches_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedMatchesNotifierHash() =>
    r'a1f4dcd6728cdfa4a7fccdeb967ea3275b3ccf40';

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

abstract class _$SharedMatchesNotifier
    extends BuildlessAutoDisposeAsyncNotifier<Set<String>> {
  late final String roomId;

  FutureOr<Set<String>> build(String roomId);
}

/// See also [SharedMatchesNotifier].
@ProviderFor(SharedMatchesNotifier)
const sharedMatchesNotifierProvider = SharedMatchesNotifierFamily();

/// See also [SharedMatchesNotifier].
class SharedMatchesNotifierFamily extends Family<AsyncValue<Set<String>>> {
  /// See also [SharedMatchesNotifier].
  const SharedMatchesNotifierFamily();

  /// See also [SharedMatchesNotifier].
  SharedMatchesNotifierProvider call(String roomId) {
    return SharedMatchesNotifierProvider(roomId);
  }

  @override
  SharedMatchesNotifierProvider getProviderOverride(
    covariant SharedMatchesNotifierProvider provider,
  ) {
    return call(provider.roomId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sharedMatchesNotifierProvider';
}

/// See also [SharedMatchesNotifier].
class SharedMatchesNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          SharedMatchesNotifier,
          Set<String>
        > {
  /// See also [SharedMatchesNotifier].
  SharedMatchesNotifierProvider(String roomId)
    : this._internal(
        () => SharedMatchesNotifier()..roomId = roomId,
        from: sharedMatchesNotifierProvider,
        name: r'sharedMatchesNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sharedMatchesNotifierHash,
        dependencies: SharedMatchesNotifierFamily._dependencies,
        allTransitiveDependencies:
            SharedMatchesNotifierFamily._allTransitiveDependencies,
        roomId: roomId,
      );

  SharedMatchesNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.roomId,
  }) : super.internal();

  final String roomId;

  @override
  FutureOr<Set<String>> runNotifierBuild(
    covariant SharedMatchesNotifier notifier,
  ) {
    return notifier.build(roomId);
  }

  @override
  Override overrideWith(SharedMatchesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SharedMatchesNotifierProvider._internal(
        () => create()..roomId = roomId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        roomId: roomId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<SharedMatchesNotifier, Set<String>>
  createElement() {
    return _SharedMatchesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SharedMatchesNotifierProvider && other.roomId == roomId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, roomId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SharedMatchesNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<Set<String>> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _SharedMatchesNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          SharedMatchesNotifier,
          Set<String>
        >
    with SharedMatchesNotifierRef {
  _SharedMatchesNotifierProviderElement(super.provider);

  @override
  String get roomId => (origin as SharedMatchesNotifierProvider).roomId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
