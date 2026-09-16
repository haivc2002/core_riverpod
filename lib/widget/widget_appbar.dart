import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class WidgetAppbar extends StatelessWidget implements PreferredSizeWidget {
  static final ValueNotifier<double> pullProgressNotifier = ValueNotifier<double>(0);

  final Color? backgroundColor;
  final Widget? leading;
  final Widget? title;
  final double toolbarHeight;
  final List<Widget>? actions;
  final double? leadingWidth;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;

  const WidgetAppbar({
    super.key,
    this.backgroundColor,
    this.leading,
    this.title,
    this.toolbarHeight = kToolbarHeight,
    this.actions,
    this.leadingWidth,
    this.centerTitle,
    this.automaticallyImplyLeading = true
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context) as PageRoute?;
    final bool canPop = route?.canPop ?? false;
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final double screenWidth = MediaQuery.of(context).size.width;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading && canPop) {
      leadingWidget = const BackButton();
    }

    Widget? titleWidget = title;
    List<Widget>? actionWidgets = actions;

    if (route != null) {
      if (leadingWidget != null) {
        leadingWidget = _FixedPosition(
          animation: route.animation!,
          secondaryAnimation: route.secondaryAnimation!,
          enableFadeAndBlur: false,
          child: leadingWidget,
        );
      }

      if (titleWidget != null) {
        titleWidget = _ClipTitle(
          animation: route.animation!,
          secondaryAnimation: route.secondaryAnimation!,
          clipBoundaryX: leadingWidget != null ? (leadingWidth ?? kToolbarHeight) : 0.0,
          centerTitle: centerTitle,
          screenWidth: screenWidth,
          targetX: leadingWidget != null ? (leadingWidth ?? kToolbarHeight) : 16.0,
          isAndroid: isAndroid,
          child: titleWidget,
        );
      }

      if (actionWidgets != null) {
        actionWidgets = actionWidgets.map((action) => _FixedPosition(
          animation: route.animation!,
          secondaryAnimation: route.secondaryAnimation!,
          enableFadeAndBlur: true,
          child: action,
        )).toList();
      }
    }

    final animation = route?.animation;

    return ValueListenableBuilder<double>(
      valueListenable: pullProgressNotifier,
      builder: (context, _, __) {
        final extraHeight = coreAppBarListIntermediateOffset;
        final currentToolbarHeight = toolbarHeight + extraHeight;

        Widget appBar;
        if (animation == null) {
          appBar = _buildAppBar(context, currentToolbarHeight, leadingWidget, titleWidget, actionWidgets);
        } else {
          appBar = AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              double dx = 0;
              if (animation.status == AnimationStatus.forward && animation.value < 1.0) {
                final bool isGesture = route?.navigator?.userGestureInProgress ?? false;
                double progress;
                if (isGesture) {
                  progress = animation.value;
                } else if (isAndroid) {
                  progress = Curves.easeInOutCubicEmphasized.transform(animation.value);
                } else {
                  progress = Curves.fastEaseInToSlowEaseOut.transform(animation.value);
                }
                final factor = isAndroid ? 0.25 : 1.0;
                dx = -screenWidth * factor * (1.0 - progress);
              }
              return _buildAppBar(
                context,
                currentToolbarHeight,
                leadingWidget != null ? Transform.translate(offset: Offset(dx, 0), child: leadingWidget) : null,
                titleWidget,
                actionWidgets?.map((a) => Transform.translate(offset: Offset(dx, 0), child: a)).toList(),
              );
            },
          );
        }

        return OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0.0,
          maxHeight: double.infinity,
          child: appBar,
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    double currentToolbarHeight,
    Widget? leadingWidget,
    Widget? titleWidget,
    List<Widget>? actionWidgets,
  ) {
    return AppBar(
      leading: leadingWidget,
      title: titleWidget,
      centerTitle: centerTitle,
      elevation: 0,
      titleSpacing: leadingWidget == null ? NavigationToolbar.kMiddleSpacing : 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leadingWidth: leadingWidth,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      toolbarHeight: currentToolbarHeight,
      actions: actionWidgets,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}

class _FixedPosition extends SingleChildRenderObjectWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool enableFadeAndBlur;

  const _FixedPosition({
    required super.child,
    required this.animation,
    required this.secondaryAnimation,
    this.enableFadeAndBlur = false,
  });

  @override
  _RenderFixedPosition createRenderObject(BuildContext context) {
    return _RenderFixedPosition(enableFadeAndBlur: enableFadeAndBlur)
      ..animation = animation
      ..secondaryAnimation = secondaryAnimation;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderFixedPosition renderObject) {
    renderObject
      ..animation = animation
      ..secondaryAnimation = secondaryAnimation
      ..enableFadeAndBlur = enableFadeAndBlur;
  }
}

