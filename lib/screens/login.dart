import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'admin/admin_home.dart';
import 'package:flutter/services.dart';

import 'user/home.dart';

import '../../config/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// -------------------------------------------------
  /// User Login Fields
  /// -------------------------------------------------
  final email = TextEditingController();
  final password = TextEditingController();

  /// -------------------------------------------------
  /// Automatically fills email in email field
  /// -------------------------------------------------
  static const String companyDomain = "@efficient-works.com";
  String get fullEmail => "${email.text.trim()}$companyDomain";

  /// -------------------------------------------------
  /// Secure Storage to Store Login Details
  /// -------------------------------------------------
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool _showPassword = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  /// -------------------------------------------------
  /// Save credentials securely (local encrypted storage)
  /// -------------------------------------------------
  // Future<void> _savePasswordSecurely(String email, String passcode) async {
  //   try {
  //     await secureStorage.write(key: "saved_email", value: email);
  //     await secureStorage.write(key: "saved_passcode", value: passcode);

  //     debugPrint("Credentials saved securely to device.");
  //   } catch (e) {
  //     debugPrint("Secure storage save failed: $e");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// -------------------------------------------------
  /// Save credentials securely (local encrypted storage)
  /// -------------------------------------------------
  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await secureStorage.read(key: "saved_email");
      final savedPasscode = await secureStorage.read(key: "saved_passcode");
      final remember = await secureStorage.read(key: "remember_me");

      if (remember == "true" && savedEmail != null && savedPasscode != null) {
        setState(() {
          email.text = savedEmail;
          password.text = savedPasscode;
          _rememberMe = true;
        });
      }
    } catch (e) {
      debugPrint("Failed to load saved credentials: $e");
    }
  }

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
  /// Save Login Credentials Locally
  /// -------------------------------------------------
  Future<void> saveLoginData(
    int userId,
    String userEmail,
    String username,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await secureStorage.write(key: "saved_email", value: email.text);
      await secureStorage.write(key: "saved_passcode", value: password.text);
      await secureStorage.write(key: "remember_me", value: "true");
    } else {
      await secureStorage.delete(key: "saved_email");
      await secureStorage.delete(key: "saved_passcode");
      await secureStorage.write(key: "remember_me", value: "false");
    }

    await prefs.setInt("userId", userId);
    await prefs.setString("email", userEmail);
    await prefs.setString("username", username);
    await prefs.setString("role", role);
    await prefs.setBool("loggedIn", true);
  }

  //Forgot Passowrod MSG
  void _forgotPassword() {
    if (email.text.isEmpty) {
      _showError("Please enter your email first");
      return;
    }

    // Hook API here later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password reset instructions sent"),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// -------------------------------------------------
  /// Validate & Login
  /// -------------------------------------------------
  Future<void> _validateAndLogin() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(email.text)) {
      _showError("Invalid username");
      return;
    }

    if (!RegExp(r'^[0-9]{4}$').hasMatch(password.text)) {
      _showError("Password must be a 4-digit code");
      return;
    }

    setState(() => _isLoading = true);

    final userData = await validateUser(fullEmail, password.text);

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
          builder: (_) => AdminHomePage(
            email: user['email'],
            userId: user['id'],
            username: user['username'],
          ),
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

  // --------------------------------------------------
  // UI Login Box
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 247, 247, 247),
                  Color.fromARGB(255, 32, 150, 62),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            top: -60,
            right: -40,
            child: _blob(220, const Color.fromARGB(255, 248, 124, 165)),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _blob(250, const Color.fromRGBO(132, 202, 141, 1)),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: _loginBox(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginBox() {
    return Container(
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
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                activeColor: const Color.fromARGB(255, 107, 217, 85),
                onChanged: (value) {
                  setState(() => _rememberMe = value ?? false);
                },
              ),
              const Text("Remember Me", style: TextStyle(color: Colors.white)),
              const Spacer(),
              TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          _loginButton(),
        ],
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _validateAndLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 104, 63, 194),
          // foregroundColor: const Color.fromARGB(255, 24, 24, 111),
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
                    Color.fromARGB(255, 103, 23, 196),
                  ),
                ),
              )
            : const Text(
                "Login",
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 98, 231, 98),
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

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
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),

          // INPUT FIELD
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,

              // 🔒 PASSCODE RESTRICTION (ONLY HERE)
              inputFormatters: isPasswordField
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ]
                  : null,

              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
              ),
            ),
          ),

          // DOMAIN ONLY FOR EMAIL FIELD
          if (!isPasswordField)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                "@efficient-works.com",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // PASSWORD VISIBILITY TOGGLE
          if (isPasswordField)
            IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: onTogglePassword,
            ),
        ],
      ),
    );
  }

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
