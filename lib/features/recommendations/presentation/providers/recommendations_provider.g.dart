// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recommendationsRepositoryHash() =>
    r'db18054863c4bedcd179b29f04e62dbb6f817b4d';

/// See also [recommendationsRepository].
@ProviderFor(recommendationsRepository)
final recommendationsRepositoryProvider =
    AutoDisposeProvider<RecommendationsRepository>.internal(
      recommendationsRepository,
      name: r'recommendationsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recommendationsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecommendationsRepositoryRef =
    AutoDisposeProviderRef<RecommendationsRepository>;
String _$recommendationsNotifierHash() =>
    r'edddf9e1ecb9f07b6f726fb0881b9ec0c3eb09f1';

/// See also [RecommendationsNotifier].
@ProviderFor(RecommendationsNotifier)
final recommendationsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      RecommendationsNotifier,
      List<MovieModel>
    >.internal(
      RecommendationsNotifier.new,
      name: r'recommendationsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recommendationsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecommendationsNotifier = AutoDisposeAsyncNotifier<List<MovieModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
