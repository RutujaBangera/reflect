import 'package:flutter/material.dart';
import 'createaccount.dart';
import 'loginpage.dart';
import 'splashscreen.dart';
import 'homescreen.dart';
import 'profilepage.dart';
import 'journalpage.dart';
import 'signinpage.dart';
import 'calender.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reflect/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ReflectApp());
}

class ReflectApp extends StatelessWidget {
  const ReflectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/createAccount': (context) => const CreateAccountPage(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfilePage(),
        '/journal': (context) => const JournalPage(),
        '/signin': (context) => const SignInPage(),
        '/calendar': (context) => const CalendarPage()
      },
    );
  }
}
