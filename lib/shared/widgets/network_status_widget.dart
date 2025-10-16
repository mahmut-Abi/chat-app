import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/services/network_service.dart';

class NetworkStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showBanner;

  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  final _networkService = NetworkService();
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _listenToConnectivityChanges();
  }

  Future<void> _checkConnection() async {
    final hasNetwork = await _networkService.checkNetworkConnection();

    if (mounted) {
      setState(() {
        _hasConnection = hasNetwork;
      });
    }
  }

  void _listenToConnectivityChanges() {
    _networkService.onConnectivityChanged.listen((results) {
      if (mounted) {
        final hasConnection = !results.contains(ConnectivityResult.none);
        setState(() {
          _hasConnection = hasConnection;
        });

        if (!hasConnection && widget.showBanner) {
          _showNoConnectionSnackBar();
        }
      }
    });
  }

  void _showNoConnectionSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.signal_wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '网络连接中断，请检查网络设置',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_hasConnection && widget.showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red.shade700,
              elevation: 4,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.signal_wifi_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '无网络连接',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: _checkConnection,
                        child: const Text(
                          '重试',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
