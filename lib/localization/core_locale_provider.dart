import 'package:core_riverpod/common/k.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_locale_provider.g.dart';

@Riverpod(keepAlive: true)
class CoreLocale extends _$CoreLocale {
  @override
  Locale build() {
    return const Locale(K.vi);
  }

  void setLocale(Locale locale) {
    state = locale;
  }
}
