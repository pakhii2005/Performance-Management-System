import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

enum ConnectionStatus { loading, connected, failed }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiClient _apiClient = ApiClient();
  ConnectionStatus _status = ConnectionStatus.loading;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _status = ConnectionStatus.loading;
    });

    // Small delay to make the transition smooth and visible
    await Future.delayed(const Duration(seconds: 1));

    final isConnected = await _apiClient.checkBackendHealth();

    if (mounted) {
      setState(() {
        _status = isConnected ? ConnectionStatus.connected : ConnectionStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),
              
              // Centered Brand & Logo section
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Centered logo placeholder with elegant enterprise-grade styling
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.insights_rounded,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Application Title
                    Text(
                      'Enterprise Performance\nManagement System',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'EPMS • Foundation Phase 1',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Connection Status indicators at the bottom
              Column(
                children: [
                  _buildStatusWidget(),
                  const SizedBox(height: 24),
                  
                  // Clean enterprise footer
                  Text(
                    '© ${DateTime.now().year} EPMS Inc. All rights reserved.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtitleColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    switch (_status) {
      case ConnectionStatus.loading:
        return Column(
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      case ConnectionStatus.connected:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7), // Soft green
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 18),
              SizedBox(width: 8),
              Text(
                'Backend Connected',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      case ConnectionStatus.failed:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2), // Soft red
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_rounded, color: Color(0xFFB91C1C), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Unable to connect to server',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentColor),
              onPressed: _checkConnection,
              tooltip: 'Retry Connection',
            ),
          ],
        );
    }
  }
}
