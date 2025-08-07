import 'package:flutter/material.dart';
import 'package:mobilenode_app/provider/provider.dart';
import '../lightnode_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key, required this.management});

  final Management management;
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("환영합니다")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text("로그인"),
              onPressed: () {
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (_) => const LoginScreen()),
                    MaterialPageRoute(builder: (_) => LightNodeScreen(management: widget.management,)),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("회원가입"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
