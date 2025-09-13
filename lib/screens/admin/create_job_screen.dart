import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/job_service.dart';
import '../../global/admin_auth_data.dart'; // ✅ IMPORTANT: Include this

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  String _jobType = 'Part-Time';
  DateTime? _deadline;
  bool _submitting = false;

  final _jobTypes = ['Part-Time', 'Full-Time', 'Remote'];

  void _submit() async {
    if (!_formKey.currentState!.validate() || _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // 🔐 Ensure token is loaded
    await AdminAuthData.load();
    print('🔐 Token being used: ${AdminAuthData.token}'); // Optional debug

    setState(() => _submitting = true);

    try {
      await JobService().createAdminJob(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _jobType,
        deadline: _deadline!,
        email: _emailController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job created successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create BuyNest Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Job Title'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Job Description'),
              maxLines: 3,
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Job Location'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
             controller: _emailController,
             decoration: const InputDecoration(labelText: 'Application Email'),
             keyboardType: TextInputType.emailAddress,
             validator: (value) =>
               value!.isEmpty || !value.contains('@') ? 'Valid email required' : null,
            ),
            DropdownButtonFormField<String>(
              value: _jobType,
              items: _jobTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (val) => setState(() => _jobType = val!),
              decoration: const InputDecoration(labelText: 'Job Type'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_deadline == null
                  ? 'Select Deadline'
                  : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _deadline = picked);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const CircularProgressIndicator()
                  : const Text('Post Job'),
            ),
          ]),
        ),
      ),
    );
  }
}
