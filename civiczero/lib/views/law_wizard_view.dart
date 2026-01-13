import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/utils/string_extensions.dart';

class LawWizardView extends StatefulWidget {
  final GovernmentModel government;

  const LawWizardView({super.key, required this.government});

  @override
  State<LawWizardView> createState() => _LawWizardViewState();
}

class _LawWizardViewState extends State<LawWizardView> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _rationaleController = TextEditingController();
  final _enforcementController = TextEditingController();
  final ProposalService _proposalService = ProposalService();
  final AuthService _authService = AuthService();
  
  int _voteDurationHours = 0;
  final _customDurationController = TextEditingController();
  String _lawType = 'policy';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _rationaleController.dispose();
    _enforcementController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (_titleController.text.trim().isEmpty || _summaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = _authService.currentUser!.uid;
      final userData = await _authService.getUserData(uid);
      final username = userData?.username ?? 'Unknown';
      final sop = widget.government.lawmakingSOP['new_law'] ?? {};

      final proposalId = await _proposalService.createProposal(
        governmentId: widget.government.id,
        creatorUid: uid,
        creatorUsername: username,
        type: 'new_law',
        category: _lawType,
        title: _titleController.text.trim(),
        rationale: '${_summaryController.text.trim()}\n\n${_rationaleController.text.trim()}\n\nEnforcement: ${_enforcementController.text.trim()}',
        changes: [],
        sopSnapshot: sop,
        voteDurationHours: _voteDurationHours == -1 
            ? int.tryParse(_customDurationController.text) ?? 48 
            : _voteDurationHours,
      );
      
      await _proposalService.startVoting(widget.government.id, proposalId, 
          _voteDurationHours == -1 ? int.tryParse(_customDurationController.text) ?? 48 : _voteDurationHours);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Law proposal submitted!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if proposal type is enabled in this government
    if (!widget.government.proposalTypes.contains('new_law')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Propose New Law'),
          backgroundColor: AppColors.primaryDark,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Law Proposals Not Enabled',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This government does not allow law proposals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Get SOP configured for this government
    final sop = widget.government.lawmakingSOP['new_law'];
    if (sop == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Propose New Law'),
          backgroundColor: AppColors.primaryDark,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 80, color: Colors.orange[400]),
                const SizedBox(height: 16),
                const Text(
                  'SOP Not Configured',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This government has not configured lawmaking procedures for new laws.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose New Law'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Propose New Law', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Law Type', border: OutlineInputBorder()),
              value: _lawType,
              items: const [
                DropdownMenuItem(value: 'policy', child: Text('Policy')),
                DropdownMenuItem(value: 'regulation', child: Text('Regulation')),
                DropdownMenuItem(value: 'resolution', child: Text('Resolution')),
                DropdownMenuItem(value: 'ordinance', child: Text('Ordinance')),
              ],
              onChanged: (val) => setState(() => _lawType = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Law Title *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Summary *', border: OutlineInputBorder(), hintText: 'Brief description of the law'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rationaleController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Rationale', border: OutlineInputBorder(), hintText: 'Why is this law needed?'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _enforcementController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Enforcement Notes', border: OutlineInputBorder(), hintText: 'How will this be enforced?'),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voting Duration', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: _voteDurationHours,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('30 seconds (testing)')),
                        DropdownMenuItem(value: 6, child: Text('6 hours')),
                        DropdownMenuItem(value: 24, child: Text('24 hours')),
                        DropdownMenuItem(value: 48, child: Text('48 hours')),
                        DropdownMenuItem(value: 168, child: Text('1 week')),
                        DropdownMenuItem(value: -1, child: Text('Custom')),
                      ],
                      onChanged: (val) => setState(() => _voteDurationHours = val!),
                    ),
                    if (_voteDurationHours == -1) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customDurationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Hours', border: OutlineInputBorder()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Required Process', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProcessStep('Debate', _getDebateRequirement(sop)),
                    _buildProcessStep('Vote', sop['voteRequired'] == true ? 'Required' : 'Not Required'),
                    if (sop['voteRequired'] == true) ...[
                      _buildProcessStep('Threshold', (sop['threshold'] as String? ?? 'simple_majority').replaceAll('_', ' ')),
                      _buildProcessStep('Voting Body', (sop['votingBody'] as String? ?? 'all_members').replaceAll('_', ' ')),
                      _buildProcessStep('Voting Time', _getLatencyDisplay(sop['votingLatency'] as String? ?? 'medium')),
                    ],
                    if (sop['debateRequired'] != 'never')
                      _buildProcessStep('Debate Time', _getLatencyDisplay(sop['debateLatency'] as String? ?? 'medium')),
                    _buildProcessStep('Execution', _getLatencyDisplay(sop['executionLatency'] as String? ?? 'medium')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProposal,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Proposal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessStep(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          Expanded(child: Text(value.capitalize(), style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _getDebateRequirement(Map<String, dynamic> sop) {
    final required = sop['debateRequired'] as String? ?? 'optional';
    switch (required) {
      case 'always':
        return 'Required';
      case 'never':
        return 'Not Allowed';
      case 'optional':
        return 'Optional';
      case 'if_challenged':
        return 'If Challenged';
      default:
        return required.capitalize();
    }
  }

  String _getLatencyDisplay(String latency) {
    switch (latency) {
      case 'low':
        return 'Fast (hours-days)';
      case 'medium':
        return 'Medium (days-week)';
      case 'high':
        return 'Slow (weeks-month)';
      default:
        return latency;
    }
  }
}