class _RenderFixedPosition extends RenderProxyBox {
  _RenderFixedPosition({required bool enableFadeAndBlur})
      : _enableFadeAndBlur = enableFadeAndBlur;

  bool _enableFadeAndBlur;
  set enableFadeAndBlur(bool value) {
    if (_enableFadeAndBlur == value) return;
    _enableFadeAndBlur = value;
    markNeedsPaint();
  }

  double? _anchorScreenX;
  bool _pendingCapture = false;

  Animation<double>? _animation;
  set animation(Animation<double>? value) {
    if (_animation == value) return;
    _animation?.removeStatusListener(_onStatus);
    _animation?.removeListener(markNeedsPaint);
    _animation = value;
    _animation?.addStatusListener(_onStatus);
    _animation?.addListener(markNeedsPaint);
    if (value != null && value.isCompleted) _pendingCapture = true;
  }

  Animation<double>? _secondaryAnimation;
  set secondaryAnimation(Animation<double>? value) {
    if (_secondaryAnimation == value) return;
    _secondaryAnimation?.removeListener(markNeedsPaint);
    _secondaryAnimation = value;
    _secondaryAnimation?.addListener(markNeedsPaint);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _pendingCapture = true;
      markNeedsPaint();
    }
  }

  double _getOpacity() {
    double opacity = 1.0;
    if (_animation != null && _animation!.status != AnimationStatus.completed) {
      opacity *= Curves.easeIn.transform(_animation!.value);
    }
    if (_secondaryAnimation != null && _secondaryAnimation!.status != AnimationStatus.dismissed) {
      opacity *= (1.0 - Curves.easeOut.transform(_secondaryAnimation!.value));
    }
    return opacity.clamp(0.0, 1.0);
  }

  double _getBlurSigma() {
    double sigma = 0.0;
    if (_animation != null && _animation!.status != AnimationStatus.completed) {
      sigma += 15.0 * (1.0 - Curves.easeIn.transform(_animation!.value));
    }
    if (_secondaryAnimation != null && _secondaryAnimation!.status != AnimationStatus.dismissed) {
      sigma += 15.0 * Curves.easeOut.transform(_secondaryAnimation!.value);
    }
    return sigma.clamp(0.0, 15.0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final screenX = localToGlobal(Offset.zero).dx;
    
    final bool isSteadyState = (_animation == null || _animation!.isCompleted) &&
                               (_secondaryAnimation == null || _secondaryAnimation!.isDismissed);

    if (isSteadyState) {
      _anchorScreenX = screenX;
      _pendingCapture = false;
    } else if (_pendingCapture) {
      _anchorScreenX = screenX;
      _pendingCapture = false;
    }

    double dx = 0.0;
    if (!isSteadyState && _anchorScreenX != null) {
      dx = _anchorScreenX! - screenX;
    }
    final double opacity = _enableFadeAndBlur ? _getOpacity() : 1.0;
    final int alpha = (opacity * 255).round();
    final double sigma = _enableFadeAndBlur ? _getBlurSigma() : 0.0;
    if (alpha == 0) return;
    void paintTransform(PaintingContext ctx, Offset off) {
      if (dx.abs() > 0.1) {
        ctx.pushTransform(
          needsCompositing,
          off,
          Matrix4.translationValues(dx, 0, 0),
          super.paint,
        );
      } else {
        super.paint(ctx, off);
      }
    }

    void paintBlur(PaintingContext ctx, Offset off) {
      if (sigma > 0.1) {
        ctx.pushLayer(
          ImageFilterLayer(imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: ui.TileMode.decal)),
          paintTransform,
          off,
        );
      } else {
        paintTransform(ctx, off);
      }
    }

    alpha < 255
      ? context.pushOpacity(offset, alpha, paintBlur)
      : paintBlur(context, offset);
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_onStatus);
    _animation?.removeListener(markNeedsPaint);
    _secondaryAnimation?.removeListener(markNeedsPaint);
    super.dispose();
  }
}

class _ClipTitle extends SingleChildRenderObjectWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final double clipBoundaryX;
  final bool? centerTitle;
  final double screenWidth;
  final double targetX;
  final bool isAndroid;

  const _ClipTitle({
    required super.child,
    required this.animation,
    required this.secondaryAnimation,
    required this.clipBoundaryX,
    required this.centerTitle,
    required this.screenWidth,
    required this.targetX,
    required this.isAndroid,
  });

  @override
  _RenderClipTitle createRenderObject(BuildContext context) {
    return _RenderClipTitle(
      clipBoundaryX: clipBoundaryX,
      centerTitle: centerTitle,
      screenWidth: screenWidth,
      targetX: targetX,
      isAndroid: isAndroid,
    )
      ..animation = animation
      ..secondaryAnimation = secondaryAnimation;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderClipTitle renderObject) {
    renderObject
      ..animation = animation
      ..secondaryAnimation = secondaryAnimation
      ..clipBoundaryX = clipBoundaryX
      ..centerTitle = centerTitle
      ..screenWidth = screenWidth
      ..targetX = targetX
      ..isAndroid = isAndroid;
  }
}

