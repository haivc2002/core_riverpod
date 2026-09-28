import 'dart:convert';
import 'package:core_riverpod/common/k.dart';
import 'package:core_riverpod/core_riverpod.dart';
import 'package:core_riverpod/debug/debug_notifier/debug_network_notifier.dart';
import 'package:core_riverpod/debug/debug_widget/debug_chip.dart';
import 'package:core_riverpod/debug/debug_widget/debug_frame.dart';
import 'package:core_riverpod/network/network_dev_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DebugNetworkTab extends HookConsumerWidget {
  const DebugNetworkTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final networkErrors = ref.watch(debugNetworkProvider);
    final hasErrors = networkErrors.isNotEmpty;

    return WidgetListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      children: [
        DebugFrame(
          name: hasErrors
              ? "API Error Console // ${networkErrors.length} Exceptions"
              : "API Error Console // Zero Anomalies",
          icon: hasErrors
              ? Icons.wifi_tethering_error_rounded_outlined
              : Icons.check_circle_outline,
          headerColor: hasErrors ? K.kOrange : K.kGreen,
          borderColor: hasErrors ? K.kOrange.op5 : null,
          trailing: hasErrors
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DebugChip(color: K.kOrange, label: "${networkErrors.length} ERRORS"),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => ref.read(debugNetworkProvider.notifier).clear(),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1F10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.delete_sweep, color: Color(0xFFF59E0B), size: 16),
                      ),
                    ),
                  ],
                )
              : DebugChip(label: "PASS", color: K.kGreen,),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasErrors) ...[
                Container(
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
                          "ZERO API EXCEPTIONS // HTTP PIPELINE CLEAN",
                          style: K.style.copyWith(
                            color: K.kGreen,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (final error in networkErrors) _NetworkErrorCard(error: error),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NetworkErrorCard extends HookWidget {
  final NetworkErrorInfo error;
  const _NetworkErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);

    final statusCode = error.statusCode;
    Color statusColor;
    if (statusCode != null) {
      if (statusCode >= 500) {
        statusColor = const Color(0xFFF43F5E);
      } else if (statusCode >= 400) {
        statusColor = const Color(0xFFF59E0B);
      } else {
        statusColor = const Color(0xFF38BDF8);
      }
    } else {
      statusColor = const Color(0xFFA855F7);
    }

    final methodColor = switch (error.method) {
      'GET' => K.kBlue,
      'POST' => K.kGreen,
      'PUT' => K.kOrange,
      'DELETE' => K.kRed,
      _ => K.kGrey,
    };

    final timeStr =
        "${error.timestamp.hour.toString().padLeft(2, '0')}:${error.timestamp.minute.toString().padLeft(2, '0')}:${error.timestamp.second.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: methodColor.darken(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: methodColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => isExpanded.value = !isExpanded.value,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DebugChip(label: error.method, color: methodColor,),
                  const SizedBox(width: 6),
                  DebugChip(
                    label: statusCode != null ? "$statusCode" : "NO RESPONSE",
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${error.durationMs}ms",
                    style: K.style.copyWith(color: K.kGrey, fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: K.style.copyWith(color: K.kGrey, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded.value ? Icons.expand_less : Icons.expand_more,
                    color: K.kGrey,
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                error.url,
                style: K.style.copyWith(),
                maxLines: isExpanded.value ? 5 : 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              Text(
                "${error.errorType} // ${error.message}",
                style: K.style.copyWith(color: methodColor, fontSize: 10),
                maxLines: isExpanded.value ? 10 : 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (isExpanded.value) ...[
                Divider(height: 16, color: methodColor.op3),
                if (error.queryParameters != null && error.queryParameters!.isNotEmpty) ...[
                  _buildDetailSection("QUERY PARAMETERS", _formatJson(error.queryParameters)),
                  const SizedBox(height: 8),
                ],
                if (error.requestData != null) ...[
                  _buildDetailSection("REQUEST BODY", _formatJson(error.requestData)),
                  const SizedBox(height: 8),
                ],

                if (error.responseData != null) ...[
                  _buildDetailSection("RESPONSE DATA", _formatJson(error.responseData)),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: error.url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Copied!"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 12),
                      label: const Text("Copy URL", style: TextStyle(fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: K.kBlue,
                        side: const BorderSide(color: K.kBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        final fullLog = StringBuffer()
                          ..writeln("[${error.method}] ${error.url}")
                          ..writeln("Status: ${error.statusCode} (${error.errorType})")
                          ..writeln("Duration: ${error.durationMs}ms")
                          ..writeln("Message: ${error.message}");
                        if (error.requestData != null) {
                          fullLog.writeln("Request: ${error.requestData}");
                        }
                        if (error.responseData != null) {
                          fullLog.writeln("Response: ${error.responseData}");
                        }
                        Clipboard.setData(ClipboardData(text: fullLog.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Copied!"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 12),
                      label: const Text("Copy Log", style: TextStyle(fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: K.kGrey,
                        side: const BorderSide(color: K.kGrey),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: K.style.copyWith(
            fontSize: 9,
            color: K.kGrey,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: K.kBaG,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: K.kBorder),
          ),
          child: SelectableText(
            content,
            style: K.style.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return "null";
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}