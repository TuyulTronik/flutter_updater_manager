import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_updater_manager/flutter_updater_manager.dart';

import 'home_screen.dart';
import 'update_manager_wrapper.dart';

/// Splash screen with update check and progress indicator
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  late final UpdateManager _manager;

  // ============================================================
  // STATE
  // ============================================================

  double _progress = 0.0;
  String _statusText = 'Memulai aplikasi...';
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _progressTimer;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _manager = UpdateManagerWrapper().getManager(
      onProgress: _onProgress,
      onStatusChange: _onStatusChange,
    );

    _startSplashSequence();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _manager.dispose();
    super.dispose();
  }

  // ============================================================
  // CALLBACKS
  // ============================================================

  void _onProgress(UpdateProgress progress) {
    if (mounted) {
      setState(() {
        _progress = progress.progress;
        _statusText = progress.message;
        if (progress.hasError) {
          _errorMessage = progress.errorMessage;
        }
      });
    }
  }

  void _onStatusChange(UpdateManagerStatus status) {
    // Handle status change if needed
  }

  // ============================================================
  // SPLASH SEQUENCE
  // ============================================================

  Future<void> _startSplashSequence() async {
    // 1. Initial delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 2. Check pending install
    await _checkPendingInstall();
    if (!mounted) return;

    // 3. Check updates
    await _checkUpdates();
    if (!mounted) return;

    // 4. Navigate to home
    _navigateToHome();
  }

  Future<void> _checkPendingInstall() async {
    // Check pending native
    final nativePending = await _manager.getPendingNative();
    if (!mounted) return;

    if (nativePending != null) {
      setState(() {
        _statusText = 'Update siap dipasang: ${nativePending.version}';
        _progress = 0.5;
      });

      await _animateProgressTo(0.6);
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final shouldInstall = await _showPendingNativeDialog(nativePending.version);
      if (!mounted) return;

      if (shouldInstall) {
        setState(() {
          _statusText = 'Memasang update...';
        });
        // Native update akan di-handle oleh manager
        await _manager.runUpdate(
          result: UpdateResult(
            hasUpdate: true,
            type: UpdateType.native,
            nativeInfo: null,
            patchInfo: null,
            changelog: null,
          ),
        );
        return;
      }
    }

    // Check pending patch
    final patchPending = await _manager.getPendingPatch();
    if (!mounted) return;

    if (patchPending != null) {
      setState(() {
        _statusText =
            'Patch siap: ${patchPending.version}+${patchPending.patchVersion}';
        _progress = 0.5;
      });

      await _animateProgressTo(0.6);
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final shouldApply = await _showPendingPatchDialog(patchPending);
      if (!mounted) return;

      if (shouldApply) {
        setState(() {
          _statusText = 'Menerapkan patch, restart...';
        });
        await _manager.applyPendingPatch();
        return;
      }
    }
  }

  Future<void> _checkUpdates() async {
    try {
      if (!mounted) return;

      setState(() {
        _statusText = 'Memeriksa pembaruan...';
      });

      await _animateProgressTo(0.3);
      if (!mounted) return;

      final result = await _manager.checkUpdates();
      if (!mounted) return;

      if (!result.hasUpdate) {
        setState(() {
          _statusText = 'Aplikasi sudah versi terbaru';
        });
        await _animateProgressTo(1.0);
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 800));
        return;
      }

      setState(() {
        _statusText = 'Update tersedia!';
      });
      await _animateProgressTo(0.5);
      if (!mounted) return;

      final shouldUpdate = await _manager.showUpdateDialog(
        context,
        result,
      );
      if (!mounted) return;

      if (shouldUpdate) {
        setState(() {
          _statusText = 'Mengupdate...';
        });

        await _manager.runUpdate(result: result);
        if (!mounted) return;

        setState(() {
          _statusText = 'Update selesai!';
        });
        await _animateProgressTo(1.0);
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        setState(() {
          _statusText = 'Update dibatalkan';
        });
        await _animateProgressTo(1.0);
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _statusText = 'Error: $e';
      });
      await _animateProgressTo(0.5);
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  Future<bool> _showPendingNativeDialog(String version) async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Update Siap Dipasang'),
            content: Text('Versi $version telah diunduh.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Install Sekarang'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showPendingPatchDialog(
    ({
      String version,
      String patchVersion,
      String tagName,
      String releaseNotes,
    }) pending,
  ) async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Patch Siap Diterapkan'),
            content: Text(
              'Patch ${pending.version}+${pending.patchVersion} siap.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restart Sekarang'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<void> _animateProgressTo(double target) async {
    if (target <= _progress) return;

    final start = _progress;
    final difference = target - start;
    final steps = 20;
    final stepDuration = const Duration(milliseconds: 30);
    final stepValue = difference / steps;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      setState(() {
        _progress = start + (stepValue * i);
      });
      await Future.delayed(stepDuration);
    }

    if (!mounted) return;
    setState(() {
      _progress = target;
    });
  }

  void _navigateToHome() {
    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isError = _errorMessage != null;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_outline : Icons.update,
                    size: 50,
                    color: isError ? Colors.red : Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                Text(
                  'Update Manager',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Example App',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 40),

                // Progress Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isError ? Colors.red : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isError) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: isError ? 1.0 : _progress.clamp(0, 1),
                          backgroundColor: Colors.grey.shade200,
                          color: isError
                              ? Colors.red
                              : _progress >= 1.0
                                  ? Colors.green
                                  : Colors.blue,
                          minHeight: 10,
                        ),
                      ),
                      if (isError) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_isLoading && !isError) ...[
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
                ],

                if (isError) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _progress = 0.0;
                        _isLoading = true;
                        _statusText = 'Mencoba ulang...';
                      });
                      _startSplashSequence();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}