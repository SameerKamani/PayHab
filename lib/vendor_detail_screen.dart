import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VendorDetailScreen extends StatefulWidget {
  final String userId;
  final String idToken;
  final String vendorName;
  final String vendorImage; // Path to vendor image asset

  const VendorDetailScreen({
    Key? key,
    required this.userId,
    required this.idToken,
    required this.vendorName,
    this.vendorImage = 'assets/default_vendor.png',
  }) : super(key: key);

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  int _currentLoan = 0;
  final String _baseUrl = 'http://10.0.2.2:5000';
  double _imageOpacity = 0.0;

  String? _amountError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload vendor image.
    precacheImage(AssetImage(widget.vendorImage), context);
  }

  @override
  void initState() {
    super.initState();
    _fetchLoanAmount();
    _amountController.addListener(_validateAmount);
    // Animate vendor image fade-in.
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _imageOpacity = 1.0;
      });
    });
  }

  void _validateAmount() {
    final text = _amountController.text;
    if (text.isNotEmpty) {
      final value = int.tryParse(text);
      if (value != null && value > 2000) {
        setState(() {
          _amountError = "Amount cannot exceed 2000";
        });
      } else {
        setState(() {
          _amountError = null;
        });
      }
    } else {
      setState(() {
        _amountError = null;
      });
    }
  }

  Future<void> _fetchLoanAmount() async {
    final url = Uri.parse(
      '$_baseUrl/loans/get?userId=${widget.userId}&vendor=${widget.vendorName}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentLoan = data["amount"] ?? 0;
        });
      } else {
        debugPrint("Error fetching loan: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception fetching loan: $e");
    }
  }

  Future<void> _addLoan() async {
    final int? amount = int.tryParse(_amountController.text);
    if (amount == null || amount > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount (max 2000)."),
        ),
      );
      return;
    } else if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a positive amount.")),
      );
      return;
    }
    final url = Uri.parse('$_baseUrl/loans/add');
    final body = json.encode({
      "userId": widget.userId,
      "vendor": widget.vendorName,
      "amount": amount,
    });
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentLoan = data["newAmount"] ?? _currentLoan;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Loan dues Rs. $amount added successfully.")),
        );
        // Return a result indicating an update.
        Navigator.pop(context, true);
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Error adding loan")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

  Future<void> _clearLoan() async {
    final String inputText = _amountController.text.trim();
    final int? amountToClear = int.tryParse(inputText);
    if (inputText.isEmpty || amountToClear == null || amountToClear <= 0) {
      setState(() {
        _amountError = "Please enter a valid positive amount.";
      });
      return;
    }
    if (_currentLoan == 0) {
      setState(() {
        _amountError = "Error: Loan data not available or already cleared.";
      });
      return;
    }
    if (amountToClear > _currentLoan) {
      setState(() {
        _amountError =
            "You owe only Rs. $_currentLoan, \nPlease enter a valid amount.";
      });
      return;
    }
    final url = Uri.parse('$_baseUrl/loans/clear');
    final body = json.encode({
      "userId": widget.userId,
      "vendor": widget.vendorName,
      "amount": amountToClear,
    });
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newLoanAmount = data["newAmount"] ?? _currentLoan;
        setState(() {
          _currentLoan = newLoanAmount;
          _amountError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Loan dues Rs. $amountToClear cleared successfully."),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context, true);
        });
      } else {
        debugPrint("Error clearing loan: ${response.body}");
        setState(() {
          _amountError = "Failed to clear loan. Try again.";
        });
      }
    } catch (e) {
      debugPrint("Exception clearing loan: $e");
      setState(() {
        _amountError = "Network error. Please check your connection.";
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    Card(
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedOpacity(
                              opacity: _imageOpacity,
                              duration: const Duration(milliseconds: 800),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  widget.vendorImage,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                widget.vendorName,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Colors.black87,
                                  fontSize: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Text(
                                "Loan due: $_currentLoan RS",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 22),
                              decoration: InputDecoration(
                                labelText: "Enter amount (max 2000)",
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.all(20),
                                errorText: _amountError,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _addLoan,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                    ),
                                    child: const Text(
                                      "Add Loan",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _clearLoan,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                    ),
                                    child: const Text(
                                      "Clear Dues",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
