import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _collegeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _regNoController.dispose();
    _collegeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'full_name': _fullNameController.text.trim(),
      'reg_no': _regNoController.text.trim(),
      'college_name': _collegeController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'password': _passwordController.text.trim(),
      'has_bike': false,
    };

    final result = await ApiService.register(payload);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // FULL NAME
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your Full Name' : null,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // REGISTRATION NUMBER
                TextFormField(
                  controller: _regNoController,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter Registration Number' : null,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // COLLEGE NAME
                TextFormField(
                  controller: _collegeController,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter College Name' : null,
                  decoration: const InputDecoration(
                    labelText: 'College Name',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // PHONE NUMBER
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter Phone Number';
                    if (v.trim().length != 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (10 digits)',
                    labelStyle: TextStyle(color: Colors.grey),
                    counterText: '',
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) => (v == null || v.trim().length < 6) ? 'Password must be at least 6 characters' : null,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),

                // REGISTER BUTTON
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'REGISTER',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}