// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rooms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$roomsRepositoryHash() => r'170e597f66a4fb23b0856446d73bafe25853a873';

/// See also [roomsRepository].
@ProviderFor(roomsRepository)
final roomsRepositoryProvider = AutoDisposeProvider<RoomsRepository>.internal(
  roomsRepository,
  name: r'roomsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$roomsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RoomsRepositoryRef = AutoDisposeProviderRef<RoomsRepository>;
String _$myRoomsNotifierHash() => r'a07504e89eb5d8da7b6d316b46b052528e19420f';

/// See also [MyRoomsNotifier].
@ProviderFor(MyRoomsNotifier)
final myRoomsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MyRoomsNotifier, List<RoomModel>>.internal(
      MyRoomsNotifier.new,
      name: r'myRoomsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myRoomsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyRoomsNotifier = AutoDisposeAsyncNotifier<List<RoomModel>>;
String _$roomByCodeNotifierHash() =>
    r'f1ec696732426adda415527988cfdabdfb4095b4';

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

abstract class _$RoomByCodeNotifier
    extends BuildlessAutoDisposeAsyncNotifier<RoomModel?> {
  late final String code;

  FutureOr<RoomModel?> build(String code);
}

/// See also [RoomByCodeNotifier].
@ProviderFor(RoomByCodeNotifier)
const roomByCodeNotifierProvider = RoomByCodeNotifierFamily();

/// See also [RoomByCodeNotifier].
class RoomByCodeNotifierFamily extends Family<AsyncValue<RoomModel?>> {
  /// See also [RoomByCodeNotifier].
  const RoomByCodeNotifierFamily();

  /// See also [RoomByCodeNotifier].
  RoomByCodeNotifierProvider call(String code) {
    return RoomByCodeNotifierProvider(code);
  }

  @override
  RoomByCodeNotifierProvider getProviderOverride(
    covariant RoomByCodeNotifierProvider provider,
  ) {
    return call(provider.code);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'roomByCodeNotifierProvider';
}

/// See also [RoomByCodeNotifier].
class RoomByCodeNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<RoomByCodeNotifier, RoomModel?> {
  /// See also [RoomByCodeNotifier].
  RoomByCodeNotifierProvider(String code)
    : this._internal(
        () => RoomByCodeNotifier()..code = code,
        from: roomByCodeNotifierProvider,
        name: r'roomByCodeNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$roomByCodeNotifierHash,
        dependencies: RoomByCodeNotifierFamily._dependencies,
        allTransitiveDependencies:
            RoomByCodeNotifierFamily._allTransitiveDependencies,
        code: code,
      );

  RoomByCodeNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.code,
  }) : super.internal();

  final String code;

  @override
  FutureOr<RoomModel?> runNotifierBuild(covariant RoomByCodeNotifier notifier) {
    return notifier.build(code);
  }

  @override
  Override overrideWith(RoomByCodeNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RoomByCodeNotifierProvider._internal(
        () => create()..code = code,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        code: code,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RoomByCodeNotifier, RoomModel?>
  createElement() {
    return _RoomByCodeNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomByCodeNotifierProvider && other.code == code;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, code.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RoomByCodeNotifierRef on AutoDisposeAsyncNotifierProviderRef<RoomModel?> {
  /// The parameter `code` of this provider.
  String get code;
}

class _RoomByCodeNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<RoomByCodeNotifier, RoomModel?>
    with RoomByCodeNotifierRef {
  _RoomByCodeNotifierProviderElement(super.provider);

  @override
  String get code => (origin as RoomByCodeNotifierProvider).code;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
