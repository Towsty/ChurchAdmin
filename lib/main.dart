import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_api_availability/google_api_availability.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'models/app_user.dart';
import 'services/user_service.dart';
import 'services/auth_service.dart';
import 'widgets/loading_overlay.dart';

import 'screens/attendance_input_screen.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/export_screen.dart';
import 'screens/join_request_approval_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_portal_screen.dart';
import 'screens/manage_members_screen.dart';
import 'screens/manage_announcements_screen.dart';
import 'screens/church_settings_screen.dart';

Future<void> initializeApp() async {
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('🟢 Firebase initialized');

    // Configure Firestore settings for mobile persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      sslEnabled: true,
    );

    // Initialize Auth
    await FirebaseAuth.instance.authStateChanges().first;
    print('🟢 Auth initialized');
  } catch (e, stackTrace) {
    print('🔥 Error during initialization: $e');
    print('Stack trace: $stackTrace');
    rethrow; // Rethrow to handle in the UI
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🟡 Step 1: Flutter bindings initialized');

  await initializeApp();

  runApp(const ChurchAdminApp());
}

class ChurchAdminApp extends StatelessWidget {
  const ChurchAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ).copyWith(
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceVariant: Colors.grey[100],
      onSurfaceVariant: Colors.black87,
      secondaryContainer: Colors.deepPurple[50],
      onSecondaryContainer: Colors.deepPurple[900],
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ).copyWith(
      surface: Color(0xFF1A1A1A),
      onSurface: Colors.white,
      surfaceVariant: Color(0xFF2D2D2D),
      onSurfaceVariant: Colors.white70,
      secondaryContainer: Colors.deepPurple[900],
      onSecondaryContainer: Colors.white,
    );

    final authService = AuthService();

    return MaterialApp(
      title: 'Church Admin',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrimColor: Colors.black54,
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: Colors.white,
          elevation: 0,
        ),
        navigationDrawerTheme: NavigationDrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          tileHeight: 56,
          indicatorColor: Colors.deepPurple[50],
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.normal,
            );
          }),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          selectedTileColor: Colors.deepPurple[50],
          iconColor: Colors.black87,
          textColor: Colors.black87,
          selectedColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
          scrimColor: Colors.black54,
          elevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        dialogBackgroundColor: const Color(0xFF121212),
        navigationDrawerTheme: NavigationDrawerThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          surfaceTintColor: Colors.transparent,
          elevation: 1,
          tileHeight: 56,
          indicatorColor: Colors.deepPurple[900],
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
            );
          }),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Colors.transparent,
          selectedTileColor: Colors.deepPurple[900],
          iconColor: Colors.white,
          textColor: Colors.white,
          selectedColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          surfaceTintColor: Colors.transparent,
          color: darkColorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: darkColorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        print('🎨 Current theme mode: ${isDark ? 'dark' : 'light'}');
        print(
          '📱 Scaffold background: ${Theme.of(context).scaffoldBackgroundColor}',
        );
        print(
          '🎯 Drawer background: ${Theme.of(context).drawerTheme.backgroundColor}',
        );
        return LoadingOverlay(
          isLoading: authService.isSigningOut,
          message: 'Switching accounts...',
          child: child!,
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            print('🔥 Auth stream error: ${snapshot.error}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => authService.signOut(context),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const AuthScreen();
          }

          return const HomeScreen();
        },
      ),
      routes: {
        '/attendance': (_) => const AttendanceInputScreen(),
        '/attendance-history': (_) => const AttendanceHistoryScreen(),
        '/export': (_) => const ExportScreen(),
        '/join-requests': (_) => const JoinRequestApprovalScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/admin': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return AdminPortalScreen(
            churchId: args['churchId'],
            churchName: args['churchName'],
          );
        },
        '/manage-members': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ManageMembersScreen(churchId: args['churchId']);
        },
        '/manage-announcements': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ManageAnnouncementsScreen(churchId: args['churchId']);
        },
        '/church-settings': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ChurchSettingsScreen(churchId: args['churchId']);
        },
      },
    );
  }
}
