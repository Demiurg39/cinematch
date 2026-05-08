// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$swipeRepositoryHash() => r'8eeec5ef5be1bcb8d5c59387b9622792d6062a75';

/// See also [swipeRepository].
@ProviderFor(swipeRepository)
final swipeRepositoryProvider = AutoDisposeProvider<SwipeRepository>.internal(
  swipeRepository,
  name: r'swipeRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$swipeRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SwipeRepositoryRef = AutoDisposeProviderRef<SwipeRepository>;
String _$matchNotifierHash() => r'24d32337fd014c0435804d840ca87212310df5cf';

/// See also [MatchNotifier].
@ProviderFor(MatchNotifier)
final matchNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      MatchNotifier,
      List<Map<String, dynamic>>
    >.internal(
      MatchNotifier.new,
      name: r'matchNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$matchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MatchNotifier = AutoDisposeStreamNotifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
