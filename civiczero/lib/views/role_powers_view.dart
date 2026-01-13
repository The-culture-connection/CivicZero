import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/member_model.dart';
import 'package:civiczero/services/role_service.dart';
import 'package:civiczero/utils/string_extensions.dart';

class RolePowersView extends StatefulWidget {
  final GovernmentModel government;
  final MemberModel? member; // null if visitor

  const RolePowersView({super.key, required this.government, this.member});

  @override
  State<RolePowersView> createState() => _RolePowersViewState();
}

class _RolePowersViewState extends State<RolePowersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Powers'),
        backgroundColor: AppColors.primaryDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryLight,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'My Access'),
            Tab(text: 'All Roles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyAccessTab(),
          _buildAllRolesTab(),
        ],
      ),
    );
  }

  Widget _buildMyAccessTab() {
    if (widget.member == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_accounts, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'You are a Visitor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text('Join this government to gain access'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.login),
              label: const Text('Go Back to Join'),
            ),
          ],
        ),
      );
    }

    final actions = [
      {'key': 'fork', 'label': 'Fork Government', 'icon': Icons.call_split},
      {'key': 'propose_events', 'label': 'Propose Events', 'icon': Icons.event},
      {'key': 'propose_laws', 'label': 'Propose Laws', 'icon': Icons.gavel},
      {'key': 'vote', 'label': 'Vote on Proposals', 'icon': Icons.how_to_vote},
      {'key': 'initiate_simulations', 'label': 'Run Simulations', 'icon': Icons.analytics},
      {'key': 'be_elected', 'label': 'Run for Office', 'icon': Icons.campaign},
      {'key': 'edit_docs_draft', 'label': 'Draft Documents', 'icon': Icons.edit_note},
      {'key': 'edit_docs_direct', 'label': 'Edit Documents Directly', 'icon': Icons.edit},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status Summary
        Card(
          color: AppColors.primaryDark,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Current Roles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.member!.roles.map((role) => Chip(
                    label: Text(role.capitalize()),
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'What You Can Do',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) {
          final canDo = _roleService.canPerform(
            member: widget.member,
            government: widget.government,
            action: action['key'] as String,
          );
          return _buildAccessCard(
            label: action['label'] as String,
            icon: action['icon'] as IconData,
            canDo: canDo,
            requirement: canDo ? null : _getRequirement(action['key'] as String),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAllRolesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'All Roles in This Government',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Understanding the role system and transition paths',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...widget.government.enabledRoles.map((role) {
          final isEnabled = true;
          final powers = widget.government.rolePowers[role];
          final transition = widget.government.roleTransitions[role];
          final duration = widget.government.roleDurations[role];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: Icon(
                _getRoleIcon(role),
                color: AppColors.primaryDark,
              ),
              title: Text(
                role.capitalize(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_roleService.getRoleDescription(role)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (powers != null) ...[
                        const Text('Powers:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._formatPowersList(powers).map((p) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p)),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 12),
                      ],
                      if (transition != null) ...[
                        const Text('How to Gain:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${(transition['method'] as String? ?? 'automatic').replaceAll('_', ' ').capitalize()}'),
                        const SizedBox(height: 12),
                      ],
                      if (duration != null) ...[
                        const Text('Duration:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(duration.replaceAll('_', ' ').capitalize()),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        // Show disabled roles (greyed out)
        const SizedBox(height: 24),
        const Text(
          'Disabled Roles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ...['visitor', 'member', 'contributor', 'voter', 'representative', 'moderator', 'founder']
            .where((r) => !widget.government.enabledRoles.contains(r))
            .map((role) => Card(
              color: Colors.grey[200],
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_getRoleIcon(role), color: Colors.grey),
                title: Text(
                  role.capitalize(),
                  style: const TextStyle(color: Colors.grey),
                ),
                subtitle: const Text('Not active in this government', style: TextStyle(fontSize: 12)),
              ),
            )).toList(),
      ],
    );
  }

  Widget _buildAccessCard({
    required String label,
    required IconData icon,
    required bool canDo,
    String? requirement,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: canDo ? Colors.green.shade50 : Colors.grey.shade100,
      child: ListTile(
        leading: Icon(
          icon,
          color: canDo ? Colors.green : Colors.grey,
        ),
        title: Text(label),
        trailing: canDo
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock, color: Colors.grey),
        subtitle: requirement != null
            ? Text(
                requirement,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              )
            : null,
        onTap: !canDo && requirement != null
            ? () => _showRequirementExplainer(label, requirement)
            : null,
      ),
    );
  }

  String _getRequirement(String action) {
    // Determine what's needed for this action
    if (widget.member == null) return 'Must join government';
    
    for (final role in widget.government.enabledRoles) {
      final powers = widget.government.rolePowers[role];
      if (powers == null) continue;
      
      bool hasPermission = false;
      switch (action) {
        case 'fork':
          hasPermission = powers['fork'] == true;
          break;
        case 'propose_events':
          hasPermission = powers['proposeEvents'] == true;
          break;
        case 'propose_laws':
          hasPermission = powers['proposeLaws'] == true;
          break;
        case 'vote':
          hasPermission = powers['vote'] == true;
          break;
        case 'initiate_simulations':
          hasPermission = powers['initiateSimulations'] == true;
          break;
        case 'be_elected':
          hasPermission = powers['beElected'] == true;
          break;
        case 'edit_docs_draft':
          hasPermission = powers['editDocs'] == 'draft' || powers['editDocs'] == 'direct';
          break;
        case 'edit_docs_direct':
          hasPermission = powers['editDocs'] == 'direct';
          break;
      }
      
      if (hasPermission) {
        if (widget.member!.roles.contains(role)) {
          return ''; // Has the role but something else is blocking
        }
        return 'Requires $role role';
      }
    }
    
    return 'Not available in this government';
  }

  void _showRequirementExplainer(String action, String requirement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(child: Text('Action Locked')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You cannot: $action',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Why:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(requirement),
            const SizedBox(height: 16),
            const Text('What to do:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Check role requirements'),
            const Text('• View "All Roles" tab'),
            const Text('• Join the government if you\'re a visitor'),
            if (requirement.contains('role'))
              const Text('• Check how to gain required role'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(1); // Switch to All Roles tab
            },
            child: const Text('View All Roles'),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    final icons = {
      'visitor': Icons.visibility,
      'member': Icons.person,
      'contributor': Icons.create,
      'voter': Icons.how_to_vote,
      'representative': Icons.account_balance,
      'moderator': Icons.admin_panel_settings,
      'founder': Icons.star,
    };
    return icons[role] ?? Icons.person_outline;
  }

  List<String> _formatPowersList(Map<String, dynamic> powers) {
    final list = <String>[];
    if (powers['fork'] == true) list.add('Fork Government');
    if (powers['proposeEvents'] == true) list.add('Propose Events');
    if (powers['proposeLaws'] == true) list.add('Propose Laws');
    if (powers['vote'] == true) list.add('Vote');
    if (powers['initiateSimulations'] == true) list.add('Initiate Simulations');
    if (powers['beElected'] == true) list.add('Be Elected');
    if (powers['editDocs'] == 'draft') list.add('Draft Documents');
    if (powers['editDocs'] == 'direct') list.add('Edit Documents Directly');
    return list;
  }
}
