// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeRoomNotifierHash() =>
    r'3016fe0223f1f86341b94b50b1c761991f6c5aa6';

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

abstract class _$ActiveRoomNotifier
    extends BuildlessAutoDisposeStreamNotifier<RoomModel?> {
  late final String roomId;

  Stream<RoomModel?> build(String roomId);
}

/// See also [ActiveRoomNotifier].
@ProviderFor(ActiveRoomNotifier)
const activeRoomNotifierProvider = ActiveRoomNotifierFamily();

/// See also [ActiveRoomNotifier].
class ActiveRoomNotifierFamily extends Family<AsyncValue<RoomModel?>> {
  /// See also [ActiveRoomNotifier].
  const ActiveRoomNotifierFamily();

  /// See also [ActiveRoomNotifier].
  ActiveRoomNotifierProvider call(String roomId) {
    return ActiveRoomNotifierProvider(roomId);
  }

  @override
  ActiveRoomNotifierProvider getProviderOverride(
    covariant ActiveRoomNotifierProvider provider,
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
  String? get name => r'activeRoomNotifierProvider';
}

/// See also [ActiveRoomNotifier].
class ActiveRoomNotifierProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<ActiveRoomNotifier, RoomModel?> {
  /// See also [ActiveRoomNotifier].
  ActiveRoomNotifierProvider(String roomId)
    : this._internal(
        () => ActiveRoomNotifier()..roomId = roomId,
        from: activeRoomNotifierProvider,
        name: r'activeRoomNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$activeRoomNotifierHash,
        dependencies: ActiveRoomNotifierFamily._dependencies,
        allTransitiveDependencies:
            ActiveRoomNotifierFamily._allTransitiveDependencies,
        roomId: roomId,
      );

  ActiveRoomNotifierProvider._internal(
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
  Stream<RoomModel?> runNotifierBuild(covariant ActiveRoomNotifier notifier) {
    return notifier.build(roomId);
  }

  @override
  Override overrideWith(ActiveRoomNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ActiveRoomNotifierProvider._internal(
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
  AutoDisposeStreamNotifierProviderElement<ActiveRoomNotifier, RoomModel?>
  createElement() {
    return _ActiveRoomNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveRoomNotifierProvider && other.roomId == roomId;
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
mixin ActiveRoomNotifierRef
    on AutoDisposeStreamNotifierProviderRef<RoomModel?> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _ActiveRoomNotifierProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<ActiveRoomNotifier, RoomModel?>
    with ActiveRoomNotifierRef {
  _ActiveRoomNotifierProviderElement(super.provider);

  @override
  String get roomId => (origin as ActiveRoomNotifierProvider).roomId;
}

String _$roomMatchNotifierHash() => r'd19b833d6e7aa29242b572650e5dee1d4f82f1ff';

abstract class _$RoomMatchNotifier
    extends BuildlessAutoDisposeNotifier<RoomMatch?> {
  late final String roomId;

  RoomMatch? build(String roomId);
}

/// See also [RoomMatchNotifier].
@ProviderFor(RoomMatchNotifier)
const roomMatchNotifierProvider = RoomMatchNotifierFamily();

/// See also [RoomMatchNotifier].
class RoomMatchNotifierFamily extends Family<RoomMatch?> {
  /// See also [RoomMatchNotifier].
  const RoomMatchNotifierFamily();

  /// See also [RoomMatchNotifier].
  RoomMatchNotifierProvider call(String roomId) {
    return RoomMatchNotifierProvider(roomId);
  }

  @override
  RoomMatchNotifierProvider getProviderOverride(
    covariant RoomMatchNotifierProvider provider,
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
  String? get name => r'roomMatchNotifierProvider';
}

/// See also [RoomMatchNotifier].
class RoomMatchNotifierProvider
    extends AutoDisposeNotifierProviderImpl<RoomMatchNotifier, RoomMatch?> {
  /// See also [RoomMatchNotifier].
  RoomMatchNotifierProvider(String roomId)
    : this._internal(
        () => RoomMatchNotifier()..roomId = roomId,
        from: roomMatchNotifierProvider,
        name: r'roomMatchNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$roomMatchNotifierHash,
        dependencies: RoomMatchNotifierFamily._dependencies,
        allTransitiveDependencies:
            RoomMatchNotifierFamily._allTransitiveDependencies,
        roomId: roomId,
      );

  RoomMatchNotifierProvider._internal(
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
  RoomMatch? runNotifierBuild(covariant RoomMatchNotifier notifier) {
    return notifier.build(roomId);
  }

  @override
  Override overrideWith(RoomMatchNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RoomMatchNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<RoomMatchNotifier, RoomMatch?>
  createElement() {
    return _RoomMatchNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomMatchNotifierProvider && other.roomId == roomId;
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
mixin RoomMatchNotifierRef on AutoDisposeNotifierProviderRef<RoomMatch?> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _RoomMatchNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<RoomMatchNotifier, RoomMatch?>
    with RoomMatchNotifierRef {
  _RoomMatchNotifierProviderElement(super.provider);

  @override
  String get roomId => (origin as RoomMatchNotifierProvider).roomId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
