import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'skin_analysis_page.dart';
import 'skin_type_selection_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  final String baseUrl;

  const ProfilePage({super.key, required this.token, required this.baseUrl});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> userData = {};
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse('${widget.baseUrl}/auth/profile');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isAdmin = userData['role'] == 'admin';
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5E3C), Color(0xFFD2A679)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'AuraSkin',
            style: GoogleFonts.notoSansAdlam(
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/background.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),

          // Main content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 140, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              const TextSpan(text: 'Welcome, '),
                              TextSpan(
                                text: userData['username'] ?? '',
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(text: '!'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Buttons with shadows
                        buildButton('Edit Your Profile', Colors.brown, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(
                                token: widget.token,
                                baseUrl: widget.baseUrl,
                              ),
                            ),
                          );
                        }),
                        buildButton('Skin Analysis', Colors.brown, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SkinAnalysisPage()),
                          );
                        }),
                        buildButton(
                          'Recommended Products for Your Skin Type',
                          Colors.brown,
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SkinTypeSelectionPage(
                                    baseUrl: widget.baseUrl),
                              ),
                            );
                          },
                        ),

                        if (isAdmin)
                          ListTile(
                            title: const Text('User Management'),
                            leading: const Icon(Icons.admin_panel_settings),
                            onTap: () {
                              // Navigate to user management page
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Logout button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.all(15),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final url = Uri.parse('${widget.baseUrl}/auth/logout');
                    try {
                      final response = await http.post(
                        url,
                        headers: {'Authorization': 'Bearer ${widget.token}'},
                      );
                      if (response.statusCode == 200) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      } else {
                        print('Error during logout: ${response.body}');
                      }
                    } catch (e) {
                      print('Error connecting to server: $e');
                    }
                  },
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}