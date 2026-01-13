import 'package:flutter/material.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/proposal_model.dart';
import 'package:civiczero/services/proposal_service.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/utils/string_extensions.dart';

class EventWizardView extends StatefulWidget {
  final GovernmentModel government;

  const EventWizardView({super.key, required this.government});

  @override
  State<EventWizardView> createState() => _EventWizardViewState();
}

class _EventWizardViewState extends State<EventWizardView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hostController = TextEditingController();
  final _capacityController = TextEditingController();
  final ProposalService _proposalService = ProposalService();
  final AuthService _authService = AuthService();
  
  String _eventType = 'assembly';
  DateTime _eventDateTime = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hostController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submitEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter event title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = _authService.currentUser!.uid;
      final userData = await _authService.getUserData(uid);
      final username = userData?.username ?? 'Unknown';
      final sop = widget.government.lawmakingSOP['event'] ?? {};

      final eventDetails = {
        'type': _eventType,
        'dateTime': _eventDateTime.toIso8601String(),
        'location': _locationController.text.trim(),
        'host': _hostController.text.trim(),
        'capacity': _capacityController.text.trim(),
      };

      final proposalId = await _proposalService.createProposal(
        governmentId: widget.government.id,
        creatorUid: uid,
        creatorUsername: username,
        type: 'event',
        category: _eventType,
        title: _titleController.text.trim(),
        rationale: '${_descriptionController.text.trim()}\n\nEvent Details: ${eventDetails.toString()}',
        changes: [
          ProposalChange(op: 'create', path: 'events', value: eventDetails),
        ],
        sopSnapshot: sop,
        voteDurationHours: 0, // Events auto-approve (no vote required by default)
      );

      // If no vote required, execute immediately
      if (sop['voteRequired'] != true) {
        await _proposalService.updateStatus(widget.government.id, proposalId, 'executed');
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event proposed!'), backgroundColor: Colors.green),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose Event'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Propose Community Event', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()),
              value: _eventType,
              items: const [
                DropdownMenuItem(value: 'assembly', child: Text('Assembly / Meeting')),
                DropdownMenuItem(value: 'livestream', child: Text('Livestream')),
                DropdownMenuItem(value: 'panel', child: Text('Panel Discussion')),
                DropdownMenuItem(value: 'townhall', child: Text('Town Hall')),
                DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
              ],
              onChanged: (val) => setState(() => _eventType = val!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date & Time'),
              subtitle: Text('${_eventDateTime.toString().substring(0, 16)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _eventDateTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_eventDateTime),
                  );
                  if (time != null) {
                    setState(() {
                      _eventDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location / Link', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Host / Organizer', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 80),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitEvent,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
