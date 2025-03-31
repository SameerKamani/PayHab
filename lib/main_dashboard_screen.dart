import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'vendor_detail_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String userId;
  final String idToken;

  const MainDashboardScreen({Key? key, required this.userId, required this.idToken})
      : super(key: key);

  @override
  _MainDashboardScreenState createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  late Future _initialData;
  String _userName = 'User';
  List<Map<String, dynamic>> vendors = [
    {"name": "Tapal", "balance": 0},
    {"name": "Rahim Bhai fries", "balance": 0},
    {"name": "Cafe2Go", "balance": 0},
    {"name": "SkyDhaba", "balance": 0},
    {"name": "Grito", "balance": 0},
  ];
  final String _baseUrl = 'http://10.0.2.2:5000';
  double _logoOpacity = 0.0;
  Timer? _tokenTimer;
  Timer? _userTimer;
  Timer? _loanTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload the logo image.
    precacheImage(const AssetImage('assets/payhab_logo.jpeg'), context);
  }

  @override
  void initState() {
    super.initState();
    _initialData = _loadInitialData();
    _startTokenCheck();
    _startUserDataListener();
    // Update vendor loans every 5 seconds.
    _loanTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateVendorLoans();
    });
    // Animate logo fade-in.
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _logoOpacity = 1.0;
      });
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchUserName(), _updateVendorLoans()]);
  }

  Future<void> _fetchUserName() async {
    final url = Uri.parse('$_baseUrl/user/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userName = data["data"]["name"] ?? 'User';
        });
      } else {
        debugPrint("Error fetching user: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception fetching user: $e");
    }
  }

  Future<void> _updateVendorLoans() async {
    for (var vendor in vendors) {
      final vendorName = vendor["name"];
      final url = Uri.parse('$_baseUrl/loans/get?userId=${widget.userId}&vendor=$vendorName');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          vendor["balance"] = data["amount"] ?? 0;
        } else {
          debugPrint("Error fetching loan for $vendorName: ${response.body}");
        }
      } catch (e) {
        debugPrint("Exception fetching loan for $vendorName: $e");
      }
    }
    // Sort vendors by balance descending.
    setState(() {
      vendors.sort((a, b) => (b['balance'] as int).compareTo(a['balance'] as int));
    });
  }

  /// Returns a color based on the balance value.
  /// 0-50: Green; 50-200: Green to Yellow gradient; 200+: Yellow to Red gradient.
  Color getBalanceColor(int balance) {
    if (balance <= 50) {
      return Colors.green;
    } else if (balance < 200) {
      double t = (balance - 50) / (200 - 50);
      return Color.lerp(Colors.green, Colors.yellow, t)!;
    } else {
      double t = (balance - 200) / 300; // Using 300 as an arbitrary max range.
      t = t.clamp(0.0, 1.0);
      return Color.lerp(Colors.yellow, Colors.red, t)!;
    }
  }

  void _startTokenCheck() {
    _tokenTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final url = Uri.parse('$_baseUrl/verify-token');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"idToken": widget.idToken}),
      );
      if (response.statusCode != 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('idToken');
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
        timer.cancel();
        _userTimer?.cancel();
        _loanTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    });
  }

  void _startUserDataListener() {
    _userTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchUserName();
    });
  }

  Future<void> _clearSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('idToken');
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.setBool('rememberMe', false);
  }

  @override
  void dispose() {
    _tokenTimer?.cancel();
    _userTimer?.cancel();
    _loanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
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
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Custom top row with logout button.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await _clearSavedCredentials();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                    // Animated logo.
                    Center(
                      child: AnimatedOpacity(
                        opacity: _logoOpacity,
                        duration: const Duration(milliseconds: 800),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundImage: const AssetImage('assets/payhab_logo.jpeg'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Greeting text.
                    Center(
                      child: Text(
                        "Welcome $_userName",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white, fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Vendor cards with AnimatedSwitcher.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(vendors.hashCode),
                        children: vendors.map((vendor) {
                          final int balance = vendor['balance'] as int;
                          final String displayBalance = "$balance RS";
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VendorDetailScreen(
                                    userId: widget.userId,
                                    idToken: widget.idToken,
                                    vendorName: vendor['name'],
                                    vendorImage: 'assets/${vendor['name'].toLowerCase().replaceAll(' ', '_')}.jpeg',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  // Replace the placeholder icon with the actual vendor image.
                                  Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/${vendor['name'].toLowerCase().replaceAll(' ', '_')}.jpeg',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            vendor['name'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            displayBalance,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: getBalanceColor(balance),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
