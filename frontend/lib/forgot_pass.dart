import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  final String baseUrl;

  ForgotPasswordPage({required this.baseUrl});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> sendResetLink() async {
    final url = Uri.parse('${widget.baseUrl}/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link sent to your email')),
        );
        Navigator.pop(context); // Go back to login page
      } else {
        print('Error during password reset request: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(response.body)['error'])),
        );
      }
    } catch (e) {
      print('Error connecting to server: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Forgot Password")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                child:
                Image.asset('assets/skincare_logo.png', height: 150), // Logo
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                sendResetLink, // Call sendResetLink function when button is pressed
                style:
                ElevatedButton.styleFrom(minimumSize:
                Size(double.infinity, 50)),
                child:
                Text("Send Reset Link"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
