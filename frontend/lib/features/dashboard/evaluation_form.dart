import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

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
  bool _isLoading = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
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
              ),
            ),
          ),
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
