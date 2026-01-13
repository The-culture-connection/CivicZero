import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/member_model.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/services/role_service.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/utils/string_extensions.dart';
import 'package:civiczero/views/proposals_view.dart';
import 'package:civiczero/views/role_powers_view.dart';
import 'package:civiczero/views/propose_amendment_view.dart';
import 'package:civiczero/views/law_wizard_view.dart';
import 'package:civiczero/views/event_wizard_view.dart';
import 'package:civiczero/views/fork_wizard_view.dart';
import 'package:civiczero/views/simulation_launch_view.dart';
import 'package:civiczero/views/proposal_detail_view.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/constants/proposal_constants.dart';

class GovernmentDetailView extends StatefulWidget {
  final GovernmentModel government;

  const GovernmentDetailView({super.key, required this.government});

  @override
  State<GovernmentDetailView> createState() => _GovernmentDetailViewState();
}

class _GovernmentDetailViewState extends State<GovernmentDetailView> {
  final GovernmentService _governmentService = GovernmentService();
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  final ProposalService _proposalService = ProposalService();
  
  bool _isMember = false;
  bool _isLoading = false;
  MemberModel? _currentMember;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      // Get member data by UID (AUTHORITY)
      final member = await _governmentService.getMember(widget.government.id, uid);
      setState(() {
        _currentMember = member;
        _isMember = member != null && member.status == 'active';
      });
    }
  }

  Future<void> _toggleMembership() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isMember) {
        // Leave using UID (AUTHORITY)
        await _governmentService.leaveGovernment(widget.government.id, uid);
        setState(() {
          _isMember = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left government')),
          );
        }
      } else {
        // Join using UID + username (UID for authority, username for display)
        final userData = await _authService.getUserData(uid);
        final username = userData?.username ?? 'Unknown';
        
        await _governmentService.joinGovernment(
          governmentId: widget.government.id,
          uid: uid, // UID = AUTHORITY
          username: username, // Username = DISPLAY
        );
        
        setState(() {
          _isMember = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined government!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gov = widget.government;

    return Scaffold(
      appBar: AppBar(
        title: Text(gov.name),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Actions',
            onPressed: () => _showActionsSheet(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with Preamble
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryDark.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gov.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${gov.scope.toUpperCase()} GOVERNMENT',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${gov.memberCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PREAMBLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    gov.preambleText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            // Your Status Card (if member)
            if (_currentMember != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RolePowersView(
                            government: gov,
                            member: _currentMember,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: AppColors.primaryDark),
                              const SizedBox(width: 8),
                              const Text(
                                'Your Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Roles: ${_currentMember!.roles.map((r) => r.capitalize()).join(', ')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _buildQuickPermission('Vote', _roleService.canPerform(member: _currentMember, government: gov, action: 'vote')),
                              _buildQuickPermission('Propose Laws', _roleService.canPerform(member: _currentMember, government: gov, action: 'propose_laws')),
                              _buildQuickPermission('Propose Events', _roleService.canPerform(member: _currentMember, government: gov, action: 'propose_events')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Pending Actions Section (Real-time)
            StreamBuilder<List<ProposalModel>>(
              stream: _proposalService.getProposals(gov.id),
              builder: (context, snapshot) {
                final allProposals = snapshot.data ?? [];
                final pendingProposals = allProposals.where((p) => 
                  ProposalStatus.activeStatuses.contains(p.status) || 
                  ProposalStatus.pendingExecutionStatuses.contains(p.status)
                ).toList();

                if (pendingProposals.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.pending_actions, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pending Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${pendingProposals.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...pendingProposals.take(3).map((proposal) => 
                            _buildPendingActionCard(proposal)
                          ).toList(),
                          if (pendingProposals.length > 3) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProposalsView(government: gov),
                                  ),
                                );
                              },
                              child: Text('View all ${pendingProposals.length} proposals'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Sections
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (gov.blueprintSeed != null) ...[
                    _buildSection('Blueprint', [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance, color: AppColors.primaryDark),
                            const SizedBox(width: 12),
                            Text(
                              'Based on: ${gov.blueprintSeed!.replaceAll('_', ' ').capitalize()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Budget Allocation', [
                    const Text(
                      'Resource priorities across key areas:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ...gov.budgetWeights.entries.map((e) => _buildBudgetBar(e.key, e.value)).toList(),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Purpose & Principles', [
                    _buildInfoRow('Primary Purposes', gov.purpose.join(', ')),
                    const SizedBox(height: 16),
                    const Text(
                      'Guiding Principles:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...gov.principles.entries.map((e) => 
                      _buildProgressRow(e.key.replaceAll('_', ' ').capitalize(), e.value)
                    ).toList(),
                  ], editTarget: 'purpose_principles'),
                  const SizedBox(height: 16),
                  _buildSection('Rights & Obligations', [
                    _buildInfoRow('Recognized Rights', gov.rightsCategories.join(', ')),
                    _buildInfoRow('Rights Can Be Limited By', gov.rightsLimits.join(', ')),
                    _buildInfoRow('Citizen Obligations', gov.citizenObligations.join(', ')),
                  ], editTarget: 'rights'),
                  const SizedBox(height: 16),
                  _buildSection('Government Structure', [
                    _buildInfoRow('Branches', gov.branches.join(', ')),
                    _buildInfoRow('Checks & Balances', gov.checksAndBalances.replaceAll('_', ' ').capitalize()),
                  ], editTarget: 'structure'),
                  const SizedBox(height: 16),
                  _buildSection('Role System', [
                    const Text('Enabled Roles:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: gov.enabledRoles.map((role) => Chip(
                        label: Text(role.capitalize()),
                        backgroundColor: AppColors.primaryDark.withOpacity(0.1),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Role Powers:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...gov.rolePowers.entries.where((e) => gov.enabledRoles.contains(e.key)).map((entry) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key.capitalize(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_formatRolePowers(entry.value), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    )).toList(),
                  ], editTarget: 'role_system'),
                  const SizedBox(height: 16),
                  _buildSection('Lawmaking Procedures', [
                    const Text('Proposal Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...gov.proposalTypes.map((type) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.replaceAll('_', ' ').capitalize(), 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 8),
                            if (gov.lawmakingSOP[type] != null) ...[
                              Text('Debate: ${(gov.lawmakingSOP[type]!['debateRequired'] as String? ?? 'optional').replaceAll('_', ' ')}',
                                  style: const TextStyle(fontSize: 13)),
                              Text('Format: ${(gov.lawmakingSOP[type]!['debateFormat'] as String? ?? 'open').replaceAll('_', ' ')}',
                                  style: const TextStyle(fontSize: 13)),
                              Text('Voting Body: ${(gov.lawmakingSOP[type]!['votingBody'] as String? ?? 'voters').replaceAll('_', ' ')}',
                                  style: const TextStyle(fontSize: 13)),
                              Text('Threshold: ${(gov.lawmakingSOP[type]!['threshold'] as String? ?? 'majority').replaceAll('_', ' ')}',
                                  style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Timing: ${_formatLatency(gov.lawmakingSOP[type]!['debateLatency'] as String? ?? 'medium')} debate, '
                                    '${_formatLatency(gov.lawmakingSOP[type]!['votingLatency'] as String? ?? 'medium')} vote, '
                                    '${_formatLatency(gov.lawmakingSOP[type]!['executionLatency'] as String? ?? 'medium')} execution',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    )).toList(),
                  ]),
                  const SizedBox(height: 16),
                  if (gov.forkRules.isNotEmpty && gov.forkRules.values.any((v) => v == true)) ...[
                    _buildSection('Fork Rules', [
                      ...gov.forkRules.entries.where((e) => e.value == true).map((entry) => Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(entry.key.replaceAll('_', ' ').capitalize(), style: const TextStyle(fontSize: 14)),
                        ],
                      )).toList(),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  if (gov.simulationTriggers.isNotEmpty && gov.simulationTriggers.values.any((v) => v == true)) ...[
                    _buildSection('Simulation Triggers', [
                      ...gov.simulationTriggers.entries.where((e) => e.value == true).map((entry) => Row(
                        children: [
                          const Icon(Icons.analytics, size: 16, color: AppColors.primaryDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(entry.key.replaceAll('_', ' ').capitalize(), style: const TextStyle(fontSize: 14)),
                          ),
                        ],
                      )).toList(),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Enforcement & Consequences', [
                    _buildInfoRow('Enforcement Authority', gov.enforcementAuthority.replaceAll('_', ' ').capitalize()),
                    _buildInfoRow('Consequence Types', gov.consequenceTypes.join(', ')),
                    _buildInfoRow('Enforcement Discretion', gov.enforcementDiscretion.replaceAll('_', ' ').capitalize()),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Change & Evolution', [
                    _buildInfoRow('Amendment Difficulty', gov.amendmentDifficulty.capitalize()),
                    _buildInfoRow('Change Triggers', gov.changeTriggers.join(', ')),
                  ]),
                  const SizedBox(height: 16),
                  if (gov.customInstitutions.isNotEmpty) ...[
                    _buildSection('Custom Institutions', [
                      ...gov.customInstitutions.map((inst) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.account_balance, color: AppColors.primaryDark, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      inst['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Type: ${(inst['type'] as String).replaceAll('_', ' ').capitalize()}',
                                  style: const TextStyle(fontSize: 13)),
                              Text('Powers: ${(inst['powers'] as List).map((p) => (p as String).replaceAll('_', ' ')).join(', ')}',
                                  style: const TextStyle(fontSize: 13)),
                              Text('Selection: ${(inst['selection'] as String).capitalize()}',
                                  style: const TextStyle(fontSize: 13)),
                              Text('Accountability: ${(inst['accountability'] as List).map((a) => (a as String).replaceAll('_', ' ')).join(', ')}',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      )).toList(),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Participation Culture', [
                    _buildInfoRow('Decision Making Style', gov.participationCulture.replaceAll('_', ' ').capitalize()),
                    _buildInfoRow('Decision Speed', gov.decisionLatency == 'low' ? 'Fast (days)' : 
                        gov.decisionLatency == 'medium' ? 'Medium (weeks)' : 'Slow (months)'),
                  ]),
                  const SizedBox(height: 16),
                  if (gov.stressResponses.isNotEmpty && gov.stressResponses.values.any((v) => v.isNotEmpty)) ...[
                    _buildSection('Crisis Response Strategy', [
                      if (gov.stressResponses['unrest']?.isNotEmpty == true)
                        _buildStressResponseCard(
                          'Civil Unrest',
                          gov.stressResponses['unrest']!,
                          Icons.warning,
                          Colors.orange,
                        ),
                      if (gov.stressResponses['corruption']?.isNotEmpty == true)
                        _buildStressResponseCard(
                          'Corruption',
                          gov.stressResponses['corruption']!,
                          Icons.gavel,
                          Colors.red,
                        ),
                      if (gov.stressResponses['economic_shock']?.isNotEmpty == true)
                        _buildStressResponseCard(
                          'Economic Crisis',
                          gov.stressResponses['economic_shock']!,
                          Icons.trending_down,
                          Colors.blue,
                        ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Performance Metrics', [
                    const Text(
                      'Current System Health:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...gov.metrics.entries.map((e) =>
                      _buildProgressRow(e.key.replaceAll('_', ' ').capitalize(), e.value)
                    ).toList(),
                  ]),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _toggleMembership,
        backgroundColor: _isMember ? Colors.red : AppColors.primaryDark,
        icon: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(_isMember ? Icons.exit_to_app : Icons.add),
        label: Text(_isMember ? 'Leave' : 'Join'),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, {String? editTarget}) {
    // Check if user can propose amendments
    final canPropose = _roleService.canPerform(
      member: _currentMember,
      government: widget.government,
      action: 'propose_laws',
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Pending proposals badge
                if (editTarget != null)
                  FutureBuilder<int>(
                    future: _proposalService.getPendingProposalsForSection(
                      widget.government.id,
                      editTarget,
                    ),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pending_actions, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (editTarget != null && canPropose)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Propose amendment',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProposeAmendmentView(
                            government: widget.government,
                            proposalType: 'governance_change',
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.replaceAll('_', ' ').capitalize(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                value > 0.7 ? Colors.green : value > 0.4 ? Colors.orange : Colors.red,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetBar(String key, int value) {
    final labels = {
      'security': 'Security & Enforcement',
      'social': 'Social Guarantees',
      'infrastructure': 'Infrastructure & Public Goods',
      'innovation': 'Innovation & Research',
      'admin': 'Administrative Overhead',
    };
    
    final icons = {
      'security': Icons.security,
      'social': Icons.favorite,
      'infrastructure': Icons.foundation,
      'innovation': Icons.lightbulb,
      'admin': Icons.admin_panel_settings,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icons[key], size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labels[key] ?? key,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressResponseCard(String title, String response, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  response.replaceAll('_', ' ').capitalize(),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRolePowers(Map<String, dynamic> powers) {
    final activePowers = <String>[];
    if (powers['fork'] == true) activePowers.add('Fork');
    if (powers['proposeEvents'] == true) activePowers.add('Propose Events');
    if (powers['proposeLaws'] == true) activePowers.add('Propose Laws');
    if (powers['vote'] == true) activePowers.add('Vote');
    if (powers['initiateSimulations'] == true) activePowers.add('Simulations');
    if (powers['beElected'] == true) activePowers.add('Be Elected');
    if (powers['editDocs'] != 'no') activePowers.add('Edit Docs (${powers['editDocs']})');
    return activePowers.isEmpty ? 'No special powers' : activePowers.join(', ');
  }

  Widget _buildQuickPermission(String label, bool allowed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Icon(
          allowed ? Icons.check_circle : Icons.lock,
          size: 14,
          color: allowed ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  void _showActionsSheet() {
    final actions = [
      {
        'category': 'Primary',
        'items': [
          {'label': 'Propose Amendment', 'icon': Icons.edit_document, 'action': 'propose_laws', 'type': 'governance_change'},
          {'label': 'Propose Law', 'icon': Icons.gavel, 'action': 'propose_laws', 'type': 'new_law'},
          {'label': 'Propose Event', 'icon': Icons.event, 'action': 'propose_events', 'type': 'event'},
          {'label': 'Fork Government', 'icon': Icons.call_split, 'action': 'fork', 'type': 'fork'},
          {'label': 'Run Simulation', 'icon': Icons.analytics, 'action': 'initiate_simulations', 'type': 'simulation'},
        ],
      },
      {
        'category': 'Secondary',
        'items': [
          {'label': 'View Proposals', 'icon': Icons.description, 'action': 'view', 'type': 'navigation'},
          {'label': 'View Role System', 'icon': Icons.admin_panel_settings, 'action': 'view', 'type': 'navigation'},
        ],
      },
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ...actions.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['category'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(section['items'] as List).map((item) {
                    final action = item['action'] as String;
                    final canDo = action == 'view' || _roleService.canPerform(
                      member: _currentMember,
                      government: widget.government,
                      action: action,
                    );
                    
                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: canDo ? AppColors.primaryDark : Colors.grey,
                      ),
                      title: Text(item['label'] as String),
                      trailing: Icon(
                        canDo ? Icons.check_circle : Icons.lock,
                        color: canDo ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (canDo) {
                          _handleAction(item);
                        } else {
                          _showLockedActionExplainer(item['label'] as String, action);
                        }
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(Map<String, dynamic> action) {
    final type = action['type'] as String;
    
    switch (type) {
      case 'navigation':
        if (action['label'] == 'View Proposals') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProposalsView(government: widget.government),
            ),
          );
        } else if (action['label'] == 'View Role System') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RolePowersView(
                government: widget.government,
                member: _currentMember,
              ),
            ),
          );
        }
        break;
      case 'governance_change':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProposeAmendmentView(
              government: widget.government,
              proposalType: 'governance_change',
            ),
          ),
        );
        break;
      case 'new_law':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LawWizardView(government: widget.government),
          ),
        );
        break;
      case 'event':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventWizardView(government: widget.government),
          ),
        );
        break;
      case 'fork':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForkWizardView(government: widget.government),
          ),
        );
        break;
      case 'simulation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimulationLaunchView(government: widget.government),
          ),
        );
        break;
    }
  }

  void _showLockedActionExplainer(String action, String permissionKey) {
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
            Text(_getPermissionRequirement(permissionKey)),
            const SizedBox(height: 16),
            const Text('What to do:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• View Role System to see requirements'),
            const Text('• Check how to gain required role'),
            if (!_isMember)
              const Text('• Join the government first'),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RolePowersView(
                    government: widget.government,
                    member: _currentMember,
                  ),
                ),
              );
            },
            child: const Text('View Roles'),
          ),
        ],
      ),
    );
  }

  String _getPermissionRequirement(String action) {
    if (_currentMember == null) return 'You must join this government first';
    
    // Find which role has this permission
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
      }
      
      if (hasPermission) {
        return 'Requires $role role. ${_getRoleTransitionHint(role)}';
      }
    }
    
    return 'This action is not available in this government';
  }

  String _getRoleTransitionHint(String role) {
    final transition = widget.government.roleTransitions[role];
    if (transition == null) return '';
    
    final method = transition['method'] as String? ?? 'automatic';
    switch (method) {
      case 'automatic':
        return 'Join and meet criteria';
      case 'election':
        return 'Must be elected';
      case 'appointment':
        return 'Must be appointed';
      case 'sortition':
        return 'Selected by lottery';
      case 'invitation':
        return 'Requires invitation';
      case 'public_vote':
        return 'Requires public approval';
      default:
        return '';
    }
  }

  String _formatLatency(String latency) {
    switch (latency) {
      case 'low':
        return 'fast';
      case 'medium':
        return 'medium';
      case 'high':
        return 'slow';
      default:
        return latency;
    }
  }

  Widget _buildPendingActionCard(ProposalModel proposal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProposalDetailView(
                government: widget.government,
                proposal: proposal,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColorForProposal(proposal.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ProposalStatus.getDisplayName(proposal.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ProposalType.getDisplayName(proposal.type),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                proposal.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                ProposalStatus.getNextStep(proposal.status),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColorForProposal(String status) {
    switch (status) {
      case ProposalStatus.voting:
        return Colors.purple;
      case ProposalStatus.passed:
        return Colors.green;
      case ProposalStatus.debating:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
