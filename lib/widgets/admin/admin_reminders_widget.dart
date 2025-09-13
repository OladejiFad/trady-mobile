import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reminder_model.dart';
import '../../services/admin_service.dart';
import '../../global/admin_auth_data.dart';

class AdminRemindersWidget extends StatefulWidget {
  const AdminRemindersWidget({super.key});

  @override
  State<AdminRemindersWidget> createState() => _AdminRemindersWidgetState();
}

class _AdminRemindersWidgetState extends State<AdminRemindersWidget> {
  late Future<List<Reminder>> _remindersFuture;
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
  }

  void _fetchReminders() {
    setState(() {
      _remindersFuture = AdminService.getReminders();
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addReminder() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter message and select date/time')),
      );
      return;
    }

    final token = AdminAuthData.token;

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No auth token found. Please log in again.')),
      );
      return;
    }

    final success = await AdminService.createReminder(
      message,
      _selectedDateTime!.toIso8601String(),
    );

    if (success) {
      _controller.clear();
      _selectedDateTime = null;
      _fetchReminders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create reminder')),
      );
    }
  }

  Future<void> _deleteReminder(String id) async {
    final token = AdminAuthData.token;

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No auth token found. Please log in again.')),
      );
      return;
    }

    final success = await AdminService.deleteReminder(id);
    if (success) {
      _fetchReminders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete reminder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'New Reminder',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addReminder,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateTime == null
                          ? 'No date/time selected'
                          : 'Scheduled: ${DateFormat('yyyy-MM-dd – hh:mm a').format(_selectedDateTime!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: const Text('Pick', style: TextStyle(fontSize: 12)),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Reminder>>(
            future: _remindersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final reminders = snapshot.data ?? [];
              if (reminders.isEmpty) {
                return const Center(child: Text('No reminders available'));
              }

              return ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: Text(reminder.message),
                    subtitle: Text('Created: ${DateFormat('yyyy-MM-dd – hh:mm a').format(reminder.createdAt.toLocal())}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReminder(reminder.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
