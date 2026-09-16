// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoreLocale)
final coreLocaleProvider = CoreLocaleProvider._();

final class CoreLocaleProvider extends $NotifierProvider<CoreLocale, Locale> {
  CoreLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coreLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coreLocaleHash();

  @$internal
  @override
  CoreLocale create() => CoreLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$coreLocaleHash() => r'7cf4adc8cea41eeb876483b211b9b91a20c707b4';

abstract class _$CoreLocale extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
