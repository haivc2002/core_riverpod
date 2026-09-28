import 'dart:async';
import 'dart:io';
import 'package:core_riverpod/debug/debug_notifier/debug_memory_notifier.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_panel_notifier.dart';
import 'package:core_riverpod/debug/debug_widget/debug_chip.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'package:core_riverpod/core_riverpod.dart';
import 'package:core_riverpod/debug/debug_widget/debug_frame.dart';
import 'package:core_riverpod/common/k.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DebugRamHistoryNotifier extends Notifier<List<double>> {
  double peakRamMB = 0.0;

  @override
  List<double> build() => [];

  void addPoint(double mb) {
    if (!kDebugMode) return;
    if (mb > peakRamMB) peakRamMB = mb;
    final list = List<double>.from(state);
    if (list.length >= 30) list.removeAt(0);
    list.add(mb);
    state = list;
  }
}

final _debugRamHistoryProvider = NotifierProvider<DebugRamHistoryNotifier, List<double>>(DebugRamHistoryNotifier.new);

class DebugOverviewTab extends HookConsumerWidget {
  const DebugOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final routeStack = ref.watch(debugProvider).routeStack;
    final Map<int, List<String>> groups = {};
    for (final item in routeStack) {
      groups.putIfAbsent(item.routeId, () => []).add(item.name);
    }
    final routeList = groups.values.toList();

    final deviceInfo = useMemoized(() async {
      final plugin = DeviceInfoPlugin();
      String name = 'Unknown Device';
      try {
        if (Platform.isAndroid) {
          final info = await plugin.androidInfo;
          name = '${info.brand} ${info.model}';
        } else if (Platform.isIOS) {
          final info = await plugin.iosInfo;
          name = info.name;
        }
      } catch (_) {}

      String ramStr = '? GB';
      double rawRamMB = 4096.0;
      try {
        if (await SystemInfoPlus.physicalMemory case final int ramMB) {
          ramStr = '${(ramMB / 1024).toStringAsFixed(2)} GB';
          rawRamMB = ramMB.toDouble();
        }
      } catch (_) {}

      return (name: name, totalRam: ramStr, rawRamMB: rawRamMB);
    });
    final deviceSnapshot = useFuture(deviceInfo);
    final isOpen = ref.watch(debugProvider.select((s) => s.isOpen));
    final appLifecycleState = useAppLifecycleState();
    final isActive = appLifecycleState == AppLifecycleState.resumed;
    final ramHistory = ref.watch(_debugRamHistoryProvider);
    final ramHistoryNotifier = ref.read(_debugRamHistoryProvider.notifier);
    final leaks = ref.watch(debugMemoryProvider);

    useEffect(() {
      if (!isOpen || !isActive) return null;
      coreLog("START RAM STREAM", name: K.nameDebug);
      final sub = Stream.periodic(const Duration(seconds: 1), (_) {
        return ProcessInfo.currentRss / (1024 * 1024);
      }).listen((mb) {
        ramHistoryNotifier.addPoint(mb);
      });
      return () {
        coreLog("STOP RAM STREAM", name: K.nameDebug);
        sub.cancel();
      };
    }, [isOpen, isActive]);

    final currentRamMB = ramHistory.isNotEmpty ? ramHistory.last : 0.0;

