import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_home.dart';
import 'user/home.dart';

import '../../config/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;

  /// -------------------------------------------------
  /// API: Validate Login Credentials
  /// -------------------------------------------------
  Future<Map<String, dynamic>?> validateUser(
    String email,
    String passcode,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/validate');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "passcode": passcode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) return data;
      }
      return null;
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      return null;
    }
  }

  /// -------------------------------------------------
  /// Save Login Credentials
  /// -------------------------------------------------
  Future<void> saveLoginData(
    int userId,
    String email,
    String username,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("userId", userId);
    await prefs.setString("email", email);
    await prefs.setString("username", username);
    await prefs.setString("role", role);
    await prefs.setBool("loggedIn", true);
  }

  /// -------------------------------------------------
  /// Validate & Login
  /// -------------------------------------------------
  Future<void> _validateAndLogin() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.text)) {
      _showError("Invalid email format");
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(password.text)) {
      _showError("Password must be a 10-digit code");
      return;
    }

    setState(() => _isLoading = true);

    final userData = await validateUser(email.text, password.text);

    if (userData == null) {
      _showError("Invalid credentials");
      setState(() => _isLoading = false);
      return;
    }

    final user = userData['user'];

    // SAVE LOGIN DETAILS
    await saveLoginData(
      user['id'],
      user['email'],
      user['username'],
      user['role'],
    );

    if (user['role'] == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminHomePage(email: user['email'], userId: user['id']),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            email: user['email'],
            userId: user['id'],
            username: user['username'],
          ),
        ),
      );
    }
  }

  /// -------------------------------------------------
  /// Show Error Snackbar
  /// -------------------------------------------------
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 247, 247, 247), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// Background Blobs
          Positioned(
            top: -60,
            right: -40,
            child: _blob(220, Colors.pinkAccent),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _blob(250, Colors.blueAccent),
          ),

          /// Login Box
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      color: Colors.white.withOpacity(0.1),
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("assets/images/ew.png", height: 80),
                        const SizedBox(height: 20),

                        Text(
                          "Please Login to continue",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.8),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _glassTextField(
                          controller: email,
                          hint: "Email",
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _glassTextField(
                          controller: password,
                          hint: "Phone Passcode",
                          icon: Icons.lock,
                          obscure: !_showPassword,
                          keyboardType: TextInputType.number,
                          isPasswordField: true,
                          showPassword: _showPassword,
                          onTogglePassword: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _validateAndLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(255, 93, 12, 193),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 93, 12, 193),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Glass Effect TextField
  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    bool isPasswordField = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        color: Colors.white.withOpacity(0.1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLength: keyboardType == TextInputType.number ? 10 : null,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        decoration: InputDecoration(
          counterText: "",
          prefixIcon: Icon(icon, color: Colors.white),

          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,

          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// Decorative Background Blob
  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.5),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: const SizedBox(),
      ),
    );
  }
}