class _RenderClipTitle extends RenderProxyBox {
  _RenderClipTitle({
    required double clipBoundaryX,
    required bool? centerTitle,
    required double screenWidth,
    required double targetX,
    required bool isAndroid,
  })  : _clipBoundaryX = clipBoundaryX,
        _centerTitle = centerTitle,
        _screenWidth = screenWidth,
        _targetX = targetX,
        _isAndroid = isAndroid;

  double _clipBoundaryX;
  set clipBoundaryX(double value) {
    if (_clipBoundaryX == value) return;
    _clipBoundaryX = value;
    markNeedsPaint();
  }

  bool? _centerTitle;
  set centerTitle(bool? value) {
    if (_centerTitle == value) return;
    _centerTitle = value;
    markNeedsPaint();
  }

  double _screenWidth;
  set screenWidth(double value) {
    if (_screenWidth == value) return;
    _screenWidth = value;
    markNeedsPaint();
  }

  double _targetX;
  set targetX(double value) {
    if (_targetX == value) return;
    _targetX = value;
    markNeedsPaint();
  }

  bool _isAndroid;
  set isAndroid(bool value) {
    if (_isAndroid == value) return;
    _isAndroid = value;
    markNeedsPaint();
  }

  Animation<double>? _animation;
  set animation(Animation<double>? value) {
    if (_animation == value) return;
    _animation?.removeListener(markNeedsPaint);
    _animation = value;
    _animation?.addListener(markNeedsPaint);
  }

  Animation<double>? _secondaryAnimation;
  set secondaryAnimation(Animation<double>? value) {
    if (_secondaryAnimation == value) return;
    _secondaryAnimation?.removeListener(markNeedsPaint);
    _secondaryAnimation = value;
    _secondaryAnimation?.addListener(markNeedsPaint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final screenX = localToGlobal(Offset.zero).dx;
    double dx = 0.0;

    if (_centerTitle == false && _animation != null && _animation!.status != AnimationStatus.completed) {
      double rawProgress = _animation!.value;
      if (rawProgress > 0) {
        double progress;
        if (_isAndroid) {
          progress = Curves.easeInOutCubicEmphasized.transform(rawProgress);
        } else {
          progress = Curves.fastEaseInToSlowEaseOut.transform(rawProgress);
        }

        double centerX = (_screenWidth - size.width) / 2.0;
        double renderedX = centerX + (_targetX - centerX) * progress;
        dx = renderedX - screenX;
      }
    }

    void paintCore(PaintingContext ctx, Offset off) {
      if (dx.abs() > 0.1) {
        ctx.pushTransform(
          needsCompositing,
          off,
          Matrix4.translationValues(dx, 0, 0),
          super.paint,
        );
      } else {
        super.paint(ctx, off);
      }
    }

    final clipLocalX = _clipBoundaryX - screenX;

    if (clipLocalX > 0) {
      if ((dx + size.width) <= clipLocalX) return;
      final rect = Rect.fromLTRB(clipLocalX, -100, size.width + dx.abs() + 100, size.height + 100);
      context.pushClipRect(needsCompositing, offset, rect, paintCore);
    } else {
      paintCore(context, offset);
    }
  }

  @override
  void dispose() {
    _animation?.removeListener(markNeedsPaint);
    _secondaryAnimation?.removeListener(markNeedsPaint);
    super.dispose();
  }
}

double get coreAppBarListIntermediateOffset => WidgetAppbar.pullProgressNotifier.value * 0.4;

class CoreAppBarListIntermediateSpace extends StatelessWidget {
  final double scale;
  const CoreAppBarListIntermediateSpace({
    this.scale = 0,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: WidgetAppbar.pullProgressNotifier,
      builder: (context, overscroll, child) {
        return SizedBox(height: overscroll * 0.4 * (1 + scale));
      },
    );
  }
}

class CoreAppBarListIntermediateTranslate extends StatelessWidget {
  final Widget child;
  const CoreAppBarListIntermediateTranslate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: WidgetAppbar.pullProgressNotifier,
      builder: (context, overscroll, childWidget) {
        return Transform.translate(
          offset: Offset(0, overscroll * 0.4),
          child: childWidget,
        );
      },
      child: child,
    );
  }
}
