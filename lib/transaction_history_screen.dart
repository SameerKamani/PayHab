import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransactionHistoryScreen extends StatefulWidget {
  final String userId;

  const TransactionHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> transactions = [];
  final String _baseUrl = 'http://10.0.2.2:5000';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final url = Uri.parse('$_baseUrl/transactions/recent/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          transactions = List<Map<String, dynamic>>.from(data["transactions"]);
        });
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final String vendorName = transaction['vendor'] ?? 'Unknown';
          final int amount = transaction['amount'] ?? 0;
          final String type = transaction['type'] ?? 'loan_add';

          final bool isAdd = type == 'loan_add';
          final String message = isAdd
              ? "You added $amount to $vendorName RS"
              : "You cleared $amount from $vendorName RS";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isAdd ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isAdd ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isAdd ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
