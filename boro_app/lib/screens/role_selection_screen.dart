import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';
import 'home/host_home_screen.dart';
import 'home/passenger_home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _bikeModelController = TextEditingController();
  final _bikeNumberController = TextEditingController();
  final _dialogFormKey = GlobalKey<FormState>();
  bool _isCheckingBike = false;
  bool _isSavingBike = false;

  @override
  void dispose() {
    _bikeModelController.dispose();
    _bikeNumberController.dispose();
    super.dispose();
  }

  // --- CHECK IF BIKE IS SAVED BEFORE SHOWING DIALOG ---
  void _onHostModeTap() async {
    setState(() => _isCheckingBike = true);

    // Fetch user profile from FastAPI backend
    final profile = await ApiService.getUserProfile();

    if (!mounted) return;
    setState(() => _isCheckingBike = false);

    // If bike is already registered in DB -> Go directly to Host Mode!
    if (profile != null && profile['has_bike'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HostHomeScreen()),
      );
    } else {
      // If no bike details saved -> Show registration dialog
      _showRegisterBikeDialog();
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Student Profile',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ApiService.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRegisterBikeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Register Your Bike',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: _dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please add your bike details to unlock Host mode and post rides.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // BIKE MODEL
                    TextFormField(
                      controller: _bikeModelController,
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter bike model' : null,
                      decoration: const InputDecoration(
                        labelText: 'Bike Model (e.g. Pulsar 150)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // BIKE PLATE NO.
                    TextFormField(
                      controller: _bikeNumberController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        UpperCaseTextFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter bike plate number';
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Bike Plate No. (e.g. KA01MN1234)',
                        labelStyle: TextStyle(color: Colors.grey),
                        counterText: '',
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _isSavingBike
                      ? null
                      : () async {
                          if (!_dialogFormKey.currentState!.validate()) return;

                          setDialogState(() => _isSavingBike = true);

                          final success = await ApiService.updateBikeDetails(
                            _bikeModelController.text.trim(),
                            _bikeNumberController.text.trim(),
                          );

                          setDialogState(() => _isSavingBike = false);

                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HostHomeScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to save bike details. Please try again.')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: _isSavingBike
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text('SAVE & CONTINUE TO HOST MODE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white),
              ),
              onPressed: _showProfileMenu,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'BORO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your mode to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 48),

              // HOST MODE CARD
              InkWell(
                onTap: _isCheckingBike ? null : _onHostModeTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_box, size: 36, color: Colors.amber),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Bike Owner (Host)',
                              style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap to post rides',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (_isCheckingBike)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // PASSENGER MODE CARD
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PassengerHomeScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 36, color: Colors.white),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Pillion Rider (Passenger)',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Search rides & book a seat',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// UpperCase Text Formatter Class
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}