import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final String baseUrl = "https://leads.efficient-works.com";

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.email, required this.userId});

  final String email;
  final int userId;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  String searchQuery = "";
  final String phone = "";

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void callUser(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cannot call $phone")));
    }
  }

  Future<void> loadUsers() async {
    final res = await http.get(Uri.parse("$baseUrl/users"));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      setState(() {
        users = list;
        filteredUsers = list;
      });
    }
  }

  void filterUsers(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredUsers = users.where((u) {
        final email = u["email"].toString().toLowerCase();
        return email.contains(searchQuery);
      }).toList();
    });
  }

  /// Fetch latest live location
  Future<Map<String, dynamic>?> getLatestLocation(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/user-locations/latest/$userId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  /// Fetch full travel path (all stored locations)
  Future<List<dynamic>> getTravelHistory(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/user-locations/history/$userId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  /// Open Google Maps for LIVE location
  Future<void> openLiveLocation(int userId) async {
    final loc = await getLatestLocation(userId);
    if (loc == null) {
      debugPrint("❌ No live location available");
      return;
    }

    final lat = loc["latitude"];
    final lng = loc["longitude"];

    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Open Google Maps with Travel Path Polyline
  Future<void> openTravelHistory(int userId) async {
    final history = await getTravelHistory(userId);
    if (history.isEmpty) {
      debugPrint("❌ No travel history available");
      return;
    }

    // Format polyline path: lat1,lng1/lat2,lng2/...
    final path = history
        .map((p) => "${p['latitude']},${p['longitude']}")
        .join("/");

    final url = Uri.parse("https://www.google.com/maps/dir/$path");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.pushNamedAndRemoveUntil(
                context,
                "/login",
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Home", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search Users by Email",
                border: OutlineInputBorder(),
              ),
              onChanged: filterUsers,
            ),
          ),

          // Table header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.black12,
            child: const Text(
              "Users List",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Users Table
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      final int userId = u["id"];
                      final String email = u["email"];
                      final String username = u["full_name"] ?? "Unknown";
                      final String phone = u["phone_number"] ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade800.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.shade200,
                            width: 2,
                          ),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // USER NAME BOX
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 3 ROUND BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // CALL BUTTON
                                _circleButton(
                                  icon: Icons.call,
                                  color: Colors.green,
                                  onTap: () => callUser(phone),
                                ),

                                // LIVE LOCATION BUTTON
                                _circleButton(
                                  icon: Icons.location_on,
                                  color: Colors.red,
                                  onTap: () => openLiveLocation(userId),
                                ),

                                // TRAVEL HISTORY BUTTON
                                _circleButton(
                                  icon: Icons.timeline,
                                  color: Colors.blue,
                                  onTap: () => openTravelHistory(userId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          color: Colors.black,
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
