import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/manager_metrics_model.dart';
import '../models/team_employee_model.dart';
import '../models/evaluation_model.dart';
import '../models/review_cycle_model.dart';
import '../auth/login_screen.dart';
import 'evaluation_form.dart';

class ManagerDashboard extends StatefulWidget {
  final int managerId;
  final String managerName;
  final String managerEmail;

  const ManagerDashboard({
    super.key,
    required this.managerId,
    required this.managerName,
    required this.managerEmail,
  });

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final ApiClient _apiClient = ApiClient();
  int _currentIndex = 0;

  bool _isLoadingMetrics = false;
  ManagerMetricsModel? _metrics;

  bool _isLoadingTeam = false;
  List<TeamEmployeeModel> _team = [];

  bool _isLoadingReviews = false;
  List<EvaluationModel> _reviews = [];

  ReviewCycleModel? _activeCycle;
  bool _isLoadingCycles = false;
  List<ReviewCycleModel> _cycles = [];

  final List<String> _titles = [
    'Manager Workspace',
    'My Reporting Team',
    'Submitted Evaluations',
    'Review Cycles'
  ];

  @override
  void initState() {
    super.initState();
    _loadTabContent(0);
    _fetchActiveCycle();
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
        _fetchTeam();
        break;
      case 2:
        _fetchReviews();
        break;
      case 3:
        _fetchCycles();
        break;
    }
  }

  Future<void> _fetchActiveCycle() async {
    try {
      final cycles = await _apiClient.getReviewCycles();
      final active = cycles.firstWhere((c) => c.status == 'ACTIVE');
      setState(() {
        _activeCycle = active;
      });
    } catch (_) {
      // Safely handle if no active cycle is defined
    }
  }

  Future<void> _fetchCycles() async {
    setState(() { _isLoadingCycles = true; });
    try {
      final list = await _apiClient.getReviewCycles();
      setState(() { _cycles = list; });
    } catch (_) {
      _showErrorSnackBar('Failed to load review cycles.');
    } finally {
      setState(() { _isLoadingCycles = false; });
    }
  }

  Future<void> _fetchMetrics() async {
    setState(() { _isLoadingMetrics = true; });
    try {
      final data = await _apiClient.getManagerMetrics(widget.managerId);
      setState(() { _metrics = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load metrics summary.');
    } finally {
      setState(() { _isLoadingMetrics = false; });
    }
  }

  Future<void> _fetchTeam() async {
    setState(() { _isLoadingTeam = true; });
    try {
      final data = await _apiClient.getManagerEmployees(widget.managerId);
      setState(() { _team = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load team list.');
    } finally {
      setState(() { _isLoadingTeam = false; });
    }
  }

  Future<void> _fetchReviews() async {
    setState(() { _isLoadingReviews = true; });
    try {
      final data = await _apiClient.getManagerEvaluations(widget.managerId);
      setState(() { _reviews = data; });
    } catch (e) {
      _showErrorSnackBar('Failed to load submitted reviews.');
    } finally {
      setState(() { _isLoadingReviews = false; });
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
            onPressed: () {
              _loadTabContent(_currentIndex);
              _fetchActiveCycle();
            },
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
                child: const Icon(Icons.assignment_ind_outlined, size: 40, color: Colors.white),
              ),
              accountName: Text(widget.managerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.managerEmail),
            ),
            _buildDrawerItem(0, 'Overview Dashboard', Icons.dashboard_outlined),
            _buildDrawerItem(1, 'My Reporting Team', Icons.people_outline),
            _buildDrawerItem(2, 'Submitted Reviews', Icons.rate_review_outlined),
            _buildDrawerItem(3, 'Review Cycles', Icons.event_note_outlined),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await _apiClient.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
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
        return _buildTeamTab();
      case 2:
        return _buildReviewsTab();
      case 3:
        return _buildCyclesTab();
      default:
        return const Center(child: Text('View not found'));
    }
  }

  // --- OVERVIEW DASHBOARD ---
  Widget _buildOverviewTab() {
    if (_isLoadingMetrics) {
      return const Center(child: CircularProgressIndicator());
    }

    final metrics = _metrics;
    if (metrics == null) {
      return const Center(child: Text('Unable to load metrics dashboard stats.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Cycle Banner Card
            Card(
              elevation: 1,
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.event_note, color: AppTheme.primaryColor, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT ACTIVE REVIEW CYCLE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.subtitleColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metrics.activeReviewCycleTitle,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Evaluation Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard('Assigned Employees', '${metrics.assignedEmployees}', Icons.people, Colors.blue),
                  _buildStatCard('Pending Reviews', '${metrics.pendingEvaluations}', Icons.pending_actions, Colors.amber),
                  _buildStatCard('Submitted Reviews', '${metrics.submittedEvaluations}', Icons.task_alt, Colors.green),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 28, color: color),
                Text(
                  count,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // --- MY TEAM TAB ---
  Widget _buildTeamTab() {
    if (_isLoadingTeam) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_team.isEmpty) {
      return const Center(child: Text('No assigned reporting employees found.'));
    }

    return ListView.builder(
      itemCount: _team.length,
      itemBuilder: (context, index) {
        final emp = _team[index];
        final isCompleted = emp.reviewStatus == 'COMPLETED';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE2E8F0),
                  child: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${emp.firstName} ${emp.lastName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Dept: ${emp.department ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: AppTheme.subtitleColor)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        emp.reviewStatus,
                        style: TextStyle(
                          color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action Button
                    ElevatedButton(
                      onPressed: isCompleted || _activeCycle == null
                          ? null
                          : () => _openEvaluationForm(emp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isCompleted ? 'Completed' : 'Evaluate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEvaluationForm(TeamEmployeeModel emp) async {
    if (_activeCycle == null) return;
    
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationForm(
          managerId: widget.managerId,
          employeeId: emp.id,
          employeeName: '${emp.firstName} ${emp.lastName}',
          department: emp.department ?? 'N/A',
          reviewCycleId: _activeCycle!.id,
          reviewCycleTitle: _activeCycle!.title,
        ),
      ),
    );

    if (refresh == true) {
      _fetchTeam();
      _fetchMetrics();
    }
  }

  // --- SUBMITTED REVIEWS TAB ---
  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return const Center(child: Text('No evaluations submitted by you yet.'));
    }

    return ListView.builder(
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final eval = _reviews[index];
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

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

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
}
