import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_storage.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../dashboard/ceo_dashboard.dart';
import '../dashboard/manager_dashboard.dart';
import '../dashboard/employee_dashboard.dart';

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

    await Future.delayed(const Duration(seconds: 1));

    final isConnected = await _apiClient.checkBackendHealth();

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _status = ConnectionStatus.connected;
      });

      // Small delay to let user see "Connected" status briefly
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // Check local session
      final token = await AuthStorage.getAccessToken();
      final user = await AuthStorage.getUser();
      final isExpired = await AuthStorage.isTokenExpired();

      if (token != null && user != null && !isExpired && user.passwordResetRequired != true) {
        Widget dashboard;
        if (user.role == 'CEO') {
          dashboard = const CeoDashboard();
        } else if (user.role == 'MANAGER') {
          dashboard = ManagerDashboard(
            managerId: user.id,
            managerName: '${user.firstName} ${user.lastName}',
            managerEmail: user.email,
          );
        } else {
          dashboard = EmployeeDashboard(
            employeeId: user.id,
            employeeName: '${user.firstName} ${user.lastName}',
            employeeEmail: user.email,
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
        );
      } else {
        // Redirect to login if no session is stored
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _status = ConnectionStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Centered Brand & Logo section
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStatusWidget(),
                    const SizedBox(height: 24),
                    
                    // Clean enterprise footer
                    Text(
                      '© ${DateTime.now().year} EPMS Inc. All rights reserved.',
                      textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildStatusWidget() {
    switch (_status) {
      case ConnectionStatus.loading:
      case ConnectionStatus.connected:
        return const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
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
