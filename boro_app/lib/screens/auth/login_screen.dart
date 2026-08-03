import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../role_selection_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regNoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _regNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ApiService.login(
      _regNoController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please check your registration number or password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- BORO LOGO BANNER ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/boro_logo.png',
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Styled Brand Header Fallback if macOS asset bundling is cached
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'BORO',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Icon(Icons.two_wheeler, size: 36, color: Colors.black),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Campus Two-Wheeler Pool',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // REGISTRATION NUMBER INPUT
                  TextFormField(
                    controller: _regNoController,
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your Registration Number' : null,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PASSWORD INPUT
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your Password' : null,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // LOGIN BUTTON
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // REGISTER LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}