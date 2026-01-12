import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:civiczero/config/app_theme.dart';
import 'package:civiczero/views/enter_view.dart';
import 'package:civiczero/services/auth_service.dart';
import 'package:civiczero/views/main_tab_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CivicZeroApp());
}

class CivicZeroApp extends StatelessWidget {
  const CivicZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicZero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.primaryDark,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              ),
            );
          }
          
          // If user is signed in, go to MainTabView
          if (snapshot.hasData) {
            return const MainTabView();
          }
          
          // Otherwise, show EnterView
          return const EnterView();
        },
      ),
    );
  }
}
