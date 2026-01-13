import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/role_service.dart';
import 'package:civiczero/constants/proposal_constants.dart';
import 'package:civiczero/utils/string_extensions.dart';

/// Shared Proposal Detail View with status timeline
class ProposalDetailView extends StatefulWidget {
  final GovernmentModel government;
  final ProposalModel proposal;

  const ProposalDetailView({
    super.key,
    required this.government,
    required this.proposal,
  });

  @override
  State<ProposalDetailView> createState() => _ProposalDetailViewState();
}

class _ProposalDetailViewState extends State<ProposalDetailView> {
  final ProposalService _proposalService = ProposalService();
  final AuthService _authService = AuthService();
  final GovernmentService _governmentService = GovernmentService();
  final RoleService _roleService = RoleService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Details'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: _getTypeColor().withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ProposalType.isConstitutional(widget.proposal.type))
                              const Icon(Icons.shield, size: 14, color: Colors.white),
                            if (ProposalType.isConstitutional(widget.proposal.type))
                              const SizedBox(width: 4),
                            Text(
                              ProposalType.getDisplayName(widget.proposal.type).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ProposalStatus.getDisplayName(widget.proposal.status).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.proposal.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${widget.proposal.creatorUsername}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Status Timeline
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Timeline',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTimelineStep('Created', widget.proposal.createdAt, true),
                      _buildTimelineStep('Submitted', widget.proposal.createdAt, _isStatusReached(ProposalStatus.submitted)),
                      if (widget.proposal.sopSnapshot['debateRequired'] != 'never')
                        _buildTimelineStep('Debating', null, _isStatusReached(ProposalStatus.debating)),
                      if (widget.proposal.sopSnapshot['voteRequired'] == true)
                        _buildTimelineStep('Voting', widget.proposal.votingStarted, _isStatusReached(ProposalStatus.voting)),
                      _buildTimelineStep('Result', null, _isStatusReached(ProposalStatus.passed) || _isStatusReached(ProposalStatus.rejected)),
                      _buildTimelineStep('Executed', widget.proposal.executedAt, _isStatusReached(ProposalStatus.executed)),
                    ],
                  ),
                ),
              ),
            ),
            // Rationale
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rationale',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(widget.proposal.rationale),
                    ],
                  ),
                ),
              ),
            ),
            // Changes (if any)
            if (widget.proposal.changes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Proposed Changes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...widget.proposal.changes.map((change) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                change.op == 'set' ? Icons.edit : 
                                change.op == 'add' ? Icons.add : Icons.remove,
                                size: 16,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${change.op} ${change.path} = ${change.value}'),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            // Voting (if in voting status)
            if (widget.proposal.status == ProposalStatus.voting)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vote',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildVoteCount('For', widget.proposal.votesFor, Colors.green),
                            _buildVoteCount('Against', widget.proposal.votesAgainst, Colors.red),
                            _buildVoteCount('Abstain', widget.proposal.votesAbstain, Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildVoteButton(),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String label, DateTime? timestamp, bool reached) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.radio_button_unchecked,
            color: reached ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                    color: reached ? Colors.black : Colors.grey,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    timestamp.toString().substring(0, 16),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isStatusReached(String checkStatus) {
    final statuses = [
      ProposalStatus.draft,
      ProposalStatus.submitted,
      ProposalStatus.debating,
      ProposalStatus.voting,
      ProposalStatus.passed,
      ProposalStatus.rejected,
      ProposalStatus.executed,
    ];

    final currentIndex = statuses.indexOf(widget.proposal.status);
    final checkIndex = statuses.indexOf(checkStatus);

    return currentIndex >= checkIndex;
  }

  Widget _buildVoteCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildVoteButton() {
    return FutureBuilder<bool>(
      future: _proposalService.hasVoted(
        widget.government.id,
        widget.proposal.id,
        _authService.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('You have voted', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ElevatedButton(
          onPressed: () {
            // Open voting sheet (reuse from proposals_view)
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Cast Your Vote'),
        );
      },
    );
  }

  Color _getTypeColor() {
    if (ProposalType.isConstitutional(widget.proposal.type)) {
      return Colors.red;
    }
    switch (widget.proposal.type) {
      case ProposalType.newLaw:
        return Colors.blue;
      case ProposalType.event:
        return Colors.green;
      case ProposalType.fork:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (widget.proposal.status) {
      case ProposalStatus.voting:
        return Colors.purple;
      case ProposalStatus.passed:
        return Colors.green;
      case ProposalStatus.rejected:
        return Colors.red;
      case ProposalStatus.executed:
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }
}
