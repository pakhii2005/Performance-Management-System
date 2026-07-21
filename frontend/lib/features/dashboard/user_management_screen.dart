import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import 'create_user_screen.dart';
import 'edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _users = [];
  List<UserModel> _managers = [];
  bool _isLoading = false;

  // Filter States
  String? _selectedRole;
  String? _selectedDept;
  bool? _selectedStatus; // true = Active, false = Inactive, null = All

  final List<String> _roles = ['CEO', 'MANAGER', 'EMPLOYEE'];
  final List<String> _departments = ['Executive Office', 'Engineering Management', 'Engineering', 'Quality Assurance', 'Human Resources', 'Sales'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadManagers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; });
    try {
      final list = await _apiClient.getUsers(
        search: _searchController.text,
        role: _selectedRole,
        department: _selectedDept,
        enabled: _selectedStatus,
      );
      setState(() { _users = list; });
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadManagers() async {
    try {
      final list = await _apiClient.getManagers();
      setState(() { _managers = list; });
    } catch (_) {
      // Suppress secondary load errors
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final bool currentlyEnabled = user.enabled ?? true;
    final String actionText = currentlyEnabled ? 'Deactivate' : 'Activate';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Account?'),
        content: Text('Are you sure you want to $actionText the account for ${user.firstName} ${user.lastName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentlyEnabled ? Colors.red : AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _isLoading = true; });
    try {
      if (currentlyEnabled) {
        await _apiClient.deactivateUser(user.id);
        _showSnackBar('${user.firstName}\x27s account is now deactivated.');
      } else {
        await _apiClient.activateUser(user.id);
        _showSnackBar('${user.firstName}\x27s account is now activated.');
      }
      _loadUsers();
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _resetPassword(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset User Password?'),
        content: Text('This will generate a temporary password for ${user.firstName} ${user.lastName}. The user will be required to change it on next login.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate Temp Password'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _isLoading = true; });
    try {
      final tempPassword = await _apiClient.resetUserPassword(user.id);
      setState(() { _isLoading = false; });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.vpn_key_rounded, color: Colors.green),
                SizedBox(width: 12),
                Text('Password Reset Completed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A secure temporary password has been generated:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    tempPassword,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please share this password with the user. They will be forced to change it upon logging in.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
      _loadUsers();
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() { _isLoading = false; });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = null;
      _selectedDept = null;
      _selectedStatus = null;
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadUsers();
              _loadManagers();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateUserScreen(managers: _managers)),
          );
          if (result == true) {
            _showSnackBar('User created successfully.');
            _loadUsers();
            _loadManagers();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filters Section
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _loadUsers(),
                            decoration: InputDecoration(
                              labelText: 'Search Users',
                              hintText: 'Enter name or email...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _loadUsers();
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Selectors Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Role Filter
                            SizedBox(
                              width: isMobile ? double.infinity : 150,
                              child: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Role', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                                  ..._roles.map((r) => DropdownMenuItem(value: r, child: Text(r))),
                                ],
                                onChanged: (val) {
                                  setState(() { _selectedRole = val; });
                                  _loadUsers();
                                },
                              ),
                            ),
                            
                            // Department Filter
                            SizedBox(
                              width: isMobile ? double.infinity : 180,
                              child: DropdownButtonFormField<String>(
                                value: _selectedDept,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Department', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Departments')),
                                  ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                                ],
                                onChanged: (val) {
                                  setState(() { _selectedDept = val; });
                                  _loadUsers();
                                },
                              ),
                            ),

                            // Status Filter
                            SizedBox(
                              width: isMobile ? double.infinity : 150,
                              child: DropdownButtonFormField<bool?>(
                                value: _selectedStatus,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                                  DropdownMenuItem(value: true, child: Text('Active Only')),
                                  DropdownMenuItem(value: false, child: Text('Inactive Only')),
                                ],
                                onChanged: (val) {
                                  setState(() { _selectedStatus = val; });
                                  _loadUsers();
                                },
                              ),
                            ),
                            
                            // Reset Filter Button
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.filter_list_off_rounded),
                              label: const Text('Reset Filters'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Directory List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? const Center(child: Text('No users matching current search/filters found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _users.size,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isEnabled = user.enabled ?? true;
                            
                            Color roleColor = Colors.grey;
                            if (user.role == 'CEO') roleColor = Colors.purple;
                            else if (user.role == 'MANAGER') roleColor = Colors.blue.shade700;
                            else if (user.role == 'EMPLOYEE') roleColor = Colors.green.shade700;

                            final initials = (user.firstName.isNotEmpty ? user.firstName[0] : '') + 
                                             (user.lastName.isNotEmpty ? user.lastName[0] : '');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isEnabled ? Colors.grey.shade200 : Colors.red.shade100,
                                  width: 1,
                                ),
                              ),
                              color: isEnabled ? Colors.white : Colors.red.shade50.withValues(alpha: 0.3),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: roleColor.withValues(alpha: 0.1),
                                  foregroundColor: roleColor,
                                  child: Text(initials.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${user.firstName} ${user.lastName}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isEnabled ? Colors.black87 : Colors.black45,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isEnabled ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isEnabled ? Colors.green.shade200 : Colors.red.shade200),
                                      ),
                                      child: Text(
                                        isEnabled ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isEnabled ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(user.email, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Role Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user.role,
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: roleColor),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Department Label
                                        if (user.department != null)
                                          Text(
                                            user.department!,
                                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                          ),
                                      ],
                                    ),
                                    if (user.role == 'EMPLOYEE' && user.managerName != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Supervisor: ${user.managerName}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: user.role == 'CEO'
                                    ? null // Cannot deactivate or reset CEO credentials from directory
                                    : PopupMenuButton<String>(
                                        onSelected: (action) async {
                                          if (action == 'edit') {
                                            final updated = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditUserScreen(user: user, managers: _managers),
                                              ),
                                            );
                                            if (updated == true) {
                                              _showSnackBar('User information updated.');
                                              _loadUsers();
                                              _loadManagers();
                                            }
                                          } else if (action == 'status') {
                                            _toggleUserStatus(user);
                                          } else if (action == 'reset_pw') {
                                            _resetPassword(user);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit_outlined),
                                              title: Text('Edit Profile'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'status',
                                            child: ListTile(
                                              leading: Icon(isEnabled ? Icons.block_flipped : Icons.check_circle_outline),
                                              title: Text(isEnabled ? 'Deactivate' : 'Activate'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'reset_pw',
                                            child: ListTile(
                                              leading: Icon(Icons.lock_reset_outlined),
                                              title: Text('Reset Password'),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

extension SafeListAccess on List {
  int get size => length;
}
