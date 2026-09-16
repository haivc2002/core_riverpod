// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_entity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalState)
final globalStateProvider = GlobalStateFamily._();

final class GlobalStateProvider
    extends $NotifierProvider<GlobalState, dynamic> {
  GlobalStateProvider._({
    required GlobalStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'globalStateProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$globalStateHash();

  @override
  String toString() {
    return r'globalStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GlobalState create() => GlobalState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(dynamic value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<dynamic>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GlobalStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$globalStateHash() => r'5ccd3cdc563baebecd43c64bf91338b3d49ba0c2';

final class GlobalStateFamily extends $Family
    with $ClassFamilyOverride<GlobalState, dynamic, dynamic, dynamic, String> {
  GlobalStateFamily._()
    : super(
        retry: null,
        name: r'globalStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  GlobalStateProvider call(String key) =>
      GlobalStateProvider._(argument: key, from: this);

  @override
  String toString() => r'globalStateProvider';
}

abstract class _$GlobalState extends $Notifier<dynamic> {
  late final _$args = ref.$arg as String;
  String get key => _$args;

  dynamic build(String key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<dynamic, dynamic>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<dynamic, dynamic>,
              dynamic,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
