import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'main_dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes for managing field focus.
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  double _logoOpacity = 0.0;

  // Base URL for your Flask server.
  final String _baseUrl = 'http://10.0.2.2:5000';

  // Regex for email validation.
  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // Real-time error messages.
  String? _emailError;
  String? _passwordError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload the logo image here to avoid jank and avoid context issues.
    precacheImage(const AssetImage('assets/payhab_logo.jpeg'), context);
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    // Request focus on the email field after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocus);
    });
    // Animate the logo fade-in.
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _logoOpacity = 1.0;
      });
    });
    // Listen for changes to update error messages in real time.
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
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
        _passwordError = 'Please enter your password';
      } else if (!_isPasswordComplex(text)) {
        _passwordError = 'Min 8 chars, letters & numbers';
      } else {
        _passwordError = null;
      }
    });
  }
  
  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('rememberMe') ?? false;
    if (remember) {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      setState(() {
        _rememberMe = true;
      });
      if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _loginUser();
        });
      }
    }
  }
  
  Future<void> _saveCredentials(String idToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('password', _passwordController.text);
      await prefs.setString('idToken', idToken);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('idToken');
      await prefs.setBool('rememberMe', false);
    }
  }
  
  // Checks that the password is at least 8 characters and includes letters and numbers.
  bool _isPasswordComplex(String password) {
    return password.length >= 8 &&
           RegExp(r'[A-Za-z]').hasMatch(password) &&
           RegExp(r'\d').hasMatch(password);
  }
  
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate() || _emailError != null || _passwordError != null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final url = Uri.parse('$_baseUrl/login');
    final body = json.encode({
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
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Login successful')),
        );
        final String userId = responseData['userId'];
        final String idToken = responseData['idToken'];
        await _saveCredentials(idToken);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDashboardScreen(userId: userId, idToken: idToken),
          ),
        );
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Login failed')),
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
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                      const SizedBox(height: 32), // Increased space between logo and fields.
                      // Email field with real-time validation.
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
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: const Icon(Icons.email),
                            errorText: _emailError,
                          ),
                          onFieldSubmitted: (_) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              FocusScope.of(context).requestFocus(_passwordFocus);
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Password field with errorText integrated.
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
                            hintText: 'Enter your password',
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
                            // Only show helper text if no error.
                            helperText: _passwordError == null ? 'Min 8 chars, letters & numbers' : null,
                            errorText: _passwordError,
                          ),
                          onFieldSubmitted: (_) {
                            _loginUser();
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "Remember me" and "Forgot password?" row.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text('Remember me'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Sign in button.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginUser,
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
                                  'Sign in',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Terms and Conditions disclaimer.
                      Center(
                        child: Text(
                          'By signing in, you agree to our Terms & Conditions and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "Don't have an account? Sign-Up" link.
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Don't have an account? "),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                );
                              },
                              child: const Text(
                                'Sign-Up',
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
