import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import '../../global/auth_data.dart';
import 'package:intl/intl.dart';

class SellerComplaintsScreen extends StatefulWidget {
  const SellerComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<SellerComplaintsScreen> createState() => _SellerComplaintsScreenState();
}

class _SellerComplaintsScreenState extends State<SellerComplaintsScreen> {
  List<Complaint> complaints = [];
  bool isLoading = false;
  String? errorMessage;

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedComplaints = await ComplaintService.getComplaintsByUser(AuthData.sellerId);
      setState(() {
        complaints = fetchedComplaints;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load complaints: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitComplaint() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ComplaintService.createComplaint(
        token: AuthData.token,
        subject: subject,
        description: description,
        sellerId: AuthData.sellerId,
      );
      _subjectController.clear();
      _descriptionController.clear();
      await _loadComplaints();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to submit complaint: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildComplaintCard(Complaint c) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('📢 ${c.subject}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.description),
            if (c.response.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('💬 Admin response: ${c.response}', style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 4),
            Text(
              '📅 ${DateFormat.yMMMd().add_jm().format(c.createdAt?.toLocal() ?? DateTime.now())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : complaints.isEmpty
                          ? const Center(child: Text('No complaints found.'))
                          : ListView.builder(
                              itemCount: complaints.length,
                              itemBuilder: (context, index) => _buildComplaintCard(complaints[index]),
                            ),
            ),
            const Divider(),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isLoading ? null : _submitComplaint,
              child: const Text('Submit Complaint'),
            ),
          ],
        ),
      ),
    );
  }
}
