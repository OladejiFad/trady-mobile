import 'package:flutter/material.dart';

class RefundsWidget extends StatelessWidget {
  const RefundsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Refunds'),
        subtitle: Text('Handle refund requests here.'),
      ),
    );
  }
}
