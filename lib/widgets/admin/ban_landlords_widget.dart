import 'package:flutter/material.dart';
import '../../models/land_lord_model.dart';
import '../../services/admin_service.dart';

class BanLandlordsWidget extends StatefulWidget {
  const BanLandlordsWidget({super.key});

  @override
  State<BanLandlordsWidget> createState() => _BanLandlordsWidgetState();
}

class _BanLandlordsWidgetState extends State<BanLandlordsWidget> {
  late Future<List<LandlordModel>> _landlords;

  @override
  void initState() {
    super.initState();
    _loadLandlords();
  }

  void _loadLandlords() {
    _landlords = AdminService.getApprovedLandlords(); 
  }
  
  Future<void> _toggleBan(String id, bool isBanned) async {
    final success = isBanned
        ? await AdminService.unbanLandlord(id)
        : await AdminService.banLandlord(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isBanned ? 'Landlord unbanned' : 'Landlord banned'),
      ));
      setState(_loadLandlords);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LandlordModel>>(
      future: _landlords,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final landlords = snapshot.data ?? [];
        if (landlords.isEmpty) {
          return const Center(child: Text('No landlords found.'));
        }

        return ListView.builder(
          itemCount: landlords.length,
          itemBuilder: (context, index) {
            final landlord = landlords[index];
            final isBanned = landlord.banned ?? false;
            return ListTile(
              title: Text(landlord.name),
              subtitle: Text(landlord.phone),
              trailing: TextButton.icon(
                icon: Icon(isBanned ? Icons.lock_open : Icons.lock),
                label: Text(isBanned ? 'Unban' : 'Ban'),
                onPressed: () => _toggleBan(landlord.id, isBanned),
              ),
            );
          },
        );
      },
    );
  }
}
