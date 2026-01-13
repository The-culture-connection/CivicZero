import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/utils/string_extensions.dart';

/// 3-Step Wizard for Proposing Governance Amendments
/// Feels like "filing a motion" - serious and procedural
class ProposeAmendmentView extends StatefulWidget {
  final GovernmentModel government;
  final String proposalType; // 'governance_change', 'new_law', etc.

  const ProposeAmendmentView({
    super.key,
    required this.government,
    this.proposalType = 'governance_change',
  });

  @override
  State<ProposeAmendmentView> createState() => _ProposeAmendmentViewState();
}

class _ProposeAmendmentViewState extends State<ProposeAmendmentView> {
  final PageController _pageController = PageController();
  final ProposalService _proposalService = ProposalService();
  final AuthService _authService = AuthService();
  
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoading = false;

  // Step 1: Choose target
  String _amendmentTarget = '';
  
  // Step 2: Make changes
  final _titleController = TextEditingController();
  final _rationaleController = TextEditingController();
  final List<ProposalChange> _changes = [];
  
  // For structured changes
  String? _selectedRole;
  String? _selectedPower;
  dynamic _newValue;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _rationaleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_currentStep == 0 && _amendmentTarget.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an amendment target')),
        );
        return;
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProposal();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProposal() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_rationaleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please explain your rationale')),
      );
      return;
    }

    if (_changes.isEmpty && widget.proposalType == 'governance_change') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify at least one change')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = _authService.currentUser!.uid;
      final userData = await _authService.getUserData(uid);
      final username = userData?.username ?? 'Unknown';

      final sop = widget.government.lawmakingSOP[widget.proposalType] ?? {};

      await _proposalService.createProposal(
        governmentId: widget.government.id,
        creatorUid: uid, // UID = AUTHORITY
        creatorUsername: username, // Username = DISPLAY
        type: widget.proposalType,
        category: _amendmentTarget.isNotEmpty ? _amendmentTarget : null,
        title: _titleController.text.trim(),
        rationale: _rationaleController.text.trim(),
        changes: _changes,
        sopSnapshot: sop,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.proposalType == 'governance_change'
                  ? 'Governance amendment proposed!'
                  : 'Proposal submitted!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proposalType == 'governance_change' 
            ? 'Propose Amendment' 
            : 'New Proposal'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStep1ChooseTarget(),
                _buildStep2MakeChanges(),
                _buildStep3PreviewSubmit(),
              ],
            ),
          ),
          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousStep,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
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
                        : Text(_currentStep == _totalSteps - 1 ? 'Submit' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1ChooseTarget() {
    final targets = [
      {'key': 'preamble', 'label': 'Preamble', 'icon': Icons.book, 'desc': 'Purpose and values'},
      {'key': 'purpose_principles', 'label': 'Purpose & Principles', 'icon': Icons.emoji_objects, 'desc': 'Core objectives'},
      {'key': 'rights', 'label': 'Rights & Limits', 'icon': Icons.shield, 'desc': 'Rights and obligations'},
      {'key': 'structure', 'label': 'Branches / Checks', 'icon': Icons.account_tree, 'desc': 'Government structure'},
      {'key': 'role_system', 'label': 'Role System', 'icon': Icons.admin_panel_settings, 'desc': 'Permissions matrix'},
      {'key': 'lawmaking_sop', 'label': 'SOP / Lawmaking Rules', 'icon': Icons.gavel, 'desc': 'Procedural rules'},
      {'key': 'institutional', 'label': 'Other Institutional Rules', 'icon': Icons.settings, 'desc': 'Enforcement, change rules'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Amendment Target',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'What part of the government do you want to change?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...targets.map((target) {
            final isSelected = _amendmentTarget == target['key'];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isSelected ? AppColors.primaryDark.withOpacity(0.1) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryDark : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _amendmentTarget = target['key'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryDark : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          target['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              target['label'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primaryDark : null,
                              ),
                            ),
                            Text(
                              target['desc'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.primaryDark),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStep2MakeChanges() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe Your Amendment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Amendment Title',
              border: OutlineInputBorder(),
              hintText: 'E.g., "Allow Members to Propose Laws"',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rationaleController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Rationale (Why this change?)',
              border: OutlineInputBorder(),
              hintText: 'Explain the reasoning behind this amendment...',
            ),
          ),
          const SizedBox(height: 24),
          if (_amendmentTarget == 'role_system') ...[
            const Text(
              'Specific Changes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(),
              ),
              value: _selectedRole,
              items: widget.government.enabledRoles
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.capitalize()),
                      ))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedRole = val;
                _selectedPower = null;
              }),
            ),
            if (_selectedRole != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Permission',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPower,
                items: const [
                  DropdownMenuItem(value: 'fork', child: Text('Can Fork')),
                  DropdownMenuItem(value: 'proposeEvents', child: Text('Can Propose Events')),
                  DropdownMenuItem(value: 'proposeLaws', child: Text('Can Propose Laws')),
                  DropdownMenuItem(value: 'vote', child: Text('Can Vote')),
                  DropdownMenuItem(value: 'initiateSimulations', child: Text('Can Run Simulations')),
                  DropdownMenuItem(value: 'beElected', child: Text('Can Be Elected')),
                  DropdownMenuItem(value: 'editDocs', child: Text('Document Editing Level')),
                ],
                onChanged: (val) => setState(() => _selectedPower = val),
              ),
              if (_selectedPower != null) ...[
                const SizedBox(height: 16),
                if (_selectedPower == 'editDocs')
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'New Value',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'no', child: Text('No')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft Only')),
                      DropdownMenuItem(value: 'direct', child: Text('Direct Edit')),
                    ],
                    onChanged: (val) => setState(() => _newValue = val),
                  )
                else
                  SwitchListTile(
                    title: const Text('Enable Permission'),
                    value: _newValue as bool? ?? false,
                    onChanged: (val) => setState(() => _newValue = val),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addChange,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Change'),
                ),
              ],
            ],
            const SizedBox(height: 24),
            if (_changes.isNotEmpty) ...[
              const Text(
                'Proposed Changes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._changes.map((change) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(change.path.split('.').last.capitalize()),
                  subtitle: Text('${change.op}: ${change.path} = ${change.value}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _changes.remove(change)),
                  ),
                ),
              )).toList(),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    'For ${_amendmentTarget.replaceAll('_', ' ')}, describe your changes in the rationale above.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addChange() {
    if (_selectedRole != null && _selectedPower != null && _newValue != null) {
      setState(() {
        _changes.add(ProposalChange(
          op: 'set',
          path: 'rolePowers.$_selectedRole.$_selectedPower',
          value: _newValue,
        ));
        // Reset for next change
        _selectedPower = null;
        _newValue = null;
      });
    }
  }

  Widget _buildStep3PreviewSubmit() {
    final sop = widget.government.lawmakingSOP[widget.proposalType] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview & Submit',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Preview Card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.proposalType == 'governance_change' 
                              ? Colors.red.shade100 
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.proposalType == 'governance_change')
                              Icon(Icons.shield, size: 14, color: Colors.red.shade700),
                            if (widget.proposalType == 'governance_change')
                              const SizedBox(width: 4),
                            Text(
                              widget.proposalType.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.proposalType == 'governance_change'
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _titleController.text.isNotEmpty ? _titleController.text : 'No title yet',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rationaleController.text.isNotEmpty ? _rationaleController.text : 'No rationale yet',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (_changes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._changes.map((change) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text('• ${change.op} ${change.path} = ${change.value}'),
                    )).toList(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Process Requirements
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Required Process',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProcessStep('Debate', sop['debateRequired'] == 'always' ? 'Required' : 'Optional'),
                  _buildProcessStep('Vote', sop['voteRequired'] == true ? 'Required' : 'Optional'),
                  _buildProcessStep('Threshold', (sop['threshold'] as String? ?? 'simple_majority').replaceAll('_', ' ')),
                  _buildProcessStep('Voting Body', (sop['votingBody'] as String? ?? 'all_members').replaceAll('_', ' ')),
                  if (widget.proposalType == 'governance_change')
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Constitutional amendment - requires supermajority',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(child: Text(value.capitalize())),
        ],
      ),
    );
  }
}
