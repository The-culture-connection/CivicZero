import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/auth_service.dart';

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
  final int _totalPages = 9; // 0-8 sections
  bool _isLoading = false;

  // Form data
  final _nameController = TextEditingController();
  
  // Section 0: Scope
  String _scope = 'local';
  
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
  
  // Section 4: Representation & Elections
  String _representationModel = 'elected_representatives';
  final Set<String> _votingEligibility = {};
  final Set<String> _officeEligibility = {};
  String _electionMethod = 'majority_vote';
  final _termLengthController = TextEditingController();
  bool _termLimits = false;
  
  // Section 5: Lawmaking
  final Set<String> _lawProposers = {};
  String _passageRules = 'simple_majority';
  final Set<String> _reviewMechanisms = {};
  
  // Section 6: Enforcement
  String _enforcementAuthority = 'central_authority';
  final Set<String> _consequenceTypes = {};
  String _enforcementDiscretion = 'context_based';
  
  // Section 7: Change & Evolution
  String _amendmentDifficulty = 'moderate';
  final Set<String> _changeTriggers = {};
  
  // Section 8: Metrics
  final Set<String> _trackedOutcomes = {};

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _preambleController.dispose();
    _termLengthController.dispose();
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
        scope: _scope,
        purpose: _purposes.toList(),
        principles: _principles,
        preambleMode: _preambleMode,
        preambleText: preambleText,
        rightsCategories: _rightsCategories.toList(),
        rightsLimits: _rightsLimits.toList(),
        citizenObligations: _obligations.toList(),
        branches: _branches.toList(),
        checksAndBalances: _checksAndBalances,
        representationModel: _representationModel,
        votingEligibility: _votingEligibility.toList(),
        officeEligibility: _officeEligibility.toList(),
        electionMethod: _electionMethod,
        termLength: _termLengthController.text.trim(),
        termLimits: _termLimits,
        lawProposers: _lawProposers.toList(),
        passageRules: _passageRules,
        reviewMechanisms: _reviewMechanisms.toList(),
        enforcementAuthority: _enforcementAuthority,
        consequenceTypes: _consequenceTypes.toList(),
        enforcementDiscretion: _enforcementDiscretion,
        amendmentDifficulty: _amendmentDifficulty,
        changeTriggers: _changeTriggers.toList(),
        metrics: {
          'trust': 0.5,
          'stability': 0.5,
          'participation': 0.5,
          'satisfaction': 0.5,
          'economic_health': 0.5,
        },
        trackedOutcomes: _trackedOutcomes.toList(),
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
                _buildPurposePage(),
                _buildRightsPage(),
                _buildStructurePage(),
                _buildRepresentationPage(),
                _buildLawmakingPage(),
                _buildEnforcementPage(),
                _buildChangePage(),
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

  Widget _buildRepresentationPage() {
    return _buildPageScaffold(
      title: 'Representation & Elections',
      children: [
        const Text(
          'How are people represented?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Direct participation (everyone votes on laws)', 'direct', _representationModel, (val) => setState(() => _representationModel = val!)),
        _buildRadioOption('Elected representatives', 'elected_representatives', _representationModel, (val) => setState(() => _representationModel = val!)),
        _buildRadioOption('Mixed (delegates + direct votes)', 'mixed', _representationModel, (val) => setState(() => _representationModel = val!)),
        const SizedBox(height: 24),
        const Text(
          'Who can vote?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('All members', 'all_members', _votingEligibility),
        _buildCheckOption('Age-restricted', 'age_restricted', _votingEligibility),
        _buildCheckOption('Contribution-based', 'contribution_based', _votingEligibility),
        _buildCheckOption('Residency-based', 'residency_based', _votingEligibility),
        const SizedBox(height: 24),
        const Text(
          'Who can run for office?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('All members', 'all_members', _officeEligibility),
        _buildCheckOption('Age-restricted', 'age_restricted', _officeEligibility),
        _buildCheckOption('Contribution-based', 'contribution_based', _officeEligibility),
        _buildCheckOption('Residency-based', 'residency_based', _officeEligibility),
        const SizedBox(height: 24),
        const Text(
          'How are representatives selected?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Majority vote', 'majority_vote', _electionMethod, (val) => setState(() => _electionMethod = val!)),
        _buildRadioOption('Ranked choice', 'ranked_choice', _electionMethod, (val) => setState(() => _electionMethod = val!)),
        _buildRadioOption('Proportional representation', 'proportional', _electionMethod, (val) => setState(() => _electionMethod = val!)),
        _buildRadioOption('Random selection (sortition)', 'sortition', _electionMethod, (val) => setState(() => _electionMethod = val!)),
        _buildRadioOption('Appointment', 'appointment', _electionMethod, (val) => setState(() => _electionMethod = val!)),
        const SizedBox(height: 24),
        TextField(
          controller: _termLengthController,
          decoration: const InputDecoration(
            labelText: 'Term Length',
            border: OutlineInputBorder(),
            hintText: 'e.g., 4 years, indefinite, etc.',
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Enforce term limits'),
          value: _termLimits,
          onChanged: (val) => setState(() => _termLimits = val ?? false),
        ),
      ],
    );
  }

  Widget _buildLawmakingPage() {
    return _buildPageScaffold(
      title: 'Lawmaking Process',
      children: [
        const Text(
          'Who can propose laws?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('Any member', 'any_member', _lawProposers),
        _buildCheckOption('Representatives only', 'representatives', _lawProposers),
        _buildCheckOption('Executive only', 'executive', _lawProposers),
        _buildCheckOption('Committees', 'committees', _lawProposers),
        _buildCheckOption('Threshold-based (signatures)', 'threshold', _lawProposers),
        const SizedBox(height: 24),
        const Text(
          'What is required for a law to pass?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildRadioOption('Simple majority', 'simple_majority', _passageRules, (val) => setState(() => _passageRules = val!)),
        _buildRadioOption('Supermajority', 'supermajority', _passageRules, (val) => setState(() => _passageRules = val!)),
        _buildRadioOption('Multiple approvals (branches)', 'multiple_approvals', _passageRules, (val) => setState(() => _passageRules = val!)),
        _buildRadioOption('Public referendum', 'public_referendum', _passageRules, (val) => setState(() => _passageRules = val!)),
        const SizedBox(height: 24),
        const Text(
          'Can laws be reviewed or blocked?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildCheckOption('No', 'no', _reviewMechanisms),
        _buildCheckOption('By courts', 'courts', _reviewMechanisms),
        _buildCheckOption('By executive', 'executive', _reviewMechanisms),
        _buildCheckOption('By public vote', 'public_vote', _reviewMechanisms),
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
