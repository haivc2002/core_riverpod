import 'package:core_flutter/core_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:core_flutter/common/global_entity.dart';
import 'package:core_flutter/common/k.dart';
import 'package:core_flutter/debug/debug_widget/debug_frame.dart';
import 'package:core_flutter/debug/debug_widget/debug_chip.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class DebugMemoryTab extends HookConsumerWidget {
  const DebugMemoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = GlobalAction.debugActions;
    final actionKeys = actions.keys.toList();
    final actionCount = actionKeys.length;

    final storageFuture = useMemoized(() async {
      Map<String, String> prefsData = {};
      Map<String, String> secureData = {};

      try {
        final prefs = await SharedPreferences.getInstance();
        for (final key in prefs.getKeys()) {
          prefsData[key] = prefs.get(key).toString();
        }
      } catch (e) {
        prefsData['[ERROR]'] = e.toString();
      }

      try {
        const secureStorage = FlutterSecureStorage();
        secureData = await secureStorage.readAll();
      } catch (e) {
        secureData['[ERROR]'] = e.toString();
      }

      return (prefs: prefsData, secure: secureData);
    });

    final storageSnapshot = useFuture(storageFuture);
    final prefsData = storageSnapshot.data?.prefs ?? {};
    final secureData = storageSnapshot.data?.secure ?? {};
    final isLoading = storageSnapshot.connectionState == ConnectionState.waiting;

    return WidgetListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      children: [
        DebugFrame(
          name: "Global Action Registry",
          icon: Icons.functions,
          trailing: DebugChip(
            color: actionCount > 0 ? K.kGreen : K.kGrey,
            label: "$actionCount REGISTERED",
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _contentRow(
                "MEMORY_FOOTPRINT",
                "~${actionCount * 32} BYTES",
                highlight: true,
              ),
              if (actionCount > 0) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: actionKeys.map((k) => DebugChip(
                    label: k,
                    color: K.kBlue,
                  )).toList(),
                ),
              ]
            ],
          ),
        ),
        
        const SizedBox(height: 14),

        DebugFrame(
          name: "SharedPreferences",
          icon: Icons.sd_storage_outlined,
          trailing: DebugChip(
            color: isLoading ? K.kGrey : (prefsData.isNotEmpty ? K.kBlue : K.kGrey),
            label: isLoading ? "LOADING..." : "${prefsData.length} KEYS",
          ),
          content: isLoading 
            ? _buildLoading()
            : _buildStorageMap(prefsData),
        ),

        const SizedBox(height: 14),

        DebugFrame(
          name: "Secure Storage // Keychain",
          icon: Icons.security,
          headerColor: K.kGreen,
          borderColor: K.kGreen.op2,
          trailing: DebugChip(
            color: isLoading ? K.kGrey : (secureData.isNotEmpty ? K.kGreen : K.kGrey),
            label: isLoading ? "LOADING..." : "${secureData.length} KEYS",
          ),
          content: isLoading 
            ? _buildLoading()
            : _buildStorageMap(secureData, isSecure: true),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          "READING STORAGE...",
          style: K.style.copyWith(color: K.kGrey, fontSize: 10, letterSpacing: 1.0),
        ),
      ),
    );
  }

  Widget _buildStorageMap(Map<String, String> data, {bool isSecure = false}) {
    if (data.isEmpty) {
      return Text(
        "[EMPTY] NO DATA ALLOCATED",
        style: K.style.copyWith(color: K.kGrey, fontSize: 10, letterSpacing: 0.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isSecure ? Icons.lock : Icons.key, size: 10, color: isSecure ? K.kGreen : K.kBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e.key,
                      style: K.style.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: K.kBaG,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.value,
                  style: K.style.copyWith(
                    color: K.kGrey,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: K.style.copyWith(
              color: highlight ? K.kBlue : Colors.white,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}