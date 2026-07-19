import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/standardization_models.dart';

class StandardizationDashboard extends StatefulWidget {
  const StandardizationDashboard({super.key});

  @override
  State<StandardizationDashboard> createState() => _StandardizationDashboardState();
}

class _StandardizationDashboardState extends State<StandardizationDashboard> {
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = true;
  CompanySummaryModel? _companySummary;
  List<ManagerCalibrationModel> _managerCalibrationList = [];
  List<DepartmentSummaryModel> _departmentSummaryList = [];
  List<String> _executiveInsights = [];

  // Table sorting states
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // Track expanded manager index for rating distribution view
  int _expandedManagerIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _expandedManagerIndex = -1;
    });

    try {
      final summary = await _apiClient.getCompanySummary();
      final calibration = await _apiClient.getManagerCalibration();
      final departments = await _apiClient.getDepartmentSummary();
      final insights = await _apiClient.getExecutiveInsights();

      setState(() {
        _companySummary = summary;
        _managerCalibrationList = calibration;
        _departmentSummaryList = departments;
        _executiveInsights = insights;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading calibration metrics: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sort<T>(Comparable<T> Function(ManagerCalibrationModel m) getField, int columnIndex, bool ascending) {
    _managerCalibrationList.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
      _expandedManagerIndex = -1; // Reset selection on sort
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasNoData = _companySummary == null || 
        _companySummary!.evaluationCompletionRate == 0.0 || 
        _managerCalibrationList.every((m) => m.employeesEvaluated == 0);

    if (hasNoData) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.query_stats_outlined, size: 72, color: Colors.amber.shade700),
                      const SizedBox(height: 20),
                      const Text(
                        'Insufficient Calibration Data',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Not enough evaluation data is available to calculate standardization metrics.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppTheme.subtitleColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Loading Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1000;
          final crossAxisCount = constraints.maxWidth > 900 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Evaluation Standardization & Calibration',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadData,
                      tooltip: 'Refresh analytics data',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. KPI Cards Grid
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildKpiCard('Company Avg Perf', _companySummary!.companyAveragePerformance.toStringAsFixed(2), Icons.star, Colors.blue),
                    _buildKpiCard('Company Avg Pot', _companySummary!.companyAveragePotential.toStringAsFixed(2), Icons.trending_up, Colors.teal),
                    _buildKpiCard('Total Managers', '${_companySummary!.totalManagers}', Icons.supervised_user_circle, Colors.amber.shade700),
                    _buildKpiCard('Needs Calibration', '${_companySummary!.managersRequiringCalibration}', Icons.gavel, Colors.orange),
                    _buildKpiCard('Completion Rate', '${_companySummary!.evaluationCompletionRate}%', Icons.done_all, Colors.purple),
                    _buildKpiCard('Standardization Score', '${_companySummary!.overallStandardizationScore}', Icons.balance, Colors.indigo),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Main content split layout
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Manager Calibration Table and Selected Distribution Chart
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildManagerCalibrationTable(),
                            if (_expandedManagerIndex != -1) ...[
                              const SizedBox(height: 16),
                              _buildManagerDetailSection(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right side: Department Metrics and Executive Insights
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildExecutiveInsightsPanel(),
                            const SizedBox(height: 16),
                            _buildDepartmentComparisonList(),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildManagerCalibrationTable(),
                      if (_expandedManagerIndex != -1) ...[
                        const SizedBox(height: 16),
                        _buildManagerDetailSection(),
                      ],
                      const SizedBox(height: 20),
                      _buildExecutiveInsightsPanel(),
                      const SizedBox(height: 20),
                      _buildDepartmentComparisonList(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: color),
                Text(
                  value,
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

  Widget _buildManagerCalibrationTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_outline, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Manager Calibration Directory',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Click rows to expand score distributions and consistency analyses.',
              style: TextStyle(fontSize: 11, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _isAscending,
                showCheckboxColumn: false,
                columns: [
                  DataColumn(
                    label: const Text('Manager Name'),
                    onSort: (columnIndex, ascending) =>
                        _sort<String>((m) => m.managerName, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Text('Dept'),
                    onSort: (columnIndex, ascending) =>
                        _sort<String>((m) => m.department, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Text('Evaluated'),
                    numeric: true,
                    onSort: (columnIndex, ascending) =>
                        _sort<num>((m) => m.employeesEvaluated, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Text('Avg Perf'),
                    numeric: true,
                    onSort: (columnIndex, ascending) =>
                        _sort<num>((m) => m.averagePerformanceRating, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Text('Diff'),
                    numeric: true,
                    onSort: (columnIndex, ascending) =>
                        _sort<num>((m) => m.differenceFromCompanyAverage, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Text('Status'),
                    onSort: (columnIndex, ascending) =>
                        _sort<String>((m) => m.calibrationStatus, columnIndex, ascending),
                  ),
                  DataColumn(
                    label: const Text('Score'),
                    numeric: true,
                    onSort: (columnIndex, ascending) =>
                        _sort<num>((m) => m.standardizationScore, columnIndex, ascending),
                  ),
                ],
                rows: List.generate(_managerCalibrationList.length, (index) {
                  final manager = _managerCalibrationList[index];
                  final isExpanded = _expandedManagerIndex == index;

                  Color statusColor = Colors.green;
                  if (manager.calibrationStatus == 'Strict') {
                    statusColor = Colors.red;
                  } else if (manager.calibrationStatus == 'Generous') {
                    statusColor = Colors.orange;
                  }

                  return DataRow(
                    selected: isExpanded,
                    onSelectChanged: (_) {
                      setState(() {
                        _expandedManagerIndex = isExpanded ? -1 : index;
                      });
                    },
                    cells: [
                      DataCell(
                        Text(manager.managerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      DataCell(Text(manager.department)),
                      DataCell(Text('${manager.employeesEvaluated}')),
                      DataCell(Text(manager.averagePerformanceRating.toStringAsFixed(1))),
                      DataCell(
                        Text(
                          (manager.differenceFromCompanyAverage >= 0 ? '+' : '') +
                              manager.differenceFromCompanyAverage.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: manager.differenceFromCompanyAverage > 0
                                ? Colors.orange.shade800
                                : (manager.differenceFromCompanyAverage < 0 ? Colors.red : Colors.green),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            manager.calibrationStatus,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${manager.standardizationScore}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(manager.standardizationScore),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerDetailSection() {
    final manager = _managerCalibrationList[_expandedManagerIndex];

    Color scoreColor = _getScoreColor(manager.standardizationScore);

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
                  '${manager.managerName} - Calibration Breakdown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _expandedManagerIndex = -1;
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Consistency & Diversity panel
            Row(
              children: [
                Expanded(
                  child: _buildDetailField(
                    'Standardization Score',
                    '${manager.standardizationScore}',
                    textColor: scoreColor,
                  ),
                ),
                Expanded(
                  child: _buildDetailField(
                    'Score Status',
                    manager.scoreStatus,
                    textColor: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailField(
                    'Consistency Analysis',
                    manager.consistencyStatus,
                    textColor: manager.consistencyStatus == 'Low Rating Diversity' ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDetailField(
                    'Average Potential',
                    manager.averagePotentialRating.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            if (manager.consistencyStatus == 'Low Rating Diversity') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: Manager has a rating deviation cluster (under-utilizes the full evaluation spectrum). Calibration is recommended.',
                        style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Rating distribution bars
            const Text(
              'Rating Frequency Distribution',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            _buildDistributionRow(5, manager.ratingDistribution[5] ?? 0.0),
            _buildDistributionRow(4, manager.ratingDistribution[4] ?? 0.0),
            _buildDistributionRow(3, manager.ratingDistribution[3] ?? 0.0),
            _buildDistributionRow(2, manager.ratingDistribution[2] ?? 0.0),
            _buildDistributionRow(1, manager.ratingDistribution[1] ?? 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  size: 11,
                  color: index < stars ? Colors.amber : Colors.grey.shade300,
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double widthFraction = percentage / 100.0;
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * widthFraction,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveInsightsPanel() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Executive Calibration Observations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._executiveInsights.map((insight) {
              IconData icon = Icons.info_outline;
              Color color = Colors.blue;

              if (insight.contains('require')) {
                icon = Icons.gavel_outlined;
                color = Colors.orange;
              } else if (insight.contains('highest')) {
                icon = Icons.trending_up;
                color = Colors.green;
              } else if (insight.contains('balanced')) {
                icon = Icons.balance;
                color = Colors.teal;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentComparisonList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Department Comparison Metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _departmentSummaryList.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final dept = _departmentSummaryList[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dept.departmentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                        ),
                        Text(
                          'Completion: ${dept.completionRate}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Avg Performance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                dept.averagePerformance.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Avg Potential', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                dept.averagePotential.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Evaluated', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                '${dept.employeesEvaluated}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}
