// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partners_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$partnersRepositoryHash() =>
    r'8237c921ede882d8ce4ab90135e579e7c0d6b9c9';

/// See also [partnersRepository].
@ProviderFor(partnersRepository)
final partnersRepositoryProvider =
    AutoDisposeProvider<PartnersRepository>.internal(
      partnersRepository,
      name: r'partnersRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$partnersRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PartnersRepositoryRef = AutoDisposeProviderRef<PartnersRepository>;
String _$partnersNotifierHash() => r'b7a4ba4742667c0d603dabb7c5776e5a0eb10986';

/// See also [PartnersNotifier].
@ProviderFor(PartnersNotifier)
final partnersNotifierProvider =
    AutoDisposeStreamNotifierProvider<
      PartnersNotifier,
      List<PartnerModel>
    >.internal(
      PartnersNotifier.new,
      name: r'partnersNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$partnersNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PartnersNotifier = AutoDisposeStreamNotifier<List<PartnerModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
