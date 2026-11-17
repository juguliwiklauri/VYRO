
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://jhcoczjtjfqiqigpcocw.supabase.co',
    publishableKey: 'sb_publishable_a0Gg8Xl2u_54Bzzp5zo45A_0uLAFLJg',
    accessToken: () async {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    },
  );

  runApp(const TurboApp());
}

class TurboApp extends StatelessWidget {
  const TurboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TURBO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2020),
          secondary: Color(0xFFFF5A36),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
