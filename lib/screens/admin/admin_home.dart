import 'package:flutter/material.dart';
import 'user_list_page.dart';
import 'restaurant_list_page.dart';

class AdminHomePage extends StatelessWidget {
  final String email;
  final int userId;

  const AdminHomePage({super.key, required this.email, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Light background

      appBar: AppBar(
        title: const Text("Admin Home", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutPopup(context),
          ),
        ],
      ),

      body: _buildBody(context),
      bottomNavigationBar: _bottomMenu(context),
    );
  }

  /// BODY UI (simple clean page)
  Widget _buildBody(BuildContext context) {
    return const Center(
      child: Text(
        "Welcome Admin",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// LOGOUT POPUP CONFIRMATION
  void _showLogoutPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Logout"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (_) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// BOTTOM NAVIGATION BAR (your design)
  Widget _bottomMenu(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(width: 1, color: Colors.grey)),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.people, size: 32),
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListPage()),
              );
            },
          ),

          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: IconButton(
              icon: const Icon(Icons.home, size: 30),
              color: Colors.black,
              onPressed: () {
                // Already on Home
              },
            ),
          ),

          IconButton(
            icon: const Icon(Icons.restaurant_menu, size: 32),
            color: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RestaurantListPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
