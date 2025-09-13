import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';

class AdminComplaintsWidget extends StatefulWidget {
  final String adminToken;

  const AdminComplaintsWidget({super.key, required this.adminToken});

  @override
  State<AdminComplaintsWidget> createState() => _AdminComplaintsWidgetState();
}

class _AdminComplaintsWidgetState extends State<AdminComplaintsWidget> {
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  void _loadComplaints() {
    setState(() {
      _complaintsFuture = ComplaintService.fetchAllComplaints(widget.adminToken);
    });
  }

  void _resolveComplaint(String id) async {
    final TextEditingController controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Complaint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Response message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        await ComplaintService.resolveComplaint(
          widget.adminToken,
          id,
          controller.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint resolved')),
        );
        _loadComplaints(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response message cannot be empty')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Complaint>>(
      future: _complaintsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading complaints: ${snapshot.error}'));
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return const Center(child: Text('No complaints found.'));
        }

        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ListTile(
                title: Text(complaint.subject),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User ID: ${complaint.userId}'), // Display userId as string
                    Text('Description: ${complaint.description}'),
                    if (complaint.status == 'resolved')
                      Text('🟢 Resolved: ${complaint.response}'),
                  ],
                ),
                trailing: complaint.status == 'pending'
                    ? ElevatedButton(
                        onPressed: () => _resolveComplaint(complaint.id),
                        child: const Text('Resolve'),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}