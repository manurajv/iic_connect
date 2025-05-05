import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iic_connect/providers/academic_provider.dart';
import 'package:iic_connect/providers/attendance_provider.dart';
import 'package:iic_connect/providers/event_provider.dart';
import 'package:iic_connect/providers/lab_provider.dart';
import 'package:iic_connect/providers/notice_provider.dart';
import 'package:iic_connect/providers/project_provider.dart';
import 'package:iic_connect/providers/subject_provider.dart';
import 'package:iic_connect/providers/timetable_provider.dart';
import 'package:iic_connect/screens/auth/login_screen.dart';
import 'package:iic_connect/screens/home/home_screen.dart';
import 'package:iic_connect/screens/labs/labs_screen.dart';
import 'package:iic_connect/screens/projects/projects_screen.dart';
import 'package:iic_connect/screens/splash/splash_screen.dart';
import 'package:iic_connect/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:iic_connect/providers/auth_provider.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => LabProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AcademicProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/projects': (context) => const ProjectsScreen(),
        '/labs': (context) => const LabsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (isLoggedIn) {
      try {
        await authProvider.initialize();
      } catch (e) {
        // If initialization fails, clear the login state
        await prefs.remove('isLoggedIn');
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return const SplashScreen();
    } else if (authProvider.user != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}