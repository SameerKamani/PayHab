import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each field.
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes for managing field focus.
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _studentIdFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  double _logoOpacity = 0.0;

  // Base URL for your Flask server endpoint.
  final String _baseUrl = 'http://10.0.2.2:5000';

  // Regex patterns.
  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  // Student ID must be exactly 2 letters followed by 5 digits.
  final RegExp studentIdRegex = RegExp(r'^[A-Za-z]{2}\d{5}$');

  // Real-time error messages.
  String? _studentIdError;
  String? _emailError;
  String? _passwordError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload the logo image.
    precacheImage(const AssetImage('assets/payhab_logo.jpeg'), context);
  }

  @override
  void initState() {
    super.initState();
    // Listen for changes to update error messages.
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _studentIdController.addListener(_validateStudentId);
    
    // Animate the logo fade-in.
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _logoOpacity = 1.0;
      });
    });
    // Request focus on the Name field after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocus);
    });
  }

  void _validateStudentId() {
    final text = _studentIdController.text;
    setState(() {
      if (text.isEmpty) {
        _studentIdError = 'Please enter your Student ID';
      } else if (!studentIdRegex.hasMatch(text)) {
        _studentIdError = 'Enter a valid Student ID (e.g., sk08109, at09123, or xy12345)';
      } else {
        _studentIdError = null;
      }
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

  void _validatePassword() {
    final text = _passwordController.text;
    setState(() {
      if (text.isEmpty) {
        _passwordError = 'Please enter a password';
      } else if (!_isPasswordComplex(text)) {
        _passwordError = 'Min 8 chars, letters & numbers';
      } else {
        _passwordError = null;
      }
    });
  }

  // Checks that the password is at least 8 characters and includes letters and numbers.
  bool _isPasswordComplex(String password) {
    return password.length >= 8 &&
           RegExp(r'[A-Za-z]').hasMatch(password) &&
           RegExp(r'\d').hasMatch(password);
  }

  // Calls the /register endpoint, then logs in and sends a verification email.
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate() ||
        _studentIdError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$_baseUrl/register');
    final body = json.encode({
      'name': _nameController.text.trim(),
      'studentId': _studentIdController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (response.statusCode == 200) {
        // Registration succeeded; proceed to log in and send verification.
        await _loginAndSendVerification();
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Error occurred')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginAndSendVerification() async {
    final loginUrl = Uri.parse('$_baseUrl/login');
    final loginBody = json.encode({
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    });

    try {
      final loginResponse = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: loginBody,
      );

      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        final String idToken = loginData['idToken'];

        // Send a verification email.
        final verifyUrl = Uri.parse('$_baseUrl/send-verification');
        final verifyBody = json.encode({
          'idToken': idToken,
        });
        final verifyResponse = await http.post(
          verifyUrl,
          headers: {'Content-Type': 'application/json'},
          body: verifyBody,
        );

        if (verifyResponse.statusCode == 200) {
          final verifyData = json.decode(verifyResponse.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                verifyData['message'] ??
                'Verification email sent. Please check your inbox.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // After a delay, navigate to the LoginScreen.
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          });
        } else {
          final verifyData = json.decode(verifyResponse.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(verifyData['error'] ?? 'Failed to send verification email')),
          );
        }
      } else {
        final loginData = json.decode(loginResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loginData['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during login: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _studentIdFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background.
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
                      // Animated logo with increased size.
                      Center(
                        child: AnimatedOpacity(
                          opacity: _logoOpacity,
                          duration: const Duration(milliseconds: 800),
                          child: Semantics(
                            label: 'PayHab Logo',
                            child: CircleAvatar(
                              radius: 120,
                              backgroundImage: const AssetImage('assets/payhab_logo.jpeg'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32), // Space between logo and form.
                      Center(
                        child: Text(
                          'Create Account',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Name Field.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _nameFocus.hasFocus ? Colors.deepPurple : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_studentIdFocus);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Student ID Field.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _studentIdFocus.hasFocus ? Colors.deepPurple : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _studentIdController,
                          focusNode: _studentIdFocus,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            labelText: 'Student ID',
                            hintText: 'e.g., sk08109, at09123, or xy12345',
                            prefixIcon: const Icon(Icons.badge),
                            errorText: _studentIdError,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your student ID';
                            } else if (!studentIdRegex.hasMatch(value)) {
                              return 'Enter a valid Student ID (e.g., sk08109, at09123, or xy12345)';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_emailFocus);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email Field.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _emailFocus.hasFocus ? Colors.deepPurple : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            errorText: _emailError,
                          ),
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password Field with eye toggle.
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _passwordFocus.hasFocus ? Colors.deepPurple : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              tooltip: _obscurePassword ? 'Show Password' : 'Hide Password',
                            ),
                            helperText: _passwordError == null ? 'Min 8 chars, letters & numbers' : null,
                            errorText: _passwordError,
                          ),
                          onFieldSubmitted: (_) {
                            _registerUser();
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Register Button.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            if (_formKey.currentState!.validate()) {
                              _registerUser();
                            }
                          },
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
                                  'Register',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Sign-In link.
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Already have an account? '),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                'Sign-In',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
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
