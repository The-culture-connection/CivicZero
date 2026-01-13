import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/utils/string_extensions.dart';

class GovernmentDetailView extends StatefulWidget {
  final GovernmentModel government;

  const GovernmentDetailView({super.key, required this.government});

  @override
  State<GovernmentDetailView> createState() => _GovernmentDetailViewState();
}

class _GovernmentDetailViewState extends State<GovernmentDetailView> {
  final GovernmentService _governmentService = GovernmentService();
  final AuthService _authService = AuthService();
  bool _isMember = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      // Check membership by UID (AUTHORITY)
      final isMember = await _governmentService.isMember(widget.government.id, uid);
      setState(() {
        _isMember = isMember;
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
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Rights & Obligations', [
                    _buildInfoRow('Recognized Rights', gov.rightsCategories.join(', ')),
                    _buildInfoRow('Rights Can Be Limited By', gov.rightsLimits.join(', ')),
                    _buildInfoRow('Citizen Obligations', gov.citizenObligations.join(', ')),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Government Structure', [
                    _buildInfoRow('Branches', gov.branches.join(', ')),
                    _buildInfoRow('Checks & Balances', gov.checksAndBalances.replaceAll('_', ' ').capitalize()),
                  ]),
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
                  ]),
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

  Widget _buildSection(String title, List<Widget> children) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
}
