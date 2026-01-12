import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';

class GovernmentsView extends StatefulWidget {
  const GovernmentsView({super.key});

  @override
  State<GovernmentsView> createState() => _GovernmentsViewState();
}

class _GovernmentsViewState extends State<GovernmentsView> {
  final List<Map<String, dynamic>> _governments = [
    {
      'name': 'City Council',
      'location': 'Downtown',
      'members': 12,
      'nextMeeting': 'Jan 15, 2026',
    },
    {
      'name': 'State Legislature',
      'location': 'State Capitol',
      'members': 150,
      'nextMeeting': 'Jan 20, 2026',
    },
    {
      'name': 'County Board',
      'location': 'County Building',
      'members': 8,
      'nextMeeting': 'Jan 18, 2026',
    },
    {
      'name': 'School Board',
      'location': 'Education Center',
      'members': 7,
      'nextMeeting': 'Jan 22, 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Governments'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search governments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Government List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _governments.length,
              itemBuilder: (context, index) {
                final gov = _governments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Navigate to government details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Viewing ${gov['name']}'),
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
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gov['name'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gov['location'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoChip(
                                icon: Icons.people,
                                label: '${gov['members']} Members',
                              ),
                              const SizedBox(width: 16),
                              _buildInfoChip(
                                icon: Icons.event,
                                label: gov['nextMeeting'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new government
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add new government'),
            ),
          );
        },
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.add, color: AppColors.primaryLight),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
