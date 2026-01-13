import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/utils/string_extensions.dart';

class NewGovernmentView extends StatefulWidget {
  const NewGovernmentView({super.key});

  @override
  State<NewGovernmentView> createState() => _NewGovernmentViewState();
}

class _NewGovernmentViewState extends State<NewGovernmentView> {
  final PageController _pageController = PageController();
  final GovernmentService _governmentService = GovernmentService();
  final AuthService _authService = AuthService();
  
  int _currentPage = 0;
  final int _totalPages = 16; // Consolidated and enhanced
  bool _isLoading = false;

  // Form data
  final _nameController = TextEditingController();
  
  // NEW: Blueprint Seed
  String? _blueprintSeed;
  
  // Section 0: Scope
  String _scope = 'local';
  
  // NEW: Budget Allocation (must total 100)
  final Map<String, int> _budgetWeights = {
    'security': 20,
    'social': 20,
    'infrastructure': 20,
    'innovation': 20,
    'admin': 20,
  };
  
  // Section 1: Purpose & Preamble
  final Set<String> _purposes = {};
  final Map<String, double> _principles = {
    'equality': 0.5,
    'fairness': 0.5,
    'efficiency': 0.5,
    'transparency': 0.5,
    'stability': 0.5,
    'adaptability': 0.5,
    'accountability': 0.5,
    'autonomy': 0.5,
  };
  String _preambleMode = 'hybrid';
  final _preambleController = TextEditingController();
  
  // Section 2: Rights & Obligations
  final Set<String> _rightsCategories = {};
  final Set<String> _rightsLimits = {};
  final Set<String> _obligations = {};
  
  // Section 3: Structure
  final Set<String> _branches = {};
  String _checksAndBalances = 'yes_symmetrical';
  
  // NEW: Custom Institutions
  final List<Map<String, dynamic>> _customInstitutions = [];
  
  // Section 4: Role System (CONSOLIDATED)
  final Set<String> _enabledRoles = {'visitor', 'member', 'voter'};
  final Map<String, Map<String, dynamic>> _rolePowers = {};
  final Map<String, Map<String, dynamic>> _roleTransitions = {};
  final Map<String, String> _roleDurations = {};
  
  // Section 5: Lawmaking SOP (ENHANCED)
  final Set<String> _proposalTypes = {'new_law'};
  final Map<String, Map<String, dynamic>> _lawmakingSOP = {};
  final Map<String, dynamic> _forkRules = {};
  final Map<String, dynamic> _simulationTriggers = {};
  
  // Section 6: Enforcement
  String _enforcementAuthority = 'central_authority';
  final Set<String> _consequenceTypes = {};
  String _enforcementDiscretion = 'context_based';
  
  // Section 7: Change & Evolution
  String _amendmentDifficulty = 'moderate';
  final Set<String> _changeTriggers = {};
  
  // Section 8: Metrics
  final Set<String> _trackedOutcomes = {};
  
  // NEW: Crisis Stress Test
  final Map<String, String> _stressResponses = {
    'unrest': '',
    'corruption': '',
    'economic_shock': '',
  };
  
  // NEW: Participation Culture
  String _participationCulture = 'balanced';
  String _decisionLatency = 'medium';

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    // Initialize default role powers
    for (var role in ['visitor', 'member', 'contributor', 'voter', 'representative', 'moderator', 'founder']) {
      _rolePowers[role] = {
        'fork': false,
        'proposeEvents': false,
        'proposeLaws': false,
        'vote': false,
        'initiateSimulations': false,
        'beElected': false,
        'editDocs': 'no',
      };
    }
    
    // Set some reasonable defaults
    _rolePowers['member']!['proposeEvents'] = true;
    _rolePowers['voter']!['vote'] = true;
    _rolePowers['contributor']!['proposeLaws'] = true;
    _rolePowers['representative']!['editDocs'] = 'draft';
    
