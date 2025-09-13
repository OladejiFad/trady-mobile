import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../global/auth_data.dart'; // for AuthData.token

class TransactionService {
  static const String baseUrl = 'http://172.20.10.2:5000/api/transactions';

  Future<List<Transaction>> fetchTransactions() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer ${AuthData.token}', // add auth header
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch transactions: ${response.statusCode}');
    }
  }
}
