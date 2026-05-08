// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_requests_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$friendRequestsNotifierHash() =>
    r'eb9d7867cb5790bfc7120445ee7f11371904e0f7';

/// See also [FriendRequestsNotifier].
@ProviderFor(FriendRequestsNotifier)
final friendRequestsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      FriendRequestsNotifier,
      List<FriendshipModel>
    >.internal(
      FriendRequestsNotifier.new,
      name: r'friendRequestsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$friendRequestsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FriendRequestsNotifier =
    AutoDisposeAsyncNotifier<List<FriendshipModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
