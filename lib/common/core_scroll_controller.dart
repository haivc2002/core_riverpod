import 'package:flutter/widgets.dart';

class CoreScrollController extends ScrollController {
  bool isMoreEnable = true;
  bool isLoadMore = false;

  CoreScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });
}
