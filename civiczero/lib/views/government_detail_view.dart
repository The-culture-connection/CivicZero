import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/auth_service.dart';

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
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      final isMember = await _governmentService.isMember(widget.government.id, userId);
      setState(() {
        _isMember = isMember;
      });
    }
  }

  Future<void> _toggleMembership() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isMember) {
        await _governmentService.leaveGovernment(widget.government.id, userId);
        setState(() {
          _isMember = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left government')),
          );
        }
      } else {
        await _governmentService.joinGovernment(widget.government.id, userId);
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
                  _buildSection('Representation & Elections', [
                    _buildInfoRow('Representation Model', gov.representationModel.replaceAll('_', ' ').capitalize()),
                    _buildInfoRow('Voting Eligibility', gov.votingEligibility.join(', ')),
                    _buildInfoRow('Office Eligibility', gov.officeEligibility.join(', ')),
                    _buildInfoRow('Election Method', gov.electionMethod.replaceAll('_', ' ').capitalize()),
                    _buildInfoRow('Term Length', gov.termLength),
                    _buildInfoRow('Term Limits', gov.termLimits ? 'Yes' : 'No'),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Lawmaking Process', [
                    _buildInfoRow('Who Can Propose Laws', gov.lawProposers.join(', ')),
                    _buildInfoRow('Passage Requirements', gov.passageRules.replaceAll('_', ' ').capitalize()),
                    _buildInfoRow('Review Mechanisms', gov.reviewMechanisms.join(', ')),
                  ]),
                  const SizedBox(height: 16),
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
