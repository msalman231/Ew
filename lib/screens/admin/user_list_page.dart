import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_user_page.dart';

final String baseUrl = "https://f5vfl9mt-3000.inc1.devtunnels.ms";

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadUsers();
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

  Future<void> callUser(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<Map<String, dynamic>?> getLatestLocation(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/user-locations/latest/$userId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<List<dynamic>> getTravelHistory(int userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/user-locations/history/$userId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<void> openLiveLocation(int userId) async {
    final loc = await getLatestLocation(userId);
    if (loc == null) return;

    final lat = loc["latitude"];
    final lng = loc["longitude"];

    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> openTravelHistory(int userId) async {
    final history = await getTravelHistory(userId);
    if (history.isEmpty) return;

    final path = history
        .map((p) => "${p['latitude']},${p['longitude']}")
        .join("/");

    final url = Uri.parse("https://www.google.com/maps/dir/$path");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users List", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserPage()),
          );
        },
      ),

      body: Column(
        children: [
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

          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      final int userId = u["id"];
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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _circleButton(
                                  icon: Icons.call,
                                  color: Colors.green,
                                  onTap: () => callUser(phone),
                                ),

                                _circleButton(
                                  icon: Icons.location_on,
                                  color: Colors.red,
                                  onTap: () => openLiveLocation(userId),
                                ),

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
