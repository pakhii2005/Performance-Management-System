import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../models/evaluation_model.dart';
import '../models/review_cycle_model.dart';
import '../models/radar_data_model.dart';
import 'radar_chart_widget.dart';
import '../auth/login_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final String employeeEmail;

  const EmployeeDashboard({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
  });

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final ApiClient _apiClient = ApiClient();
  int _currentIndex = 0;

  bool _isLoadingProfile = false;
  UserModel? _profile;

  bool _isLoadingEvaluations = false;
  List<EvaluationModel> _evaluations = [];

  ReviewCycleModel? _activeCycle;

  bool _isLoadingRadar = false;
  List<RadarDataModel> _radarDataList = [];
  int _selectedRadarIndex = -1;

  final List<String> _titles = [
    'Employee Workspace',
    'My Profile',
    'My Performance Evaluations'
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
        _fetchProfile();
        _fetchEvaluations();
        _fetchRadarData();
        break;
      case 1:
        _fetchProfile();
        break;
      case 2:
        _fetchEvaluations();
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
      // Safely ignore if no cycle active
    }
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoadingProfile = true; });
    try {
      final data = await _apiClient.getEmployeeProfile(widget.employeeId);
      setState(() { _profile = data; });
    } catch (e) {
      _showErrorSnackBar('Unable to load profile information.');
    } finally {
      setState(() { _isLoadingProfile = false; });
    }
  }

  Future<void> _fetchEvaluations() async {
    setState(() { _isLoadingEvaluations = true; });
    try {
      final data = await _apiClient.getEmployeeEvaluations(widget.employeeId);
      setState(() { _evaluations = data; });
    } catch (e) {
      _showErrorSnackBar('Unable to Load Evaluations');
    } finally {
      setState(() { _isLoadingEvaluations = false; });
    }
  }

  Future<void> _fetchRadarData() async {
    setState(() { _isLoadingRadar = true; });
    try {
      final data = await _apiClient.getEmployeePerformanceRadar(widget.employeeId);
      setState(() {
        _radarDataList = data;
        if (data.isNotEmpty) {
          _selectedRadarIndex = 0; // Default to latest review cycle
        } else {
          _selectedRadarIndex = -1;
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load performance competency data.');
    } finally {
      setState(() { _isLoadingRadar = false; });
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
            tooltip: 'Refresh details',
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
                child: const Icon(Icons.person_pin, size: 40, color: Colors.white),
              ),
              accountName: Text(widget.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.employeeEmail),
            ),
            _buildDrawerItem(0, 'Dashboard Overview', Icons.dashboard_outlined),
            _buildDrawerItem(1, 'My Profile details', Icons.account_circle_outlined),
            _buildDrawerItem(2, 'My Evaluations Feed', Icons.rate_review_outlined),
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
        return _buildProfileTab();
      case 2:
        return _buildEvaluationsTab();
      default:
        return const Center(child: Text('View not found'));
    }
  }

  // --- DASHBOARD OVERVIEW TAB ---
  Widget _buildOverviewTab() {
    if (_isLoadingProfile || _isLoadingEvaluations) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = _profile;
    final totalEvals = _evaluations.length;
    final activeTitle = _activeCycle != null ? _activeCycle!.title : 'No Active Cycle';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Banner Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(Icons.waving_hand, color: Colors.amber, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(fontSize: 14, color: AppTheme.subtitleColor),
                        ),
                        Text(
                          widget.employeeName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
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
            'My Performance Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          // Info Cards grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Department',
                          profile?.department ?? 'N/A',
                          Icons.business,
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Assigned Manager',
                          profile?.managerName ?? 'No Manager Assigned',
                          Icons.assignment_ind,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Active Review Cycle',
                          activeTitle,
                          Icons.calendar_today,
                          Colors.amber,
                        ),
                      ),
                      if (isWide) const SizedBox(width: 12),
                      if (isWide)
                        Expanded(
                          child: _buildSummaryCard(
                            'Evaluations Received',
                            '$totalEvals',
                            Icons.fact_check,
                            Colors.blue,
                          ),
                        ),
                    ],
                  ),
                  if (!isWide) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Evaluations Received',
                            '$totalEvals',
                            Icons.fact_check,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Competency Radar Insights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          _isLoadingRadar
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _radarDataList.isEmpty
                  ? Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.radar_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No detailed manager evaluations found yet.',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int>(
                              value: _selectedRadarIndex,
                              decoration: InputDecoration(
                                labelText: 'Select Review Cycle',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: List.generate(_radarDataList.length, (index) {
                                final rd = _radarDataList[index];
                                return DropdownMenuItem(
                                  value: index,
                                  child: Text(rd.reviewCycle),
                                );
                              }),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRadarIndex = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                height: 260,
                                width: 260,
                                child: RadarChartWidget(
                                  competencyScores: _radarDataList[_selectedRadarIndex].competencyScores,
                                  size: 260,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Overall Performance',
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStars(_radarDataList[_selectedRadarIndex].performanceRating),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Overall Potential',
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStars(_radarDataList[_selectedRadarIndex].potentialRating),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Manager Comments / Feedback',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _radarDataList[_selectedRadarIndex].managerComments ?? 'No feedback comments provided.',
                                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Evaluated on: ${_formatDate(_radarDataList[_selectedRadarIndex].reviewDate)}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- MY PROFILE TAB ---
  Widget _buildProfileTab() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: Text('Failed to load profile details.'));
    }

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 48, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('EMPLOYEE PROFILE INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Divider(height: 24),
                  _buildProfileRow('First Name', profile.firstName),
                  _buildProfileRow('Last Name', profile.lastName),
                  _buildProfileRow('Email Address', profile.email),
                  _buildProfileRow('Department', profile.department ?? 'N/A'),
                  _buildProfileRow('Manager Name', profile.managerName ?? 'No Manager Assigned'),
                  _buildProfileRow('Corporate Role', profile.role),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  // --- MY EVALUATIONS TAB ---
  Widget _buildEvaluationsTab() {
    if (_isLoadingEvaluations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_evaluations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No evaluations available.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.subtitleColor),
            ),
          ],
        ),
      );
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
                    Expanded(
                      child: Text(
                        eval.reviewCycleTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
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
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => _showEvaluationDetailsDialog(eval),
                    child: const Text('View Details'),
                  ),
                ),
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

  // --- VIEW DETAILS MODAL ---
  void _showEvaluationDetailsDialog(EvaluationModel eval) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Evaluation Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogRow('Employee Name', eval.employeeName),
                  _buildDialogRow('Manager Name', eval.managerName),
                  _buildDialogRow('Review Cycle', eval.reviewCycleTitle),
                  _buildDialogRow('Submission Date', _formatDate(eval.submittedDate)),
                  const Divider(height: 24),
                  const Text('Ratings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
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
                  const Divider(height: 28),
                  const Text('Manager Comments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      eval.managerComments ?? 'No comments provided',
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}
