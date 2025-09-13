import 'package:flutter/material.dart';
import '../../models/property_model.dart';
import '../../services/admin_property_service.dart';

class AdminPendingPropertiesScreen extends StatefulWidget {
  const AdminPendingPropertiesScreen({Key? key}) : super(key: key);

  @override
  State<AdminPendingPropertiesScreen> createState() => _AdminPendingPropertiesScreenState();
}

class _AdminPendingPropertiesScreenState extends State<AdminPendingPropertiesScreen> {
  final AdminPropertyService _service = AdminPropertyService();
  late Future<List<Property>> _pendingPropertiesFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingProperties();
  }

  void _loadPendingProperties() {
    setState(() {
      _pendingPropertiesFuture = _service.fetchPendingProperties();
    });
  }

  Future<void> _approveProperty(String propertyId) async {
    try {
      await _service.approveProperty(propertyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Property approved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadPendingProperties();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rejectProperty(String propertyId) async {
    try {
      await _service.rejectProperty(propertyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Property rejected successfully'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadPendingProperties();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Properties',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadPendingProperties,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPendingProperties(),
        child: FutureBuilder<List<Property>>(
          future: _pendingPropertiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPendingProperties,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final properties = snapshot.data ?? [];
            if (properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inbox,
                      color: Colors.grey,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pending properties',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPendingProperties,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        property.location.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Approve Property',
                          child: IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _approveProperty(property.id),
                            splashRadius: 24,
                          ),
                        ),
                        Tooltip(
                          message: 'Reject Property',
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _rejectProperty(property.id),
                            splashRadius: 24,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Optional: Add navigation to property details
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}