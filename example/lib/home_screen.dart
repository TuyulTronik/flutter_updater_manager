import 'package:flutter/material.dart';
import 'package:flutter_updater_manager/flutter_updater_manager.dart';

import 'update_manager_wrapper.dart';

/// Home screen after splash
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final UpdateManager _manager;
  UpdateResult? _lastResult;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();

    // ✅ Gunakan callback di constructor, bukan di-set setelah inisialisasi
    _manager = UpdateManagerWrapper().getManager(
      onProgress: (progress) {
        // Handle progress if needed
      },
      onStatusChange: (status) {
        if (mounted) {
          setState(() {
            _status = status.toString().split('.').last;
          });
        }
      },
    );
  }

  Future<void> _checkUpdate() async {
    try {
      final result = await _manager.checkUpdates();

      // ✅ Guard mounted
      if (!mounted) return;

      setState(() {
        _lastResult = result;
      });

      if (result.hasUpdate) {
        final shouldUpdate = await _manager.showUpdateDialog(
          context,
          result,
        );

        // ✅ Guard mounted
        if (!mounted) return;

        if (shouldUpdate) {
          await _manager.runUpdate(result: result);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _applyPendingPatch() async {
    try {
      await _manager.applyPendingPatch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: $_status',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              if (_lastResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last check: ${_lastResult!.hasUpdate ? "Update available" : "No update"}',
                  style: TextStyle(
                    color: _lastResult!.hasUpdate ? Colors.orange : Colors.green,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _checkUpdate,
                icon: const Icon(Icons.update),
                label: const Text('Check Update'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _applyPendingPatch,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Apply Pending Patch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}