import 'package:flutter/material.dart';
import '../../global/auth_data.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  late Future<List<Transaction>> _futureTransactions;

 @override
void initState() {
  super.initState();
  _futureTransactions = TransactionService().fetchTransactions();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: FutureBuilder<List<Transaction>>(
        future: _futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final transactions = snapshot.data ?? [];
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                title: Text('Amount: \$${tx.amount.toStringAsFixed(2)}'),
                subtitle: Text('Status: ${tx.status}'),
                trailing: Text(tx.transactionDate.toLocal().toString().split(' ')[0]),
              );
            },
          );
        },
      ),
    );
  }
}