    return WidgetListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      children: [
        DebugFrame(
          name: "Route Trace // Navigation Stack",
          icon: Icons.alt_route,
          content: routeList.isEmpty
              ? Text(
                  "[IDLE] No active route frames captured...",
                  style: K.style.copyWith(color: K.kGrey),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (int i = 0; i < routeList.length; i++) ...[
                      DebugChip(
                        label: routeList[i].length > 1
                            ? "${routeList[i].first}[${routeList[i].skip(1).join(', ')}]"
                            : routeList[i].first,
                        color: i == routeList.length - 1 ? K.kBlue : K.kGrey,
                      ),
                      if (i < routeList.length - 1)
                        const Icon(Icons.arrow_forward_ios, color: K.kBlue, size: 10),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 14),

        DebugFrame(
          name: "System Telemetry & Hardware",
          icon: Icons.memory,
          trailing: DebugChip(
            color: K.kGreen,
            label: "● LIVE 1Hz"
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _contentRow("HARDWARE_MODEL", deviceSnapshot.data?.name ?? 'QUERYING...'),
              _contentRow("TOTAL_PHYSICAL_RAM", deviceSnapshot.data?.totalRam ?? 'QUERYING...'),
              _contentRow(
                "LIVE_RESIDENT_SET (RSS)",
                isOpen && isActive ? '${currentRamMB.toStringAsFixed(2)} MB' : 'PAUSED',
                highlight: true,
              ),
              const SizedBox(height: 12),
              Container(
                height: 85,
                decoration: BoxDecoration(
                  color: K.kBaG,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: CustomPaint(
                  painter: RamChartPainter(
                    history: ramHistory,
                    peakRamMB: ramHistoryNotifier.peakRamMB,
                    maxRamMB: deviceSnapshot.data?.rawRamMB ?? 4096.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        DebugFrame(
          name: leaks.isEmpty
              ? "Leak Inspector // Integrity Verified"
              : "Critical Anomalies // Leak Detected",
          icon: leaks.isEmpty ? Icons.shield_outlined : Icons.warning_amber_rounded,
          headerColor: leaks.isEmpty ? K.kGreen : K.kRed,
          borderColor: leaks.isEmpty ? null : K.kRed.op5,
          trailing: leaks.isEmpty
              ? DebugChip(label: "PASS", color: K.kGreen)
              : Row(
                children: [
                  DebugChip(color: K.kRed, label: "${leaks.length} LEAKS"),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => ref.read(debugMemoryProvider.notifier).clear(),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B1218),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.delete_sweep, color: K.kRed, size: 16),
                    ),
                  ),
                ],
              ),
          content: leaks.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: K.kGreen.darken(),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: K.kGreen.op2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: K.kGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "ZERO ALLOCATION LEAKS // HEAP CLEAN",
                          style: K.style.copyWith(
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                            color: K.kGreen
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in leaks) _buildLeakItemCard(item),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildLeakItemCard(DebugLeakReport item) {
    final cleanName = item.objectName.replaceAll(" (never disposed)", "");

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: K.kRed.darken(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: K.kRed.op3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DebugChip(color: K.kRed, label: "LEAK",),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanName,
                    style: K.style.copyWith(fontWeight: FontWeight.bold,),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DebugChip(
                  color: K.kBlue,
                  label: "@ ${item.screenName}",
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "ALLOCATION NOT RELEASED // MISSING .dispose() EXECUTION",
              style: K.style.copyWith(
                color: K.kRed.op5,
                fontSize: 9,
                letterSpacing: 0.5
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: K.style.copyWith(
              color: K.kGrey,
              letterSpacing: 0.5
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: K.style.copyWith(
              color: highlight ? K.kBlue : Colors.white,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.5
            ),
          ),
        ],
      ),
    );
  }
}

class RamChartPainter extends CustomPainter {
  final List<double> history;
  final double peakRamMB;
  final double maxRamMB;

  RamChartPainter({required this.history, required this.peakRamMB, required this.maxRamMB});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty || maxRamMB <= 0) return;

    double chartMaxMB = (peakRamMB * 1.25);
    if (chartMaxMB < 256) chartMaxMB = 256;
    if (chartMaxMB > maxRamMB) chartMaxMB = maxRamMB;

    final gridPaint = Paint()
      ..color = K.kNavi
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final maxPoints = 30;
    final stepX = size.width / (maxPoints - 1);
    final stepY = size.height / 4;

    for (int i = 1; i < maxPoints - 1; i += 2) {
      canvas.drawLine(Offset(i * stepX, 0), Offset(i * stepX, size.height), gridPaint);
    }

    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(Offset(0, i * stepY), Offset(size.width, i * stepY), gridPaint);
    }

    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final y = size.height - (history[i] / chartMaxMB * size.height).clamp(0.0, size.height);

      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo((history.length - 1) * stepX, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          K.kBlue.op(0.35),
          K.kBlue.op(0.01),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = K.kBlue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    String formatMB(double mb) {
      if (mb >= 1024) {
        return '${(mb / 1024).toStringAsFixed(1)}GB';
      }
      return '${mb.toInt()}MB';
    }

    final yMaxPainter = TextPainter(
      text: TextSpan(text: 'LIMIT: ${formatMB(chartMaxMB)}', style: K.style.copyWith(
        color: K.kGrey,
         fontSize: 9,
        letterSpacing: 0.5
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    yMaxPainter.paint(canvas, const Offset(4, 3));
    yMaxPainter.dispose();

    final xStartPainter = TextPainter(
      text: TextSpan(text: '-30s', style: K.style.copyWith(
        color: K.kGrey,
         fontSize: 9,
        letterSpacing: 0.5
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    xStartPainter.paint(canvas, Offset(4, size.height - 13));
    xStartPainter.dispose();

    final xEndPainter = TextPainter(
      text: TextSpan(
        text: 'LIVE',
        style: K.style.copyWith(
            color: K.kBlue,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5
        )
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    xEndPainter.paint(canvas, Offset(size.width - xEndPainter.width - 4, size.height - 13));
    xEndPainter.dispose();
  }

  @override
  bool shouldRepaint(covariant RamChartPainter oldDelegate) => true;
}