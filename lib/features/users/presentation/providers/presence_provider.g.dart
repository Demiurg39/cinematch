// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$presenceRepositoryHash() =>
    r'2f6ffdb80c6aaf39f333975bf09a191f0deae980';

/// See also [presenceRepository].
@ProviderFor(presenceRepository)
final presenceRepositoryProvider =
    AutoDisposeProvider<PresenceRepository>.internal(
      presenceRepository,
      name: r'presenceRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$presenceRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PresenceRepositoryRef = AutoDisposeProviderRef<PresenceRepository>;
String _$userPresenceHash() => r'871243a01c8f3493dd9b264362b6b7bd3e8f8507';

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

/// See also [userPresence].
@ProviderFor(userPresence)
const userPresenceProvider = UserPresenceFamily();

/// See also [userPresence].
class UserPresenceFamily extends Family<AsyncValue<bool>> {
  /// See also [userPresence].
  const UserPresenceFamily();

  /// See also [userPresence].
  UserPresenceProvider call(String userId) {
    return UserPresenceProvider(userId);
  }

  @override
  UserPresenceProvider getProviderOverride(
    covariant UserPresenceProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userPresenceProvider';
}

/// See also [userPresence].
class UserPresenceProvider extends AutoDisposeStreamProvider<bool> {
  /// See also [userPresence].
  UserPresenceProvider(String userId)
    : this._internal(
        (ref) => userPresence(ref as UserPresenceRef, userId),
        from: userPresenceProvider,
        name: r'userPresenceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userPresenceHash,
        dependencies: UserPresenceFamily._dependencies,
        allTransitiveDependencies:
            UserPresenceFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserPresenceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<bool> Function(UserPresenceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserPresenceProvider._internal(
        (ref) => create(ref as UserPresenceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<bool> createElement() {
    return _UserPresenceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPresenceProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserPresenceRef on AutoDisposeStreamProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserPresenceProviderElement
    extends AutoDisposeStreamProviderElement<bool>
    with UserPresenceRef {
  _UserPresenceProviderElement(super.provider);

  @override
  String get userId => (origin as UserPresenceProvider).userId;
}

String _$myPresenceNotifierHash() =>
    r'ab504b674f910576f3959392eb44a04673a5ea86';

/// See also [MyPresenceNotifier].
@ProviderFor(MyPresenceNotifier)
final myPresenceNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MyPresenceNotifier, void>.internal(
      MyPresenceNotifier.new,
      name: r'myPresenceNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myPresenceNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyPresenceNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
