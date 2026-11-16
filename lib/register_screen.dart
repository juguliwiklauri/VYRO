import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  Future<void> submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty ||
        password.text.length < 6 || username.text.trim().isEmpty) {
      setState(() => error = 'შეავსე ყველა ველი. პაროლი მინიმუმ 6 სიმბოლო უნდა იყოს.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      await AuthService().register(displayName: name.text, username: username.text,
        email: email.text, password: password.text);
      if (mounted) Navigator.pop(context);
    } catch (e) { setState(() => error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { name.dispose(); username.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('რეგისტრაცია')),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'სახელი')),
      const SizedBox(height: 12),
      TextField(controller: username, decoration: const InputDecoration(labelText: 'მომხმარებლის სახელი (მაგ. vyro_user)')),
      const SizedBox(height: 12),
      TextField(controller: email, keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'ელფოსტა')),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true,
        decoration: const InputDecoration(labelText: 'პაროლი (მინიმუმ 6 სიმბოლო)')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
        child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : submit,
        child: Text(busy ? 'იქმნება ანგარიში...' : 'რეგისტრაცია')),
    ]),
  );
}
