import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/user_model.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  final List<UserModel> managers;

  const EditUserScreen({
    super.key,
    required this.user,
    required this.managers,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late String _selectedDept;
  int? _selectedManagerId;
  late bool _isEnabled;
  bool _isLoading = false;

  final List<String> _departments = [
    'Executive Office', 
    'Engineering Management', 
    'Engineering', 
    'Quality Assurance', 
    'Human Resources', 
    'Sales'
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _selectedDept = widget.user.department ?? 'Engineering';
    _selectedManagerId = widget.user.managerId;
    _isEnabled = widget.user.enabled ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Update basic profile info (first name, last name, department)
      await _apiClient.updateUser(
        widget.user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        department: _selectedDept,
      );

      // 2. Update supervisor if employee and supervisor assignment changed
      if (widget.user.role == 'EMPLOYEE' && _selectedManagerId != widget.user.managerId) {
        await _apiClient.assignUserManager(widget.user.id, _selectedManagerId);
      }

      // 3. Update account status if it changed
      final bool statusChanged = _isEnabled != (widget.user.enabled ?? true);
      if (statusChanged) {
        if (_isEnabled) {
          await _apiClient.activateUser(widget.user.id);
        } else {
          await _apiClient.deactivateUser(widget.user.id);
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (widget.user.firstName.isNotEmpty ? widget.user.firstName[0] : '') + 
                     (widget.user.lastName.isNotEmpty ? widget.user.lastName[0] : '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar & Static Info Area
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.primaryColor,
                            child: Text(
                              initials.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.user.email,
                                  style: const TextStyle(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        widget.user.role,
                                        style: const TextStyle(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.bold, 
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Email and Role cannot be modified',
                                      style: TextStyle(color: Colors.black54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 36),

                      // First & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Department Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDept,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _departments.map((d) {
                          return DropdownMenuItem(value: d, child: Text(d));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() { _selectedDept = val; });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Supervisor Manager Dropdown (Only for Employees)
                      if (widget.user.role == 'EMPLOYEE') ...[
                        DropdownButtonFormField<int>(
                          value: _selectedManagerId,
                          decoration: InputDecoration(
                            labelText: 'Supervisor (Manager)',
                            prefixIcon: const Icon(Icons.supervised_user_circle_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: widget.managers.map((mgr) {
                            return DropdownMenuItem<int>(
                              value: mgr.id,
                              child: Text('${mgr.firstName} ${mgr.lastName} (${mgr.department ?? "N/A"})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() { _selectedManagerId = val; });
                          },
                          validator: (v) => v == null ? 'Employees must have a designated manager' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Account Status Switch
                      Card(
                        color: _isEnabled ? Colors.green.shade50.withValues(alpha: 0.2) : Colors.red.shade50.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _isEnabled ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SwitchListTile(
                            value: _isEnabled,
                            activeColor: Colors.green,
                            inactiveTrackColor: Colors.red.shade100,
                            inactiveThumbColor: Colors.red,
                            title: Text(
                              _isEnabled ? 'Account is Active' : 'Account is Disabled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isEnabled ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                            subtitle: const Text(
                              'Disabled users are immediately locked out and blocked from logging into the portal.',
                              style: TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            onChanged: (val) {
                              setState(() { _isEnabled = val; });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                                : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
