import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/metrics_model.dart';
import '../models/review_cycle_model.dart';
import '../models/evaluation_model.dart';
import '../models/talent_matrix_model.dart';
import 'standardization_dashboard.dart';
import '../auth/login_screen.dart';

class CeoDashboard extends StatefulWidget {
  const CeoDashboard({super.key});

  @override
  State<CeoDashboard> createState() => _CeoDashboardState();
}

class _CeoDashboardState extends State<CeoDashboard> {
  final ApiClient _apiClient = ApiClient();
  int _currentIndex = 0;
  
  bool _isLoadingMetrics = false;
  MetricsModel? _metrics;
  
  bool _isLoadingEmployees = false;
  List<UserModel> _employees = [];
  
  bool _isLoadingManagers = false;
  List<UserModel> _managers = [];
  
  bool _isLoadingCycles = false;
  List<ReviewCycleModel> _cycles = [];
  
  bool _isLoadingEvaluations = false;
  List<EvaluationModel> _evaluations = [];

  bool _isLoadingTalentMatrix = false;
  List<TalentMatrixModel> _talentMatrix = [];
  TalentMatrixModel? _selectedEmployee;

  final List<String> _titles = [
    'CEO Overview',
    'Employees Directory',
    'Managers Directory',
    'Review Cycles',
    'Submitted Evaluations',
    'Performance Standardization'
  ];

  @override
  void initState() {
    super.initState();
    _loadTabContent(0);
  }

