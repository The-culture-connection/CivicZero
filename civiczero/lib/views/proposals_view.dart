import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/services/auth_service.dart';

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
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
