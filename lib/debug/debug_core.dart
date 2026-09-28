import 'package:core_riverpod/common/k.dart';
import 'package:core_riverpod/core_riverpod.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_memory_notifier.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_network_notifier.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_panel_notifier.dart';
import 'package:core_riverpod/debug/debug_tab/debug_memory_tab.dart';
import 'package:core_riverpod/debug/debug_tab/debug_network_tab.dart';
import 'package:core_riverpod/debug/debug_tab/debug_overview_tab.dart';
import 'package:core_riverpod/debug/debug_widget/debug_badges.dart';
import 'package:core_riverpod/debug/debug_widget/debug_chip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugCore {
  static OverlayEntry? _overlayEntry;
  static bool _isShown = false;

  static void show(BuildContext context) {
    if (!kDebugMode) return;
    if (_isShown) return;
    _isShown = true;
    _overlayEntry = OverlayEntry(
      builder: (_) => const DraggableDebugButton(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
      }
    });
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShown = false;
  }
}

class DraggableDebugButton extends ConsumerWidget {
  const DraggableDebugButton({super.key});

  final double _btnSize = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.sizeOf(context);
    final safeArea = MediaQuery.paddingOf(context);
    final state = ref.watch(debugProvider);
    final notifier = ref.read(debugProvider.notifier);

    return SizedBox.expand(
      child: Stack(
        children: [
          if (state.isOpen)
            const Positioned.fill(child: _DebugPanelContent()),
          AnimatedPositioned(
            duration: state.isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: state.x,
            top: state.y,
            child: GestureDetector(
              onPanStart: (_) => notifier.onDragStart(),
              onPanUpdate: (details) => notifier.onDragUpdate(
                details.delta.dx,
                details.delta.dy,
                screenSize,
                safeArea,
                _btnSize,
              ),
              onPanEnd: (_) => notifier.onDragEnd(screenSize, _btnSize),
              child: Material(
                type: MaterialType.transparency,
                child: Consumer(
                  builder: (context, ref, child) {
                    final leaks = ref.watch(debugMemoryProvider);
                    final networkErrors = ref.watch(debugNetworkProvider);
                    final hasLeaks = leaks.isNotEmpty;
                    final hasNetErrors = networkErrors.isNotEmpty;
                    final hasIssues = hasLeaks || hasNetErrors;
                    final totalIssues = leaks.length + networkErrors.length;
                    final alertColor = hasLeaks
                        ? K.kRed
                        : K.kOrange;
                    final isOpen = state.isOpen;
                    final icon = isOpen
                        ? Icons.close
                        : Icons.bug_report;
                    final foregroundColor = isOpen
                        ? Colors.white
                        : hasIssues
                        ? alertColor
                        : K.kBlue;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: _btnSize,
                          height: _btnSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: foregroundColor.darken(),
                            border: Border.all(color: foregroundColor, width: 1.8),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: notifier.togglePanel,
                            icon: Icon(
                              icon,
                              color: foregroundColor,
                              size: 26,
                            ),
                          ),
                        ),
                        if (hasIssues && !state.isOpen)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: DebugBadges(totalIssues),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugPanelContent extends ConsumerWidget {
  const _DebugPanelContent();

  final _tabs = const [
    DebugOverviewTab(),
    DebugNetworkTab(),
    DebugMemoryTab(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debugProvider);
    final leaksCount = ref.watch(debugMemoryProvider.select((v) => v.length));
    final networkErrorsCount = ref.watch(debugNetworkProvider.select((v) => v.length));

    return Scaffold(
      backgroundColor: K.kBaG,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: K.kNavi,
                border: Border(bottom: BorderSide(color: K.kBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: K.kGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "DEV_CORE // TELEMETRY OVERLAY",
                    style: K.style.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: K.kGrey
                    ),
                  ),
                  const Spacer(),
                  if (leaksCount > 0)
                    DebugChip(color: K.kRed, label: "LEAKS: $leaksCount"),
                  if (leaksCount > 0 && networkErrorsCount > 0)
                    const SizedBox(width: 6),
                  if (networkErrorsCount > 0)
                    DebugChip(color: K.kOrange, label: "API ERR: $networkErrorsCount"),
                ],
              ),
            ),

            Container(
              color: const Color(0xFF0C101A),
              child: Row(
                children: [
                  _buildTabBtn("OVERVIEW", 0, state.tabIndex, ref, badge: leaksCount > 0 ? "$leaksCount" : null),
                  _buildTabBtn(
                    "NETWORK",
                    1,
                    state.tabIndex,
                    ref,
                    badge: networkErrorsCount > 0 ? "$networkErrorsCount" : null,
                    badgeColor: const Color(0xFFF59E0B),
                  ),
                  _buildTabBtn("MEMORY", 2, state.tabIndex, ref),
                ],
              ),
            ),
            const Divider(height: 1, color: K.kBorder),
            Expanded(child: _tabs[state.tabIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String title, int index, int currentIndex, WidgetRef ref, {String? badge, Color? badgeColor}) {
    final isSelected = currentIndex == index;
    final effectiveBadgeColor = badgeColor ?? const Color(0xFFF43F5E);

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(debugProvider.notifier).setTabIndex(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? K.kNavi : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? K.kBlue : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: K.style.copyWith(
                  color: isSelected ? K.kBlue : K.kGrey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: effectiveBadgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: K.style.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}