import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/role_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BoroApp());
}

class BoroApp extends StatelessWidget {
  const BoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: FutureBuilder<String?>(
        future: StorageService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            return const RoleSelectionScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}