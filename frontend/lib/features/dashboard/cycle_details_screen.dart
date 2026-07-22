import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/review_cycle_details_model.dart';
import '../models/user_model.dart';

class CycleDetailsScreen extends StatefulWidget {
  final int cycleId;
  final String userRole; // 'CEO' or 'MANAGER'
  final List<UserModel> managers;

  const CycleDetailsScreen({
    super.key,
    required this.cycleId,
    required this.userRole,
    required this.managers,
  });

  @override
  State<CycleDetailsScreen> createState() => _CycleDetailsScreenState();
}

class _CycleDetailsScreenState extends State<CycleDetailsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  ReviewCycleDetailsModel? _details;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _apiClient.getReviewCycleDetails(widget.cycleId);
      setState(() {
        _details = data;
      });
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditCycleDialog() {
    if (_details == null) return;

    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: _details!.title);
    final descController = TextEditingController(text: _details!.description ?? '');
    DateTime? startDate = DateTime.tryParse(_details!.startDate);
    DateTime? endDate = DateTime.tryParse(_details!.endDate);
    String status = _details!.status;
    UserModel? selectedManager = widget.managers.cast<UserModel?>().firstWhere(
      (m) => m?.id == _details!.managerId,
      orElse: () => null,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
                initialDate: endDate ?? startDate ?? DateTime.now(),
                firstDate: startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) {
                setDialogState(() {
                  endDate = picked;
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Review Cycle', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const SizedBox(height: 16),
                        // Searchable Manager Picker
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Assign Manager *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.subtitleColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SearchableManagerPicker(
                          managers: widget.managers,
                          selectedManager: selectedManager,
                          onSelected: (mgr) {
                            setDialogState(() {
                              selectedManager = mgr;
                            });
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
                    if (selectedManager == null) {
                      _showErrorSnackBar('Please select an assigned manager');
                      return;
                    }

                    Navigator.pop(context); // Close dialog

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      await _apiClient.updateReviewCycle(
                        _details!.id,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
                        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
                        status: status,
                        managerId: selectedManager!.id,
                      );
                      _showSuccessSnackBar('Review Cycle Updated Successfully');
                      _fetchDetails();
                    } catch (e) {
                      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCEO = widget.userRole == 'CEO';
    final details = _details;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          details != null ? details.title : 'Cycle Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (isCEO && details != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _showEditCycleDialog,
              tooltip: 'Edit Cycle',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _fetchDetails,
            tooltip: 'Refresh details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : details == null
              ? const Center(child: Text('Failed to load review cycle details'))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(details),
                        const SizedBox(height: 16),
                        _buildProgressDashboard(details),
                        const SizedBox(height: 24),
                        const Text(
                          'Participating Employees Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 12),
                        _buildEmployeesList(details),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(ReviewCycleDetailsModel details) {
    final isActive = details.status == 'ACTIVE';
    final isCompleted = details.status == 'COMPLETED';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    details.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFDCFCE7)
                        : isCompleted
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    details.status,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF15803D)
                          : isCompleted
                              ? const Color(0xFF1D4ED8)
                              : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (details.description != null && details.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details.description!,
                style: const TextStyle(fontSize: 14, color: AppTheme.subtitleColor),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow(
                    'Start Date',
                    _formatDate(details.startDate),
                    Icons.calendar_month_outlined,
                  ),
                ),
                Expanded(
                  child: _buildDetailRow(
                    'End Date',
                    _formatDate(details.endDate),
                    Icons.calendar_month_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Responsible Overseer Manager',
              details.managerName ?? 'Unassigned',
              Icons.assignment_ind_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDashboard(ReviewCycleDetailsModel details) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle Metrics Dashboard',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 76,
                            width: 76,
                            child: CircularProgressIndicator(
                              value: details.completionPercentage / 100,
                              strokeWidth: 7,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                            ),
                          ),
                          Text(
                            '${details.completionPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completion',
                        style: TextStyle(fontSize: 12, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              'Total Employees',
                              '${details.totalEmployees}',
                              Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              'Completed Reviews',
                              '${details.reviewsCompleted}',
                              Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              'Reviews Pending',
                              '${details.reviewsPending}',
                              Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              'Self Assess Pending',
                              '${details.selfAssessmentsPending}',
                              Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.subtitleColor, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList(ReviewCycleDetailsModel details) {
    if (details.employees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No employees participating in this cycle.',
                style: TextStyle(color: AppTheme.subtitleColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.employees.length,
      itemBuilder: (context, index) {
        final emp = details.employees[index];
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
              child: Text(
                '${emp.firstName[0]}${emp.lastName[0]}',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${emp.firstName} ${emp.lastName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${emp.email} • ${emp.department ?? "N/A"}',
              style: const TextStyle(fontSize: 11, color: AppTheme.subtitleColor),
            ),
            trailing: _buildStatusBadge(emp.reviewStatus),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = Colors.grey.shade700;

    switch (status) {
      case 'Completed':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      case 'Manager Review Pending':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        break;
      case 'Self Assessment Completed':
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF1D4ED8);
        break;
      case 'Not Started':
        bg = const Color(0xFFF1F5F9);
        text = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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
}

class SearchableManagerPicker extends StatefulWidget {
  final List<UserModel> managers;
  final UserModel? selectedManager;
  final ValueChanged<UserModel?> onSelected;

  const SearchableManagerPicker({
    super.key,
    required this.managers,
    required this.selectedManager,
    required this.onSelected,
  });

  @override
  State<SearchableManagerPicker> createState() => _SearchableManagerPickerState();
}

class _SearchableManagerPickerState extends State<SearchableManagerPicker> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    final modalFiltered = widget.managers.where((m) {
                      final name = '${m.firstName} ${m.lastName}'.toLowerCase();
                      final email = m.email.toLowerCase();
                      final dept = (m.department ?? '').toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return name.contains(query) || email.contains(query) || dept.contains(query);
                    }).toList();

                    return AlertDialog(
                      title: const Text('Select Responsible Manager'),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 350,
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: 'Search Manager',
                                prefixIcon: Icon(Icons.search),
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  _searchQuery = val;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: modalFiltered.isEmpty
                                  ? const Center(child: Text('No managers match search'))
                                  : ListView.builder(
                                      itemCount: modalFiltered.length,
                                      itemBuilder: (context, idx) {
                                        final mgr = modalFiltered[idx];
                                        final isSelected = widget.selectedManager?.id == mgr.id;
                                        return ListTile(
                                          title: Text('${mgr.firstName} ${mgr.lastName}'),
                                          subtitle: Text('${mgr.email} • ${mgr.department ?? "N/A"}'),
                                          trailing: isSelected
                                              ? const Icon(Icons.check, color: AppTheme.accentColor)
                                              : null,
                                          onTap: () {
                                            widget.onSelected(mgr);
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            widget.onSelected(null);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear Selection'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedManager != null
                        ? '${widget.selectedManager!.firstName} ${widget.selectedManager!.lastName} (${widget.selectedManager!.department ?? "N/A"})'
                        : 'Select Manager *',
                    style: TextStyle(
                      color: widget.selectedManager != null ? Colors.black87 : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
