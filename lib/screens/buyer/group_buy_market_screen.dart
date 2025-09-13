import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/group_buy_model.dart';
import '../../services/group_buy_service.dart';
import '../../widgets/buyer/group_buy_card.dart';
import '../../widgets/buyer/group_buy_join_form.dart'; // <-- Import the join form dialog

class GroupBuyMarketScreen extends StatefulWidget {
  const GroupBuyMarketScreen({super.key});

  @override
  State<GroupBuyMarketScreen> createState() => _GroupBuyMarketScreenState();
}

class _GroupBuyMarketScreenState extends State<GroupBuyMarketScreen> {
  late Future<List<GroupBuy>> _groupBuysFuture;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadGroupBuys();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadGroupBuys();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadGroupBuys() {
    setState(() {
      _groupBuysFuture = GroupBuyService().fetchAllGroupBuys().then((groupBuys) {
        return groupBuys.where((gb) {
          final joined = gb.participants.fold<int>(0, (sum, p) => sum + (p.quantity ?? 1));
          final isFull = joined >= gb.minParticipants;
          return !isFull;
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 3
            : 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Buy Market'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<GroupBuy>>(
        future: _groupBuysFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final groupBuys = snapshot.data ?? [];

          if (groupBuys.isEmpty) {
            return const Center(child: Text('No group buys available.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: groupBuys.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final groupBuy = groupBuys[index];

              return GroupBuyCard(
                groupBuy: groupBuy,
                onRefresh: _loadGroupBuys,
                onJoin: () {
                  showDialog(
                    context: context,
                    builder: (_) => GroupBuyJoinForm(
                      groupBuy: groupBuy,
                      onSuccess: _loadGroupBuys,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
