import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'models/app_user.dart';
import 'services/user_service.dart';

import 'screens/attendance_input_screen.dart';
import 'screens/attendance_history_screen.dart';
import 'screens/export_screen.dart';
import 'screens/join_request_approval_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_portal_screen.dart';
import 'screens/manage_members_screen.dart';
import 'screens/manage_announcements_screen.dart';
import 'screens/church_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Before Firebase init');
  print('🟡 Step 1: Flutter bindings initialized');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('🟢 Step 2: Firebase initialized');
  print('Firebase initialized');

  // ✅ Enable Firestore debug logging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  //FirebaseFirestore.instance.setLogLevel(LogLevel.debug);

  final user = FirebaseAuth.instance.currentUser;
  print('👤 Initial user: ${user?.uid ?? 'none'}');

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
        return child!;
      },
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasError) {
              print('🔥 Error loading user profile: ${userSnapshot.error}');
              return const Scaffold(
                body: Center(
                  child: Text('Something went wrong. Please try again.'),
                ),
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
