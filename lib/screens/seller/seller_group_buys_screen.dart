import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/group_buy_service.dart';
import '../../models/group_buy_model.dart';

class SellerGroupBuysScreen extends StatefulWidget {
  const SellerGroupBuysScreen({super.key});

  @override
  State<SellerGroupBuysScreen> createState() => _SellerGroupBuysScreenState();
}

class _SellerGroupBuysScreenState extends State<SellerGroupBuysScreen> {
  late Future<List<GroupBuy>> _groupBuysFuture;

  @override
  void initState() {
    super.initState();
    _refreshGroupBuys();
  }

  void _refreshGroupBuys() {
    setState(() {
      _groupBuysFuture = GroupBuyService().fetchSellerGroupBuys();
    });
  }

  void _deleteGroupBuy(String id) async {
    await GroupBuyService().deleteGroupBuy(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group buy deleted')));
    _refreshGroupBuys();
  }

  void _toggleVisibility(String id, bool visible) async {
    await GroupBuyService().toggleGroupBuyVisibility(id, visible);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(visible ? 'Group buy is now visible' : 'Group buy is now hidden'),
    ));
    _refreshGroupBuys();
  }

  void _editGroupBuy(GroupBuy groupBuy) {
    // Optional: Navigate to an edit screen and prefill form
    // Navigator.push(context, MaterialPageRoute(builder: (_) => EditGroupBuyScreen(groupBuy: groupBuy)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Group Buys')),
      body: FutureBuilder<List<GroupBuy>>(
        future: _groupBuysFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final groupBuys = snapshot.data!;
          if (groupBuys.isEmpty) return const Center(child: Text('No group buys created yet'));

          return ListView.builder(
            itemCount: groupBuys.length,
            itemBuilder: (context, index) {
              final gb = groupBuys[index];
              final isExpired = DateTime.now().isAfter(gb.deadline);
              final dateFmt = DateFormat('MMM d, yyyy');

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(gb.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: gb.visible ? Colors.green[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          gb.visible ? 'Visible' : 'Hidden',
                          style: TextStyle(
                            color: gb.visible ? Colors.green[800] : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text('₦${gb.pricePerUnit.toStringAsFixed(2)}'),
                          Text('Min: ${gb.minParticipants}'),
                          Text('Joined: ${gb.joinedQuantity}'),
                          Text('Participants: ${gb.joinedQuantity}'),
                          Text(
                            isExpired ? 'Expired: ${dateFmt.format(gb.deadline)}' : 'Deadline: ${dateFmt.format(gb.deadline)}',
                            style: TextStyle(color: isExpired ? Colors.red : Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editGroupBuy(gb);
                      if (value == 'delete') _deleteGroupBuy(gb.id);
                      if (value == 'toggle') _toggleVisibility(gb.id, !gb.visible);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(gb.visible ? 'Hide from buyers' : 'Show to buyers'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
