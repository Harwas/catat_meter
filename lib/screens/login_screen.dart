import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final usersRef = FirebaseDatabase.instance.ref('users');
    final snapshot = await usersRef.get();
    Map<String, dynamic>? userData;

    if (snapshot.exists) {
      var data = snapshot.value;
      if (data is Map) {
        final usersMap = Map<dynamic, dynamic>.from(data);
        usersMap.forEach((key, value) {
          if (value['username'] == username && value['password'] == password) {
            userData = {
              'uid': key,
              'username': value['username'],
              'role': value['role'],
              'cater_kode': value['cater_kode'],
            };
          }
        });
      } else if (data is List) {
        for (int i = 0; i < data.length; i++) {
          final value = data[i];
          if (value == null) continue;
          if (value['username'] == username && value['password'] == password) {
            userData = {
              'uid': i.toString(),
              'username': value['username'],
              'role': value['role'],
              'cater_kode': value['cater_kode'],
            };
          }
        }
      }
    }

    setState(() => _loading = false);

    if (userData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(currentUser: userData!),
        ),
      );
    } else {
      setState(() {
        _errorMsg = "Username atau password salah!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (_errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text("Login"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}