import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'models/app_user.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Before Firebase init');
  print('🟡 Step 1: Flutter bindings initialized');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('🟢 Step 2: Firebase initialized');
  print('Firebase initialized');

  final user = FirebaseAuth.instance.currentUser;
  print('👤 Initial user: ${user?.uid ?? 'none'}');  // <-- 👈 This is the key line

  runApp(const ChurchAdminApp());
}

class ChurchAdminApp extends StatelessWidget {
  const ChurchAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Church Admin',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
      ),
      darkTheme: ThemeData.dark(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;
        if (user == null) {
          print('🛑 No Firebase user found. Showing auth screen.');
          return const AuthScreen();
        }

        return FutureBuilder<AppUser?>(
          future: UserService().getUser(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasError) {
              print('🔥 Error loading user profile: ${userSnapshot.error}');
              return const Scaffold(
                body: Center(child: Text('Something went wrong. Please try again.')),
              );
            }

            final appUser = userSnapshot.data;
            if (appUser == null) {
              print('❌ AppUser profile not found for UID: ${user.uid}');
              return const Scaffold(
                body: Center(
                  child: Text(
                    'User profile not found.\nPlease contact support or re-register.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            print('✅ AppUser loaded: ${appUser.name}');

            // ✅ Main screen
            return const HomeScreen();
          },
        );
      },
    );
  }
}




