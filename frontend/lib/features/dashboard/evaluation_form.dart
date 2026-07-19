import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/team_average_model.dart';

class EvaluationForm extends StatefulWidget {
  final int managerId;
  final int employeeId;
  final String employeeName;
  final String department;
  final int reviewCycleId;
  final String reviewCycleTitle;

  const EvaluationForm({
    super.key,
    required this.managerId,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.reviewCycleId,
    required this.reviewCycleTitle,
  });

  @override
  State<EvaluationForm> createState() => _EvaluationFormState();
}

class _EvaluationFormState extends State<EvaluationForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  final _commentsController = TextEditingController();

  int? _performanceRating;
  int? _potentialRating;

  int? _communicationScore;
  int? _technicalSkillScore;
  int? _problemSolvingScore;
  int? _leadershipScore;
  int? _teamworkScore;
  int? _adaptabilityScore;
  int? _customerFocusScore;
  int? _innovationScore;

  bool _isLoading = false;
  bool _isLoadingAverage = false;
  TeamAverageModel? _teamAverage;

  @override
  void initState() {
    super.initState();
    _fetchTeamAverage();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeamAverage() async {
    setState(() {
      _isLoadingAverage = true;
    });
    try {
      final avg = await _apiClient.getTeamAverage(widget.managerId);
      setState(() {
        _teamAverage = avg;
      });
    } catch (_) {
      // Fail silently, fallbacks are handled
    } finally {
      setState(() {
        _isLoadingAverage = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_performanceRating == null || _potentialRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both ratings'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_communicationScore == null ||
        _technicalSkillScore == null ||
        _problemSolvingScore == null ||
        _leadershipScore == null ||
        _teamworkScore == null ||
        _adaptabilityScore == null ||
        _customerFocusScore == null ||
        _innovationScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please evaluate all competency areas'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiClient.submitEvaluation(
        employeeId: widget.employeeId,
        managerId: widget.managerId,
        reviewCycleId: widget.reviewCycleId,
        performanceRating: _performanceRating!,
        potentialRating: _potentialRating!,
        managerComments: _commentsController.text.trim(),
        communicationScore: _communicationScore!,
        technicalSkillScore: _technicalSkillScore!,
        problemSolvingScore: _problemSolvingScore!,
        leadershipScore: _leadershipScore!,
        teamworkScore: _teamworkScore!,
        adaptabilityScore: _adaptabilityScore!,
        customerFocusScore: _customerFocusScore!,
        innovationScore: _innovationScore!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluation Submitted Successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger list refresh
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Evaluation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            final formWidget = Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Read Only Target Employee Info Card
                  Card(
                    elevation: 1,
                    color: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EVALUATION TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            widget.employeeName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 4),
                          Text('Department: ${widget.department}', style: const TextStyle(fontSize: 14, color: AppTheme.subtitleColor)),
                          const Divider(height: 24),
                          const Text('ACTIVE REVIEW CYCLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            widget.reviewCycleTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Performance Rating Dropdown
                  DropdownButtonFormField<int>(
                    value: _performanceRating,
                    decoration: InputDecoration(
                      labelText: 'Performance Rating *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.star_outline_rounded),
                    ),
                    items: List.generate(5, (index) {
                      final val = index + 1;
                      return DropdownMenuItem(
                        value: val,
                        child: Text('$val - ${_getRatingDescription(val)}'),
                      );
                    }),
                    validator: (val) => val == null ? 'Performance rating is required' : null,
                    onChanged: (val) {
                      setState(() {
                        _performanceRating = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Potential Rating Dropdown
                  DropdownButtonFormField<int>(
                    value: _potentialRating,
                    decoration: InputDecoration(
                      labelText: 'Potential Rating *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.trending_up_rounded),
                    ),
                    items: List.generate(5, (index) {
                      final val = index + 1;
                      return DropdownMenuItem(
                        value: val,
                        child: Text('$val - ${_getPotentialDescription(val)}'),
                      );
                    }),
                    validator: (val) => val == null ? 'Potential rating is required' : null,
                    onChanged: (val) {
                      setState(() {
                        _potentialRating = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Competency Score Metrics (1-5)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildCompetencyDropdown('Communication *', _communicationScore, (val) {
                    setState(() { _communicationScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Technical Skills *', _technicalSkillScore, (val) {
                    setState(() { _technicalSkillScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Problem Solving *', _problemSolvingScore, (val) {
                    setState(() { _problemSolvingScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Leadership *', _leadershipScore, (val) {
                    setState(() { _leadershipScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Teamwork *', _teamworkScore, (val) {
                    setState(() { _teamworkScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Adaptability *', _adaptabilityScore, (val) {
                    setState(() { _adaptabilityScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Customer Focus *', _customerFocusScore, (val) {
                    setState(() { _customerFocusScore = val; });
                  }),
                  const SizedBox(height: 16),
                  _buildCompetencyDropdown('Innovation *', _innovationScore, (val) {
                    setState(() { _innovationScore = val; });
                  }),
                  const SizedBox(height: 24),

                  // Manager Comments Multiline field
                  TextFormField(
                    controller: _commentsController,
                    decoration: InputDecoration(
                      labelText: 'Manager Comments *',
                      alignLabelWithHint: true,
                      hintText: 'Enter qualitative feedback regarding performance...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48.0),
                        child: Icon(Icons.comment_outlined),
                      ),
                    ),
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Manager comments are required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Evaluation',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            );

            final comparisonPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Live Team Comparison Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                _isLoadingAverage
                    ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
                    : Column(
                        children: [
                          _buildComparisonBar(
                            'Performance Rating',
                            (_performanceRating ?? 0).toDouble(),
                            _teamAverage?.averagePerformance ?? 0.0,
                          ),
                          const SizedBox(height: 16),
                          _buildComparisonBar(
                            'Potential Rating',
                            (_potentialRating ?? 0).toDouble(),
                            _teamAverage?.averagePotential ?? 0.0,
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 1,
                            color: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.people_outline, color: AppTheme.primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your Team: ${_teamAverage?.numberOfEmployeesEvaluated ?? 0} employees evaluated.',
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: formWidget,
                    ),
                  ),
                  const VerticalDivider(width: 32),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: comparisonPanel,
                    ),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    formWidget,
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 20),
                    comparisonPanel,
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompetencyDropdown(String label, int? currentValue, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: List.generate(5, (index) {
        final val = index + 1;
        return DropdownMenuItem(
          value: val,
          child: Text('$val - ${_getCompetencyLevelDesc(val)}'),
        );
      }),
      validator: (val) => val == null ? '$label is required' : null,
      onChanged: onChanged,
    );
  }

  String _getCompetencyLevelDesc(int score) {
    switch (score) {
      case 1: return 'Novice / Developing';
      case 2: return 'Basic Application';
      case 3: return 'Proficient / Meets Expectations';
      case 4: return 'Advanced Application';
      case 5: return 'Expert / Role Model';
      default: return '';
    }
  }

  Widget _buildComparisonBar(String title, double current, double average) {
    final double maxScore = 5.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 100, child: Text('Current Rating', style: TextStyle(fontSize: 12, color: Colors.black87))),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final targetWidth = constraints.maxWidth * (current / maxScore);
                      return Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            width: targetWidth.clamp(0.0, constraints.maxWidth - 30),
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.accentColor, AppTheme.accentColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            current > 0 ? current.toStringAsFixed(1) : 'N/A',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 100, child: Text('Team Average', style: TextStyle(fontSize: 12, color: Colors.black87))),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final targetWidth = constraints.maxWidth * (average / maxScore);
                      return Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            width: targetWidth.clamp(0.0, constraints.maxWidth - 30),
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            average.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1: return 'Unsatisfactory';
      case 2: return 'Needs Improvement';
      case 3: return 'Meets Expectations';
      case 4: return 'Exceeds Expectations';
      case 5: return 'Outstanding';
      default: return '';
    }
  }

  String _getPotentialDescription(int potential) {
    switch (potential) {
      case 1: return 'Low Potential';
      case 2: return 'Medium-Low Potential';
      case 3: return 'Medium Potential';
      case 4: return 'High Potential';
      case 5: return 'High Potential / Fast Track';
      default: return '';
    }
  }
}
