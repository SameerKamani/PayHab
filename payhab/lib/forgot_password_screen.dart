import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;
  double _headerOpacity = 0.0;

  // Base URL for your Flask server.
  final String _baseUrl = 'http://10.0.2.2:5000';

  // Regex for email validation.
  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  String? _emailError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload assets if needed.
    precacheImage(const AssetImage('assets/payhab_logo.jpeg'), context);
  }

  @override
  void initState() {
    super.initState();
    // Listen for email changes to provide real-time validation.
    _emailController.addListener(_validateEmail);
    // Animate the header fade-in.
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _headerOpacity = 1.0;
      });
    });
    // Request focus on the email field after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocus);
    });
  }

  void _validateEmail() {
    final text = _emailController.text;
    setState(() {
      if (text.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!emailRegex.hasMatch(text)) {
        _emailError = 'Invalid email format';
      } else {
        _emailError = null;
      }
    });
  }
  
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate() || _emailError != null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final url = Uri.parse("$_baseUrl/forgot-password");
    final body = json.encode({
      "email": _emailController.text.trim(),
    });
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent. Please check your inbox."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        });
      } else {
        final responseData = json.decode(response.body);
        String errorMessage = responseData["error"]?["message"] ?? "Password reset failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background for a consistent branded look.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with fade-in animation.
                      AnimatedOpacity(
                        opacity: _headerOpacity,
                        duration: const Duration(milliseconds: 800),
                        child: const Text(
                          "Reset Your Password",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email field wrapped in an AnimatedContainer.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _emailFocus.hasFocus ? Colors.deepPurple : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          autofocus: true,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            labelText: "Email",
                            hintText: "Enter your email",
                            prefixIcon: const Icon(Icons.email),
                            errorText: _emailError,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Reset Password button.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              : const Text(
                                  "Reset Password",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "Back to Sign In" link.
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Remembered your password? "),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                "Sign In",
                                style: TextStyle(color: Colors.blue),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
