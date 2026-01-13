import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/services/government_service.dart';
import 'package:civiczero/services/role_service.dart';

class ProposalsView extends StatefulWidget {
  final GovernmentModel government;

  const ProposalsView({super.key, required this.government});

  @override
  State<ProposalsView> createState() => _ProposalsViewState();
}

class _ProposalsViewState extends State<ProposalsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProposalService _proposalService = ProposalService();
  final AuthService _authService = AuthService();
  final GovernmentService _governmentService = GovernmentService();
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text('${widget.government.name} - Proposals'),
        backgroundColor: AppColors.primaryDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryLight,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Passed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProposalList(['submitted', 'debating', 'voting']),
          _buildProposalList(['passed', 'executed']),
          _buildAllProposals(),
        ],
      ),
    );
  }

  Widget _buildProposalList(List<String> statuses) {
    return StreamBuilder<List<ProposalModel>>(
      stream: _proposalService.getProposals(widget.government.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final proposals = (snapshot.data ?? [])
            .where((p) => statuses.contains(p.status))
            .toList();

        if (proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Proposals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            return _buildProposalCard(proposals[index]);
          },
        );
      },
    );
  }

  Widget _buildAllProposals() {
    return StreamBuilder<List<ProposalModel>>(
      stream: _proposalService.getProposals(widget.government.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final proposals = snapshot.data ?? [];

        if (proposals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Proposals Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text('Be the first to propose a change!'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: proposals.length,
          itemBuilder: (context, index) {
            return _buildProposalCard(proposals[index]);
          },
        );
      },
    );
  }

  Widget _buildProposalCard(ProposalModel proposal) {
    final statusColors = {
      'submitted': Colors.blue,
      'debating': Colors.orange,
      'voting': Colors.purple,
      'passed': Colors.green,
      'rejected': Colors.red,
      'executed': Colors.teal,
    };

    final statusColor = statusColors[proposal.status] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProposalDetail(proposal),
        borderRadius: BorderRadius.circular(12),
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      proposal.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: proposal.type == 'governance_change' 
                          ? Colors.red.shade50 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (proposal.type == 'governance_change')
                          Icon(Icons.shield, size: 12, color: Colors.red.shade700),
                        if (proposal.type == 'governance_change')
                          const SizedBox(width: 4),
                        Text(
                          proposal.type.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: proposal.type == 'governance_change' 
                                ? Colors.red.shade700 
                                : Colors.grey.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                proposal.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                proposal.rationale.length > 150
                    ? '${proposal.rationale.substring(0, 150)}...'
                    : proposal.rationale,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'by ${proposal.creatorUsername}', // Username for DISPLAY
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  if (proposal.status == 'voting') ...[
                    _buildVoteCount(Icons.thumb_up, proposal.votesFor, Colors.green),
                    const SizedBox(width: 12),
                    _buildVoteCount(Icons.thumb_down, proposal.votesAgainst, Colors.red),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteCount(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  void _showProposalDetail(ProposalModel proposal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(proposal.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${proposal.type.replaceAll('_', ' ')}'),
              if (proposal.category != null)
                Text('Category: ${proposal.category!.replaceAll('_', ' ')}'),
              const SizedBox(height: 8),
              Text('Status: ${proposal.status}'),
              Text('By: ${proposal.creatorUsername}'),
              const SizedBox(height: 16),
              const Text('Rationale:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(proposal.rationale),
              if (proposal.changes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Changes:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...proposal.changes.map((change) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('• ${change.op} ${change.path} = ${change.value}'),
                )).toList(),
              ],
              if (proposal.status == 'voting') ...[
                const SizedBox(height: 16),
                const Text('Votes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('For: ${proposal.votesFor}'),
                Text('Against: ${proposal.votesAgainst}'),
                Text('Abstain: ${proposal.votesAbstain}'),
                const SizedBox(height: 16),
                _buildVotingButtons(proposal),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (proposal.status == 'voting')
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showVotingSheet(proposal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
            ),
            child: const Text('Vote'),
          ),
      ],
    ),
  );
}

Widget _buildVotingButtons(ProposalModel proposal) {
  return FutureBuilder<bool>(
    future: _proposalService.hasVoted(
      widget.government.id,
      proposal.id,
      _authService.currentUser!.uid,
    ),
    builder: (context, snapshot) {
      if (snapshot.data == true) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Text('You have voted', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }

      return ElevatedButton.icon(
        onPressed: () => _showVotingSheet(proposal),
        icon: const Icon(Icons.how_to_vote),
        label: const Text('Cast Your Vote'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
        ),
      );
    },
  );
}

void _showVotingSheet(ProposalModel proposal) async {
  // Check if user can vote
  final uid = _authService.currentUser?.uid;
  if (uid == null) return;
  
  final member = await _governmentService.getMember(widget.government.id, uid);
  final canVote = _roleService.canPerform(
    member: member,
    government: widget.government,
    action: 'vote',
  );
  
  if (!canVote) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have voting permissions'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Check if already voted
  final hasVoted = await _proposalService.hasVoted(
    widget.government.id,
    proposal.id,
    uid,
  );
  
  if (hasVoted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have already voted on this proposal')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cast Your Vote',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            proposal.title,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildVoteButton('Vote For', Icons.thumb_up, Colors.green, 'for', proposal),
          const SizedBox(height: 12),
          _buildVoteButton('Vote Against', Icons.thumb_down, Colors.red, 'against', proposal),
          const SizedBox(height: 12),
          _buildVoteButton('Abstain', Icons.remove_circle_outline, Colors.grey, 'abstain', proposal),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildVoteButton(String label, IconData icon, Color color, String choice, ProposalModel proposal) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton.icon(
      onPressed: () => _castVote(proposal, choice),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

Future<void> _castVote(ProposalModel proposal, String choice) async {
  final uid = _authService.currentUser!.uid;
  final userData = await _authService.getUserData(uid);
  final username = userData?.username ?? 'Unknown';
  
  try {
    await _proposalService.castVote(
      governmentId: widget.government.id,
      proposalId: proposal.id,
      voterUid: uid, // UID = AUTHORITY
      voterUsername: username, // Username = DISPLAY
      choice: choice,
    );
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote cast: $choice'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to vote: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
}
}