    // Initialize default lawmaking SOP
    _lawmakingSOP['new_law'] = {
      'debateRequired': 'optional',
      'debateFormat': 'open_discussion',
      'voteRequired': true,
      'votingBody': 'eligible_voters',
      'threshold': 'simple_majority',
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _preambleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitGovernment();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitGovernment() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a government name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate preamble if hybrid mode
      String preambleText = _preambleController.text;
      if (_preambleMode == 'auto_generated' || (_preambleMode == 'hybrid' && preambleText.isEmpty)) {
        preambleText = _generatePreamble();
      }

      final government = GovernmentModel(
        id: '',
        name: _nameController.text.trim(),
        createdBy: _authService.currentUser!.uid,
        createdAt: DateTime.now(),
        blueprintSeed: _blueprintSeed,
        scope: _scope,
        budgetWeights: _budgetWeights,
        purpose: _purposes.toList(),
        principles: _principles,
        preambleMode: _preambleMode,
        preambleText: preambleText,
        rightsCategories: _rightsCategories.toList(),
        rightsLimits: _rightsLimits.toList(),
        citizenObligations: _obligations.toList(),
        branches: _branches.toList(),
        checksAndBalances: _checksAndBalances,
        enabledRoles: _enabledRoles.toList(),
        rolePowers: _rolePowers,
        roleTransitions: _roleTransitions,
        roleDurations: _roleDurations,
        proposalTypes: _proposalTypes.toList(),
        lawmakingSOP: _lawmakingSOP,
        forkRules: _forkRules,
        simulationTriggers: _simulationTriggers,
        enforcementAuthority: _enforcementAuthority,
        consequenceTypes: _consequenceTypes.toList(),
        enforcementDiscretion: _enforcementDiscretion,
        amendmentDifficulty: _deriveAmendmentDifficulty(),
        changeTriggers: _changeTriggers.isNotEmpty ? _changeTriggers.toList() : ['public_vote', 'crisis'],
        metrics: {
          'trust': 0.5,
          'stability': 0.5,
          'participation': 0.5,
          'satisfaction': 0.5,
          'economic_health': 0.5,
        },
        trackedOutcomes: _trackedOutcomes.toList(),
        customInstitutions: _customInstitutions,
        stressResponses: _stressResponses,
        participationCulture: _participationCulture,
        decisionLatency: _decisionLatency,
        memberIds: [_authService.currentUser!.uid],
        memberCount: 1,
      );

      await _governmentService.createGovernment(government);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Government created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _deriveAmendmentDifficulty() {
    // Derive from constitutional amendment SOP if configured
    final constSOP = _lawmakingSOP['constitutional'];
    if (constSOP != null) {
      final threshold = constSOP['threshold'] as String? ?? 'simple_majority';
      if (threshold.contains('75')) return 'difficult';
      if (threshold.contains('66')) return 'moderate';
      if (threshold == 'consensus') return 'difficult';
      return 'moderate';
    }
    return 'moderate'; // default
  }

  String _generatePreamble() {
    final purposes = _purposes.join(', ');
    return 'We, the members of ${_nameController.text}, establish this $_scope government '
        'for the purposes of $purposes. '
        'We are guided by principles of ${_principles.entries.where((e) => e.value > 0.6).map((e) => e.key).join(', ')}. '
        'We recognize the importance of ${_rightsCategories.join(', ')} rights '
        'and commit to ${_obligations.join(', ')}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Government'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
          // Page indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Step ${_currentPage + 1} of $_totalPages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _buildNameAndScopePage(),
                _buildBlueprintSeedPage(),
                _buildBudgetAllocationPage(),
                _buildPurposePage(),
                _buildRightsPage(),
                _buildStructurePage(),
                _buildCustomInstitutionPage(),
                _buildRoleDefinitionsPage(),
                _buildRolePowersPage(),
                _buildRoleTransitionsPage(),
                _buildParticipationCulturePage(),
                _buildLawmakingSOPPage(),
                _buildForkRulesPage(),
                _buildSimulationTriggersPage(),
                _buildEnforcementPage(),
                _buildStressTestPage(),
                _buildMetricsPage(),
              ],
            ),
          ),
          // Navigation buttons
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
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousPage,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: AppColors.primaryLight,
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
                        : Text(_currentPage == _totalPages - 1 ? 'Create' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintSeedPage() {
    return _buildPageScaffold(
      title: 'Choose a Blueprint (Optional)',
      children: [
        const Text(
          'Start from a template or build from scratch',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildBlueprintCard(
          'Direct Democracy',
          'All members vote on all laws. High participation, slower decisions.',
          'direct_democracy',
          Icons.how_to_vote,
        ),
        _buildBlueprintCard(
          'Representative Republic',
          'Elected representatives with checks and balances. Balanced approach.',
          'republic',
          Icons.account_balance,
        ),
        _buildBlueprintCard(
          'Technocracy',
          'Expert-led with merit-based selection. Efficient, expertise-focused.',
          'technocracy',
          Icons.science,
        ),
        _buildBlueprintCard(
          'Consensus Community',
          'Deliberation and unanimity required. High trust, relationship-based.',
          'consensus',
          Icons.groups,
        ),
        _buildBlueprintCard(
          'From Scratch',
          'Build your government without any pre-set defaults.',
          null,
          Icons.construction,
        ),
      ],
    );
  }

  Widget _buildBlueprintCard(String title, String description, String? seed, IconData icon) {
    final isSelected = _blueprintSeed == seed;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppColors.primaryDark.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryDark : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _blueprintSeed = seed),
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
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primaryDark : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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
  }

  Widget _buildBudgetAllocationPage() {
    final total = _budgetWeights.values.fold(0, (a, b) => a + b);
    final isValid = total == 100;

    return _buildPageScaffold(
      title: 'Budget Allocation',
      children: [
        const Text(
          'Allocate 100 points across priorities. This shapes your government\'s focus.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isValid ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isValid ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.warning,
                color: isValid ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Total: $total / 100',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isValid ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildBudgetSlider('Security & Enforcement', 'security', Icons.security),
        _buildBudgetSlider('Social Guarantees', 'social', Icons.favorite),
        _buildBudgetSlider('Infrastructure & Public Goods', 'infrastructure', Icons.foundation),
        _buildBudgetSlider('Innovation & Research', 'innovation', Icons.lightbulb),
        _buildBudgetSlider('Administrative Overhead', 'admin', Icons.admin_panel_settings),
      ],
    );
  }

  Widget _buildBudgetSlider(String label, String key, IconData icon) {
    final value = _budgetWeights[key]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          onChanged: (val) {
            setState(() => _budgetWeights[key] = val.toInt());
          },
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: AppColors.primaryDark,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomInstitutionPage() {
    return _buildPageScaffold(
      title: 'Custom Institution (Optional)',
      children: [
        const Text(
          'Add a unique institution to your government. This creates distinctive governance.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        if (_customInstitutions.isEmpty) ...[
          ElevatedButton.icon(
            onPressed: () => _showAddInstitutionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Institution'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Or skip to keep it simple',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ] else
          ..._customInstitutions.map((inst) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: AppColors.primaryDark),
              title: Text(inst['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Type: ${inst['type']}\nPowers: ${(inst['powers'] as List).join(', ')}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() => _customInstitutions.remove(inst));
                },
              ),
              isThreeLine: true,
            ),
          )).toList(),
        if (_customInstitutions.isNotEmpty) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showAddInstitutionDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Another Institution'),
          ),
        ],
      ],
    );
  }

  void _showAddInstitutionDialog() {
    String name = '';
    String type = 'ombudsman';
    Set<String> powers = {};
    String selection = 'election';
    Set<String> accountability = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Institution'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Institution Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),
                const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: [
                    'ombudsman',
                    'citizen_assembly',
                    'standards_board',
                    'ethics_tribunal',
                    'mediation_council',
                    'custom',
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                  onChanged: (val) => setDialogState(() => type = val!),
                ),
                const SizedBox(height: 16),
                const Text('Powers:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['advisory', 'veto', 'audit', 'investigate', 'prosecute', 'publish_reports']
                      .map((p) => FilterChip(
                            label: Text(p),
                            selected: powers.contains(p),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) powers.add(p); else powers.remove(p);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('Selection Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selection,
                  isExpanded: true,
                  items: ['election', 'sortition', 'appointment', 'credentials']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setDialogState(() => selection = val!),
                ),
                const SizedBox(height: 16),
                const Text('Accountability:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['recall', 'term_limit', 'oversight', 'transparency']
                      .map((a) => FilterChip(
                            label: Text(a),
                            selected: accountability.contains(a),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) accountability.add(a); else accountability.remove(a);
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    _customInstitutions.add({
                      'name': name,
                      'type': type,
                      'powers': powers.toList(),
                      'selection': selection,
                      'accountability': accountability.toList(),
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationCulturePage() {
    return _buildPageScaffold(
      title: 'Participation Culture',
      children: [
        const Text(
          'How does your government make decisions?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Low participation, high delegation', 'low_delegation', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        _buildRadioOption('Frequent referendums', 'frequent_referendums', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        _buildRadioOption('Deliberation-first (discussion required)', 'deliberation_first', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        _buildRadioOption('Efficiency-first (fast decisions)', 'efficiency_first', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        _buildRadioOption('Expertise-gated (credential pathways)', 'expertise_gated', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        _buildRadioOption('Rotating civic duty (sortition)', 'sortition_duty', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        _buildRadioOption('Balanced (default)', 'balanced', _participationCulture, (val) => setState(() => _participationCulture = val!)),
        const SizedBox(height: 24),
        const Text(
          'Decision Speed',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Fast (days)', 'low', _decisionLatency, (val) => setState(() => _decisionLatency = val!)),
        _buildRadioOption('Medium (weeks)', 'medium', _decisionLatency, (val) => setState(() => _decisionLatency = val!)),
        _buildRadioOption('Slow (months)', 'high', _decisionLatency, (val) => setState(() => _decisionLatency = val!)),
      ],
    );
  }

  Widget _buildStressTestPage() {
    return _buildPageScaffold(
      title: 'Crisis Stress Test',
      children: [
        const Text(
          'How would your government respond to these scenarios?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        _buildStressScenario(
          'Scenario A: Civil Unrest',
          'A controversial law passes. Protests erupt. How do you respond?',
          Icons.warning,
          'unrest',
          ['enforce_strictly', 'open_dialogue', 'hold_referendum', 'judicial_review', 'decentralize_decision'],
        ),
        const SizedBox(height: 24),
        _buildStressScenario(
          'Scenario B: Corruption Scandal',
          'A high-ranking official is accused of corruption. What happens?',
          Icons.gavel,
          'corruption',
          ['independent_audit', 'public_recall', 'criminal_trial', 'immunity_protection', 'forced_resignation'],
        ),
        const SizedBox(height: 24),
        _buildStressScenario(
          'Scenario C: Economic Shock',
          'A sudden economic crisis hits. Unemployment rises. What\'s your response?',
          Icons.trending_down,
          'economic_shock',
          ['austerity_measures', 'stimulus_spending', 'price_controls', 'universal_basic_income', 'deregulation'],
        ),
      ],
    );
  }

  Widget _buildStressScenario(String title, String description, IconData icon, String key, List<String> options) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...options.map((option) => RadioListTile<String>(
              title: Text(option.replaceAll('_', ' ').capitalize()),
              value: option,
              groupValue: _stressResponses[key],
              onChanged: (val) => setState(() => _stressResponses[key] = val!),
              dense: true,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameAndScopePage() {
    return _buildPageScaffold(
      title: 'Government Name & Scope',
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Government Name',
            border: OutlineInputBorder(),
            hintText: 'Enter a name for your government',
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'What level of governance are you designing?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Local (city / municipality / community)', 'local', _scope, (val) => setState(() => _scope = val!)),
        _buildRadioOption('Regional (state / province / territory)', 'regional', _scope, (val) => setState(() => _scope = val!)),
        _buildRadioOption('National (federal)', 'national', _scope, (val) => setState(() => _scope = val!)),
      ],
    );
  }

  Widget _buildPurposePage() {
    return _buildPageScaffold(
      title: 'Purpose & Preamble',
      children: [
        const Text(
          'What is the primary purpose of this government? (Select up to 3)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Provide safety and order', 'safety', _purposes),
        _buildCheckOption('Protect individual freedoms', 'freedom', _purposes),
        _buildCheckOption('Promote economic stability', 'economic_stability', _purposes),
        _buildCheckOption('Ensure basic needs are met', 'basic_needs', _purposes),
        _buildCheckOption('Coordinate shared resources', 'shared_resources', _purposes),
        _buildCheckOption('Resolve disputes', 'dispute_resolution', _purposes),
        _buildCheckOption('Advance long-term collective goals', 'collective_goals', _purposes),
        const SizedBox(height: 24),
        const Text(
          'Guiding Principles (Use sliders to set importance)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        ..._principles.keys.map((key) => _buildSlider(key, _principles[key]!, (val) {
          setState(() => _principles[key] = val);
        })).toList(),
        const SizedBox(height: 24),
        const Text(
          'Preamble Construction',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildRadioOption('Auto-generated from answers', 'auto_generated', _preambleMode, (val) => setState(() => _preambleMode = val!)),
        _buildRadioOption('Write my own', 'user_written', _preambleMode, (val) => setState(() => _preambleMode = val!)),
        _buildRadioOption('Hybrid (edit generated)', 'hybrid', _preambleMode, (val) => setState(() => _preambleMode = val!)),
        if (_preambleMode == 'user_written' || _preambleMode == 'hybrid') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _preambleController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Preamble Text',
              border: OutlineInputBorder(),
              hintText: 'Write your preamble...',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRightsPage() {
    return _buildPageScaffold(
      title: 'Rights & Obligations',
      children: [
        const Text(
          'Which types of rights does this government recognize?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Personal autonomy (speech, belief, movement)', 'personal', _rightsCategories),
        _buildCheckOption('Legal protections (due process, fair trial)', 'legal', _rightsCategories),
        _buildCheckOption('Political participation (vote, run for office)', 'political', _rightsCategories),
        _buildCheckOption('Economic participation (work, own property)', 'economic', _rightsCategories),
        _buildCheckOption('Social guarantees (education, healthcare, housing)', 'social', _rightsCategories),
        _buildCheckOption('Digital rights (data ownership, privacy)', 'digital', _rightsCategories),
        const SizedBox(height: 24),
        const Text(
          'Can rights be limited under certain conditions?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Never', 'never', _rightsLimits),
        _buildCheckOption('Only with public approval', 'public_approval', _rightsLimits),
        _buildCheckOption('Only during emergencies', 'emergencies', _rightsLimits),
        _buildCheckOption('By courts', 'courts', _rightsLimits),
        _buildCheckOption('By legislature', 'legislature', _rightsLimits),
        _buildCheckOption('By executive action', 'executive', _rightsLimits),
        const SizedBox(height: 24),
        const Text(
          'What obligations do members have?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Follow enacted laws', 'follow_laws', _obligations),
        _buildCheckOption('Pay taxes or contributions', 'taxes', _obligations),
        _buildCheckOption('Participate in civic duties (jury, service)', 'civic_duties', _obligations),
        _buildCheckOption('Defend the community if required', 'defend', _obligations),
        _buildCheckOption('None', 'none', _obligations),
      ],
    );
  }

  Widget _buildStructurePage() {
    return _buildPageScaffold(
      title: 'Structure of Government',
      children: [
        const Text(
          'Which branches exist in your government?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Law-making (Legislative)', 'legislative', _branches),
        _buildCheckOption('Law-enforcing (Executive)', 'executive', _branches),
        _buildCheckOption('Law-interpreting (Judicial)', 'judicial', _branches),
        _buildCheckOption('Administrative / Technical', 'administrative', _branches),
        _buildCheckOption('Independent Oversight', 'oversight', _branches),
        const SizedBox(height: 24),
        const Text(
          'Can branches limit each other\'s power?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('No', 'no', _checksAndBalances, (val) => setState(() => _checksAndBalances = val!)),
        _buildRadioOption('Yes, symmetrically', 'yes_symmetrical', _checksAndBalances, (val) => setState(() => _checksAndBalances = val!)),
        _buildRadioOption('Yes, asymmetrically', 'yes_asymmetrical', _checksAndBalances, (val) => setState(() => _checksAndBalances = val!)),
      ],
    );
  }

  Widget _buildRoleDefinitionsPage() {
    final allRoles = ['visitor', 'member', 'contributor', 'voter', 'representative', 'moderator', 'founder'];
    return _buildPageScaffold(
      title: 'Role Definitions',
      children: [
        const Text(
          'Which roles exist in your government? (Minimum: Visitor + Member)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ...allRoles.map((role) => CheckboxListTile(
          title: Text(role.capitalize()),
          subtitle: Text(_getRoleDescription(role)),
          value: _enabledRoles.contains(role),
          onChanged: (val) {
            setState(() {
              if (val == true && !['visitor', 'member'].contains(role)) {
                _enabledRoles.add(role);
              } else if (val == false && !['visitor', 'member'].contains(role)) {
                _enabledRoles.remove(role);
              }
            });
          },
        )).toList(),
      ],
    );
  }

  String _getRoleDescription(String role) {
    final descriptions = {
      'visitor': 'Read-only access',
      'member': 'Joined participant',
      'contributor': 'Can write drafts',
      'voter': 'Meets voting eligibility',
      'representative': 'Elected/selected leader',
      'moderator': 'Facilitates discussions',
      'founder': 'Creator (no permanent authority)',
    };
    return descriptions[role] ?? '';
  }

  Widget _buildRolePowersPage() {
    return _buildPageScaffold(
      title: 'Role Powers',
      children: [
        const Text(
          'Configure what each role can do',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ..._enabledRoles.map((role) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(role.capitalize(), style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Can Fork Government'),
                      value: _rolePowers[role]?['fork'] ?? false,
                      onChanged: (val) => setState(() => _rolePowers[role]!['fork'] = val),
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('Can Propose Events'),
                      value: _rolePowers[role]?['proposeEvents'] ?? false,
                      onChanged: (val) => setState(() => _rolePowers[role]!['proposeEvents'] = val),
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('Can Propose Laws'),
                      value: _rolePowers[role]?['proposeLaws'] ?? false,
                      onChanged: (val) => setState(() => _rolePowers[role]!['proposeLaws'] = val),
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('Can Vote'),
                      value: _rolePowers[role]?['vote'] ?? false,
                      onChanged: (val) => setState(() => _rolePowers[role]!['vote'] = val),
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('Can Initiate Simulations'),
                      value: _rolePowers[role]?['initiateSimulations'] ?? false,
                      onChanged: (val) => setState(() => _rolePowers[role]!['initiateSimulations'] = val),
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('Can Be Elected'),
                      value: _rolePowers[role]?['beElected'] ?? false,
                      onChanged: (val) => setState(() => _rolePowers[role]!['beElected'] = val),
                      dense: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Edit Foundational Documents'),
                      value: _rolePowers[role]?['editDocs'] ?? 'no',
                      items: const [
                        DropdownMenuItem(value: 'no', child: Text('No')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft Only')),
                        DropdownMenuItem(value: 'direct', child: Text('Direct Edit')),
                      ],
                      onChanged: (val) => setState(() => _rolePowers[role]!['editDocs'] = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildRoleTransitionsPage() {
    return _buildPageScaffold(
      title: 'Role Transitions & Duration',
      children: [
        const Text(
          'How do users gain roles and how long do they last?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ..._enabledRoles.where((r) => r != 'visitor').map((role) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.capitalize(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'How to gain this role'),
                  value: _roleTransitions[role]?['method'] ?? 'automatic',
                  items: const [
                    DropdownMenuItem(value: 'automatic', child: Text('Automatic (meets criteria)')),
                    DropdownMenuItem(value: 'election', child: Text('Election')),
                    DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
                    DropdownMenuItem(value: 'sortition', child: Text('Sortition (random)')),
                    DropdownMenuItem(value: 'invitation', child: Text('Invitation')),
                    DropdownMenuItem(value: 'public_vote', child: Text('Public Vote')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _roleTransitions[role] = {'method': val!};
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Role duration'),
                  value: _roleDurations[role] ?? 'permanent',
                  items: const [
                    DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                    DropdownMenuItem(value: 'fixed_term', child: Text('Fixed Term')),
                    DropdownMenuItem(value: 'conditional', child: Text('Expires if inactive')),
                    DropdownMenuItem(value: 'revocable', child: Text('Revocable')),
                  ],
                  onChanged: (val) => setState(() => _roleDurations[role] = val!),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildLawmakingSOPPage() {
    return _buildPageScaffold(
      title: 'Lawmaking Standard Operating Procedure',
      children: [
        const Text(
          'Define the detailed process for making laws',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        const Text('Proposal Types:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildCheckOption('New Law', 'new_law', _proposalTypes),
        _buildCheckOption('Law Amendment', 'amendment', _proposalTypes),
        _buildCheckOption('Law Repeal', 'repeal', _proposalTypes),
        _buildCheckOption('Constitutional Amendment', 'constitutional', _proposalTypes),
        _buildCheckOption('Emergency Action', 'emergency', _proposalTypes),
        const SizedBox(height: 24),
        ..._proposalTypes.map((type) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text('${type.replaceAll('_', ' ').capitalize()} - SOP', style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Debate Required?'),
                      value: _lawmakingSOP[type]?['debateRequired'] ?? 'optional',
                      items: const [
                        DropdownMenuItem(value: 'never', child: Text('Never')),
                        DropdownMenuItem(value: 'always', child: Text('Always')),
                        DropdownMenuItem(value: 'optional', child: Text('Optional')),
                        DropdownMenuItem(value: 'if_challenged', child: Text('Only if challenged')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _lawmakingSOP[type] = _lawmakingSOP[type] ?? {};
                          _lawmakingSOP[type]!['debateRequired'] = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Debate Format'),
                      value: _lawmakingSOP[type]?['debateFormat'] ?? 'open_discussion',
                      items: const [
                        DropdownMenuItem(value: 'time_boxed', child: Text('Time-boxed')),
                        DropdownMenuItem(value: 'argument_limited', child: Text('Argument-limited')),
                        DropdownMenuItem(value: 'open_discussion', child: Text('Open discussion')),
                        DropdownMenuItem(value: 'moderated', child: Text('Moderated')),
                        DropdownMenuItem(value: 'expert_gated', child: Text('Expert-gated')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _lawmakingSOP[type] = _lawmakingSOP[type] ?? {};
                          _lawmakingSOP[type]!['debateFormat'] = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Who Votes?'),
                      value: _lawmakingSOP[type]?['votingBody'] ?? 'eligible_voters',
                      items: const [
                        DropdownMenuItem(value: 'all_members', child: Text('All members')),
                        DropdownMenuItem(value: 'eligible_voters', child: Text('Eligible voters')),
                        DropdownMenuItem(value: 'representatives', child: Text('Representatives')),
                        DropdownMenuItem(value: 'mixed', child: Text('Mixed (public + reps)')),
                        DropdownMenuItem(value: 'random_panel', child: Text('Random panel')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _lawmakingSOP[type] = _lawmakingSOP[type] ?? {};
                          _lawmakingSOP[type]!['votingBody'] = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Voting Threshold'),
                      value: _lawmakingSOP[type]?['threshold'] ?? 'simple_majority',
                      items: const [
                        DropdownMenuItem(value: 'simple_majority', child: Text('Simple majority (>50%)')),
                        DropdownMenuItem(value: 'supermajority_66', child: Text('Supermajority (66%)')),
                        DropdownMenuItem(value: 'supermajority_75', child: Text('Supermajority (75%)')),
                        DropdownMenuItem(value: 'consensus', child: Text('Consensus (unanimous)')),
                        DropdownMenuItem(value: 'quorum_majority', child: Text('Quorum + majority')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _lawmakingSOP[type] = _lawmakingSOP[type] ?? {};
                          _lawmakingSOP[type]!['threshold'] = val!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildForkRulesPage() {
    return _buildPageScaffold(
      title: 'Fork Rules',
      children: [
        const Text(
          'When a government fork is proposed, what must happen?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Mandatory rationale required'),
          value: _forkRules['rationale_required'] ?? false,
          onChanged: (val) => setState(() => _forkRules['rationale_required'] = val),
        ),
        CheckboxListTile(
          title: const Text('Snapshot selection'),
          value: _forkRules['snapshot_selection'] ?? false,
          onChanged: (val) => setState(() => _forkRules['snapshot_selection'] = val),
        ),
        CheckboxListTile(
          title: const Text('Debate required'),
          value: _forkRules['debate_required'] ?? false,
          onChanged: (val) => setState(() => _forkRules['debate_required'] = val),
        ),
        CheckboxListTile(
          title: const Text('Public notice period'),
          value: _forkRules['notice_period'] ?? false,
          onChanged: (val) => setState(() => _forkRules['notice_period'] = val),
        ),
        CheckboxListTile(
          title: const Text('Final vote required'),
          value: _forkRules['vote_required'] ?? false,
          onChanged: (val) => setState(() => _forkRules['vote_required'] = val),
        ),
        CheckboxListTile(
          title: const Text('Immediate fork (no vote)'),
          value: _forkRules['immediate'] ?? false,
          onChanged: (val) => setState(() => _forkRules['immediate'] = val),
        ),
        CheckboxListTile(
          title: const Text('Cooling-off period'),
          value: _forkRules['cooling_off'] ?? false,
          onChanged: (val) => setState(() => _forkRules['cooling_off'] = val),
        ),
      ],
    );
  }

  Widget _buildSimulationTriggersPage() {
    return _buildPageScaffold(
      title: 'Simulation Triggers',
      children: [
        const Text(
          'When should consequence simulations run?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('After proposal submission'),
          value: _simulationTriggers['after_submission'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['after_submission'] = val),
        ),
        CheckboxListTile(
          title: const Text('After debate'),
          value: _simulationTriggers['after_debate'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['after_debate'] = val),
        ),
        CheckboxListTile(
          title: const Text('Before vote'),
          value: _simulationTriggers['before_vote'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['before_vote'] = val),
        ),
        CheckboxListTile(
          title: const Text('After passage'),
          value: _simulationTriggers['after_passage'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['after_passage'] = val),
        ),
        CheckboxListTile(
          title: const Text('On major changes only'),
          value: _simulationTriggers['major_only'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['major_only'] = val),
        ),
        const SizedBox(height: 24),
        const Text(
          'Who can trigger simulations?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Any member'),
          value: _simulationTriggers['trigger_any_member'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['trigger_any_member'] = val),
        ),
        CheckboxListTile(
          title: const Text('Contributors'),
          value: _simulationTriggers['trigger_contributors'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['trigger_contributors'] = val),
        ),
        CheckboxListTile(
          title: const Text('Representatives'),
          value: _simulationTriggers['trigger_representatives'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['trigger_representatives'] = val),
        ),
        CheckboxListTile(
          title: const Text('Moderators'),
          value: _simulationTriggers['trigger_moderators'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['trigger_moderators'] = val),
        ),
        CheckboxListTile(
          title: const Text('Automatic only'),
          value: _simulationTriggers['automatic_only'] ?? false,
          onChanged: (val) => setState(() => _simulationTriggers['automatic_only'] = val),
        ),
      ],
    );
  }

  Widget _buildEnforcementPage() {
    return _buildPageScaffold(
      title: 'Enforcement & Consequences',
      children: [
        const Text(
          'Who enforces laws?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Central authority', 'central_authority', _enforcementAuthority, (val) => setState(() => _enforcementAuthority = val!)),
        _buildRadioOption('Local authorities', 'local_authorities', _enforcementAuthority, (val) => setState(() => _enforcementAuthority = val!)),
        _buildRadioOption('Community enforcement', 'community', _enforcementAuthority, (val) => setState(() => _enforcementAuthority = val!)),
        _buildRadioOption('Automated systems', 'automated', _enforcementAuthority, (val) => setState(() => _enforcementAuthority = val!)),
        _buildRadioOption('Hybrid', 'hybrid', _enforcementAuthority, (val) => setState(() => _enforcementAuthority = val!)),
        const SizedBox(height: 24),
        const Text(
          'What consequences exist for violations?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Fines', 'fines', _consequenceTypes),
        _buildCheckOption('Loss of privileges', 'loss_privileges', _consequenceTypes),
        _buildCheckOption('Mandatory remediation', 'remediation', _consequenceTypes),
        _buildCheckOption('Detention', 'detention', _consequenceTypes),
        _buildCheckOption('Public record', 'public_record', _consequenceTypes),
        _buildCheckOption('Restorative processes', 'restorative', _consequenceTypes),
        const SizedBox(height: 24),
        const Text(
          'Is enforcement discretionary?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Always strict', 'strict', _enforcementDiscretion, (val) => setState(() => _enforcementDiscretion = val!)),
        _buildRadioOption('Context-based', 'context_based', _enforcementDiscretion, (val) => setState(() => _enforcementDiscretion = val!)),
        _buildRadioOption('Fully discretionary', 'discretionary', _enforcementDiscretion, (val) => setState(() => _enforcementDiscretion = val!)),
        _buildRadioOption('Algorithmic', 'algorithmic', _enforcementDiscretion, (val) => setState(() => _enforcementDiscretion = val!)),
      ],
    );
  }

  Widget _buildChangePage() {
    return _buildPageScaffold(
      title: 'Change & Evolution',
      children: [
        const Text(
          'Can the system be changed?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('No', 'no', _amendmentDifficulty, (val) => setState(() => _amendmentDifficulty = val!)),
        _buildRadioOption('Yes, difficult', 'difficult', _amendmentDifficulty, (val) => setState(() => _amendmentDifficulty = val!)),
        _buildRadioOption('Yes, moderate', 'moderate', _amendmentDifficulty, (val) => setState(() => _amendmentDifficulty = val!)),
        _buildRadioOption('Yes, easy', 'easy', _amendmentDifficulty, (val) => setState(() => _amendmentDifficulty = val!)),
        const SizedBox(height: 24),
        const Text(
          'What events can force change?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Public vote', 'public_vote', _changeTriggers),
        _buildCheckOption('Crisis', 'crisis', _changeTriggers),
        _buildCheckOption('Economic collapse', 'economic_collapse', _changeTriggers),
        _buildCheckOption('Corruption threshold', 'corruption', _changeTriggers),
        _buildCheckOption('Population growth', 'population_growth', _changeTriggers),
        _buildCheckOption('External pressure', 'external_pressure', _changeTriggers),
      ],
    );
  }

  Widget _buildMetricsPage() {
    return _buildPageScaffold(
      title: 'Tracked Outcomes',
      children: [
        const Text(
          'What outcomes should the system track?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Public satisfaction', 'satisfaction', _trackedOutcomes),
        _buildCheckOption('Economic health', 'economic_health', _trackedOutcomes),
        _buildCheckOption('Inequality', 'inequality', _trackedOutcomes),
        _buildCheckOption('Stability', 'stability', _trackedOutcomes),
        _buildCheckOption('Innovation', 'innovation', _trackedOutcomes),
        _buildCheckOption('Trust in institutions', 'trust', _trackedOutcomes),
        _buildCheckOption('Participation rates', 'participation', _trackedOutcomes),
        const SizedBox(height: 24),
        const Text(
          'These metrics will be used to simulate the consequences of governance decisions.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPageScaffold({required String title, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRadioOption<T>(String label, T value, T groupValue, ValueChanged<T?> onChanged) {
    return RadioListTile<T>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      dense: true,
    );
  }

  Widget _buildCheckOption(String label, String value, Set<String> selectedSet) {
    return CheckboxListTile(
      title: Text(label),
      value: selectedSet.contains(value),
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            selectedSet.add(value);
          } else {
            selectedSet.remove(value);
          }
        });
      },
      dense: true,
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${label.replaceAll('_', ' ').capitalize()}: ${(value * 100).toInt()}%',
          style: const TextStyle(fontSize: 14),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0,
          max: 1,
          divisions: 10,
          activeColor: AppColors.primaryDark,
        ),
      ],
    );
  }
}
