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
String _$swipeDeckNotifierHash() => r'b144932bf322199f1510bac04d98ed28b62f9a4a';

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
    r'71bf6b62c8ff14f8034661cc1261313eb5154529';

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