  void _loadTabContent(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        _fetchMetrics();
        break;
      case 1:
        _fetchEmployees();
        break;
      case 2:
        _fetchManagers();
        break;
      case 3:
        _fetchCycles();
        break;
      case 4:
        _fetchEvaluations();
        break;
      case 5:
        // Handled within StandardizationDashboard itself
        break;
    }
  }

  Future<void> _fetchMetrics() async {
    setState(() { 
      _isLoadingMetrics = true; 
      _isLoadingTalentMatrix = true; 
    });
    try {
      final data = await _apiClient.getCeoMetrics();
      final matrixData = await _apiClient.getTalentMatrix();
      setState(() { 
        _metrics = data; 
        _talentMatrix = matrixData;
        _selectedEmployee = null; // Reset selection
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load dashboard metrics summary.');
    } finally {
      setState(() { 
        _isLoadingMetrics = false; 
        _isLoadingTalentMatrix = false; 
      });
    }
  }

  Future<void> _fetchEmployees() async {
    setState(() { _isLoadingEmployees = true; });
    try {
      final data = await _apiClient.getEmployees();
      setState(() { _employees = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load employees list.');
    } finally {
      setState(() { _isLoadingEmployees = false; });
    }
  }

  Future<void> _fetchManagers() async {
    setState(() { _isLoadingManagers = true; });
    try {
      final data = await _apiClient.getManagers();
      setState(() { _managers = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load managers list.');
    } finally {
      setState(() { _isLoadingManagers = false; });
    }
  }

  Future<void> _fetchCycles() async {
    setState(() { _isLoadingCycles = true; });
    try {
      final data = await _apiClient.getReviewCycles();
      setState(() { _cycles = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load review cycles.');
    } finally {
      setState(() { _isLoadingCycles = false; });
    }
  }

  Future<void> _fetchEvaluations() async {
    setState(() { _isLoadingEvaluations = true; });
    try {
      final data = await _apiClient.getEvaluations();
      setState(() { _evaluations = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load evaluations list.');
    } finally {
      setState(() { _isLoadingEvaluations = false; });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTabContent(_currentIndex),
            tooltip: 'Refresh current view',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.primaryColor),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.accentColor.withValues(alpha: 0.2),
                child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
              ),
              accountName: const Text('Sarah Jenkins', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('sarah.ceo@epms.com'),
            ),
            _buildDrawerItem(0, 'Overview Dashboard', Icons.dashboard_outlined),
            _buildDrawerItem(1, 'Employees List', Icons.people_outline),
            _buildDrawerItem(2, 'Managers List', Icons.supervised_user_circle_outlined),
            _buildDrawerItem(3, 'Review Cycles', Icons.event_note_outlined),
            _buildDrawerItem(4, 'Evaluations Feed', Icons.rate_review_outlined),
            _buildDrawerItem(5, 'Performance Standardization', Icons.balance_outlined),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBody(),
        ),
      ),
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton(
              onPressed: _showCreateCycleDialog,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.accentColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.accentColor : Colors.black87,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close drawer
        _loadTabContent(index);
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildEmployeesTab();
      case 2:
        return _buildManagersTab();
      case 3:
        return _buildCyclesTab();
      case 4:
        return _buildEvaluationsTab();
      case 5:
        return const StandardizationDashboard();
      default:
        return const Center(child: Text('View not found'));
    }
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab() {
    if (_isLoadingMetrics) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final metrics = _metrics;
    if (metrics == null) {
      return const Center(child: Text('Unable to load counts summary data.'));
    }

    // Compute High Performers & Needs Development counts dynamically
    final int highPerformersCount = _talentMatrix.where((e) => e.performanceRating >= 4 && e.potentialRating >= 4).length;
    final int needsDevCount = _talentMatrix.where((e) => e.performanceRating <= 2 && e.potentialRating <= 2).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final crossAxisCount = isWide ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Organization Pulse',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              // 6 KPI Grid Cards
              GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard('Total Employees', '${metrics.totalEmployees}', Icons.people, Colors.blue),
                  _buildStatCard('Managers', '${metrics.totalManagers}', Icons.supervised_user_circle, Colors.teal),
                  _buildStatCard('Active Review Cycles', '${metrics.activeReviewCycles}', Icons.loop, Colors.amber),
                  _buildStatCard('Completed Evaluations', '${metrics.submittedEvaluations}', Icons.fact_check, Colors.indigo),
                  _buildStatCard('High Performers', '$highPerformersCount', Icons.star, Colors.green),
                  _buildStatCard('Needs Development', '$needsDevCount', Icons.warning_amber_rounded, Colors.redAccent),
                ],
              ),
              const SizedBox(height: 28),
              // 9-Box Talent Matrix
              _buildTalentMatrix(),
              const SizedBox(height: 20),
              // Selected Employee Details
              _buildSelectedEmployeeDetails(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: color),
                Text(
                  count,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalentMatrix() {
    if (_isLoadingTalentMatrix) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Talent Distribution Matrix (9-Box Grid)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select an employee point to view full organizational insights',
              style: TextStyle(fontSize: 12, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 380,
              child: Row(
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Potential',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                        ),
                      ),
                      Text('High (4-5)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Med (3)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Low (1-2)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                      SizedBox(height: 24),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildMatrixCell('Emerging Talent', Colors.orange, Colors.orange.shade900, _filterEmployees(0, 2))),
                              Expanded(child: _buildMatrixCell('Emerging Talent', Colors.orange, Colors.orange.shade900, _filterEmployees(1, 2))),
                              Expanded(child: _buildMatrixCell('High Performer', Colors.green, Colors.green.shade900, _filterEmployees(2, 2))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildMatrixCell('Needs Dev', Colors.red, Colors.red.shade900, _filterEmployees(0, 1))),
                              Expanded(child: _buildMatrixCell('Core Contributor', Colors.blue, Colors.blue.shade900, _filterEmployees(1, 1))),
                              Expanded(child: _buildMatrixCell('Core Contributor', Colors.blue, Colors.blue.shade900, _filterEmployees(2, 1))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildMatrixCell('Needs Dev', Colors.red, Colors.red.shade900, _filterEmployees(0, 0))),
                              Expanded(child: _buildMatrixCell('Needs Dev', Colors.red, Colors.red.shade900, _filterEmployees(1, 0))),
                              Expanded(child: _buildMatrixCell('Core Contributor', Colors.blue, Colors.blue.shade900, _filterEmployees(2, 0))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            const Expanded(child: Center(child: Text('Low (1-2)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)))),
                            const Expanded(child: Center(child: Text('Med (3)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)))),
                            const Expanded(child: Center(child: Text('High (4-5)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Performance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixCell(String title, Color bgColor, Color textColor, List<TalentMatrixModel> employees) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.06),
        border: Border.all(color: bgColor.withValues(alpha: 0.25), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: employees.map((emp) {
                    final isSelected = _selectedEmployee == emp;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmployee = emp;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected ? textColor : bgColor.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black87 : Colors.white,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(emp.employeeName),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedEmployeeDetails() {
    final emp = _selectedEmployee;
    if (emp == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  emp.employeeName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedEmployee = null;
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDetailField('Department', emp.department)),
                Expanded(child: _buildDetailField('Assigned Manager', emp.managerName)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDetailField('Performance Rating', '${emp.performanceRating} / 5')),
                Expanded(child: _buildDetailField('Potential Rating', '${emp.potentialRating} / 5')),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailField('Latest Review Cycle', emp.reviewCycle),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  List<TalentMatrixModel> _filterEmployees(int xIndex, int yIndex) {
    return _talentMatrix.where((emp) {
      int getXIndex(int rating) {
        if (rating <= 2) return 0;
        if (rating == 3) return 1;
        return 2;
      }
      int getYIndex(int rating) {
        if (rating <= 2) return 0;
        if (rating == 3) return 1;
        return 2;
      }
      return getXIndex(emp.performanceRating) == xIndex && getYIndex(emp.potentialRating) == yIndex;
    }).toList();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '';
  }

  // --- EMPLOYEES TAB ---
  Widget _buildEmployeesTab() {
    if (_isLoadingEmployees) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_employees.isEmpty) {
      return const Center(child: Text('No employees found in the organization.'));
    }

    return ListView.builder(
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            title: Text('${emp.firstName} ${emp.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Department: ${emp.department ?? 'N/A'}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Manager', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(emp.managerName ?? 'No Manager', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- MANAGERS TAB ---
  Widget _buildManagersTab() {
    if (_isLoadingManagers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_managers.isEmpty) {
      return const Center(child: Text('No managers found in the organization.'));
    }

    return ListView.builder(
      itemCount: _managers.length,
      itemBuilder: (context, index) {
        final mgr = _managers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.supervised_user_circle, color: Color(0xFF15803D)),
            ),
            title: Text('${mgr.firstName} ${mgr.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Department: ${mgr.department ?? 'N/A'}'),
            trailing: Chip(
              backgroundColor: const Color(0xFFDBEAFE),
              side: BorderSide.none,
              label: Text(
                'Reports: ${mgr.employeeCount ?? 0}',
                style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- REVIEW CYCLES TAB ---
  Widget _buildCyclesTab() {
    if (_isLoadingCycles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cycles.isEmpty) {
      return const Center(child: Text('No review cycles created yet.'));
    }

    return ListView.builder(
      itemCount: _cycles.length,
      itemBuilder: (context, index) {
        final cycle = _cycles[index];
        final isActive = cycle.status == 'ACTIVE';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cycle.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cycle.status,
                        style: TextStyle(
                          color: isActive ? const Color(0xFF15803D) : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (cycle.description != null && cycle.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(cycle.description!, style: const TextStyle(fontSize: 13, color: AppTheme.subtitleColor)),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Start: ${_formatDate(cycle.startDate)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    Text('End: ${_formatDate(cycle.endDate)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  // --- EVALUATIONS TAB ---
  Widget _buildEvaluationsTab() {
    if (_isLoadingEvaluations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_evaluations.isEmpty) {
      return const Center(child: Text('No evaluations have been submitted yet.'));
    }

    return ListView.builder(
      itemCount: _evaluations.length,
      itemBuilder: (context, index) {
        final eval = _evaluations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      eval.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                    ),
                    Text(
                      _formatDate(eval.submittedDate),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Evaluated by: ${eval.managerName}', style: const TextStyle(fontSize: 13, color: AppTheme.subtitleColor)),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Performance Rating', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          _buildStars(eval.performanceRating),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Potential Rating', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          _buildStars(eval.potentialRating),
                        ],
                      ),
                    ),
                  ],
                ),
                if (eval.managerComments != null && eval.managerComments!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Comments:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    eval.managerComments!,
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  // --- CREATE REVIEW CYCLE DIALOG ---
  void _showCreateCycleDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String status = 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> selectStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now().minusDays(365),
                lastDate: DateTime.now().plusDays(365 * 2),
              );
              if (picked != null) {
                setDialogState(() {
                  startDate = picked;
                });
              }
            }

            Future<void> selectEndDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: startDate ?? DateTime.now().minusDays(365),
                lastDate: DateTime.now().plusDays(365 * 2),
              );
              if (picked != null) {
                setDialogState(() {
                  endDate = picked;
                });
              }
            }

            return AlertDialog(
              title: const Text('Create Review Cycle', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title *'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        // Start Date
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                startDate == null
                                    ? 'Start Date *'
                                    : 'Start: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
                                style: TextStyle(color: startDate == null ? Colors.red : Colors.black87),
                              ),
                            ),
                            TextButton(
                              onPressed: selectStartDate,
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // End Date
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                endDate == null
                                    ? 'End Date *'
                                    : 'End: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                                style: TextStyle(color: endDate == null ? Colors.red : Colors.black87),
                              ),
                            ),
                            TextButton(
                              onPressed: selectEndDate,
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                            DropdownMenuItem(value: 'ARCHIVED', child: Text('ARCHIVED')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                status = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (startDate == null || endDate == null) {
                      _showErrorSnackBar('Dates are required');
                      return;
                    }
                    if (endDate!.isBefore(startDate!)) {
                      _showErrorSnackBar('End Date cannot be before Start Date');
                      return;
                    }

                    Navigator.pop(context); // Close dialog
                    
                    setState(() {
                      _isLoadingCycles = true;
                    });

                    try {
                      await _apiClient.createReviewCycle(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
                        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
                        status: status,
                      );
                      
                      // Refresh dashboard pulse & cycles list
                      _fetchCycles();
                      _fetchMetrics();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review Cycle Created Successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
                    } finally {
                      setState(() {
                        _isLoadingCycles = false;
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Simple extension helper to subtract days from DateTime
extension DateTimeExtension on DateTime {
  DateTime minusDays(int days) {
    return subtract(Duration(days: days));
  }
  DateTime plusDays(int days) {
    return add(Duration(days: days));
  }
}
