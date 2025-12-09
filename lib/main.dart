import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login UI',

      routes: {
        "/login": (context) => const LoginPage(),

        "/home": (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;

          return HomePage(
            email: args["email"],
            userId: args["userId"],
            username: args["username"],
          );
        },
      },

      home: const LoginPage(),
    );
  }
}
