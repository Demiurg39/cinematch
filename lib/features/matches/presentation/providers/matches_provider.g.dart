// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$matchesRepositoryHash() => r'f5edf2e3fc144e73d766200e497c8c26b14de53e';

/// See also [matchesRepository].
@ProviderFor(matchesRepository)
final matchesRepositoryProvider =
    AutoDisposeProvider<MatchesRepository>.internal(
      matchesRepository,
      name: r'matchesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$matchesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MatchesRepositoryRef = AutoDisposeProviderRef<MatchesRepository>;
String _$matchesNotifierHash() => r'46d6d00d82a1cd34d4691735605925a2f2c341b0';

/// See also [MatchesNotifier].
@ProviderFor(MatchesNotifier)
final matchesNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      MatchesNotifier,
      List<MatchModel>
    >.internal(
      MatchesNotifier.new,
      name: r'matchesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$matchesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MatchesNotifier = AutoDisposeStreamNotifier<List<MatchModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
