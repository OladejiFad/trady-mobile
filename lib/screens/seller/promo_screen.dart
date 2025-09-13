import 'package:flutter/material.dart';
import '../../models/promo_model.dart';
import '../../services/promo_service.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  List<Promo> promos = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  String code = '';
  String discountType = 'percentage';
  String discountValue = '';
  DateTime? expiresAt;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    try {
      final data = await PromoService.fetchSellerPromosForSelf();
      setState(() {
        promos = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _createPromo() async {
    if (_formKey.currentState?.validate() != true || expiresAt == null) return;
    _formKey.currentState?.save();
    try {
      await PromoService.createPromo({
        'code': code,
        'discountType': discountType,
        'discountValue': double.parse(discountValue),
        'expiresAt': expiresAt!.toIso8601String(),
      });
      Navigator.pop(context);
      _loadPromos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Promo'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Promo Code'),
                  onSaved: (val) => code = val!.trim(),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: discountType,
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                  ],
                  onChanged: (val) => setState(() => discountType = val!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Discount Value'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => discountValue = val!,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => expiresAt = date);
                    }
                  },
                  child: Text(expiresAt == null ? 'Select Expiry Date' : 'Change Expiry Date'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _createPromo, child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _deletePromo(String id) async {
    try {
      await PromoService.deletePromo(id);
      _loadPromos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Promo Codes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : promos.isEmpty
              ? const Center(child: Text('No promos yet'))
              : ListView.builder(
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    return ListTile(
                      title: Text(promo.code),
                      subtitle: Text(
                        '${promo.discountType == 'percentage' ? '${promo.discountValue}%' : '₦${promo.discountValue}'} - expires: ${promo.expiresAt.toLocal().toString().split(' ')[0]}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePromo(promo.id),
                      ),
                    );
                  },
                ),
    );
  }
}
