import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:laboratoriska3/screens/login_screen.dart';
import 'package:laboratoriska3/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyA21iHyTibrJMhZfOS4P7zj0Uy1FIu7RZw",
            authDomain: "laboratoriski203082.firebaseapp.com",
            projectId: "laboratoriski203082",
            storageBucket: "laboratoriski203082.appspot.com",
            messagingSenderId: "569262115580",
            appId: "1:569262115580:web:c7d123c79bd4f3945a6579"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exams app 203082',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   useMaterial3: true,
      // ),
      home: const SignUpScreen(),
    );
  }
}
