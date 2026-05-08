// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friends_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$friendsRepositoryHash() => r'6fcd70bd53291e39d65d2a7b1f9b98e46947dea1';

/// See also [friendsRepository].
@ProviderFor(friendsRepository)
final friendsRepositoryProvider =
    AutoDisposeProvider<FriendsRepository>.internal(
      friendsRepository,
      name: r'friendsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$friendsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FriendsRepositoryRef = AutoDisposeProviderRef<FriendsRepository>;
String _$friendsNotifierHash() => r'480d1c108da7e0335686db98e7820dc14b1e9d75';

/// See also [FriendsNotifier].
@ProviderFor(FriendsNotifier)
final friendsNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      FriendsNotifier,
      List<FriendshipModel>
    >.internal(
      FriendsNotifier.new,
      name: r'friendsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$friendsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FriendsNotifier = AutoDisposeStreamNotifier<List<FriendshipModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
