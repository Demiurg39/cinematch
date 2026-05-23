// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$swipeDeckStateHash() => r'f75e331263315180a2b09b614da03d3e01915dfe';

/// See also [swipeDeckState].
@ProviderFor(swipeDeckState)
final swipeDeckStateProvider = AutoDisposeProvider<SwipeDeckState>.internal(
  swipeDeckState,
  name: r'swipeDeckStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$swipeDeckStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SwipeDeckStateRef = AutoDisposeProviderRef<SwipeDeckState>;
String _$swipeDeckNotifierHash() => r'd60777a6004fa37781133469aa58708552c49d00';

/// See also [SwipeDeckNotifier].
@ProviderFor(SwipeDeckNotifier)
final swipeDeckNotifierProvider =
    AutoDisposeNotifierProvider<SwipeDeckNotifier, SwipeDeckState>.internal(
      SwipeDeckNotifier.new,
      name: r'swipeDeckNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$swipeDeckNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SwipeDeckNotifier = AutoDisposeNotifier<SwipeDeckState>;
String _$popularDeckNotifierHash() =>
    r'b45397a8ea29fb1c431742f8218b01a431925dc1';

/// See also [PopularDeckNotifier].
@ProviderFor(PopularDeckNotifier)
final popularDeckNotifierProvider =
    AutoDisposeNotifierProvider<PopularDeckNotifier, SwipeDeckState>.internal(
      PopularDeckNotifier.new,
      name: r'popularDeckNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$popularDeckNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PopularDeckNotifier = AutoDisposeNotifier<SwipeDeckState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
