import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_user_page.dart';
import 'package:efficient_works/config/constants.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  String searchQuery = "";

  bool _isLaunchingMap = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final res = await http.get(Uri.parse("${AppConfig.baseUrl}/users"));
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
      Uri.parse("${AppConfig.baseUrl}/user-locations/latest/$userId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<List<dynamic>> getTravelHistory(int userId) async {
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/user-locations/history/$userId"),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<void> openLiveLocation(int userId) async {
    if (_isLaunchingMap) return; // 🔒 prevent double launch
    _isLaunchingMap = true;

    try {
      final loc = await getLatestLocation(userId);

      if (!mounted) return;

      if (loc == null || loc["latitude"] == null || loc["longitude"] == null) {
        _toast("Live location not available");
        return;
      }

      final lat = loc["latitude"].toString();
      final lng = loc["longitude"].toString();

      final uri = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );

      if (!await canLaunchUrl(uri)) {
        _toast("Unable to open Google Maps");
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _toast("Failed to open live location");
    } finally {
      // Delay unlock to avoid instant re-trigger
      Future.delayed(const Duration(seconds: 1), () {
        _isLaunchingMap = false;
      });
    }
  }

  Future<void> openTravelHistory(int userId) async {
    if (_isLaunchingMap) return;
    _isLaunchingMap = true;

    try {
      final history = await getTravelHistory(userId);

      if (!mounted) return;

      if (history.isEmpty) {
        _toast("Travel history not available");
        return;
      }

      // ✅ Keep only last 10 points (VERY IMPORTANT)
      final points = history
          .where((p) => p["latitude"] != null && p["longitude"] != null)
          .take(10)
          .map((p) => "${p['latitude']},${p['longitude']}")
          .toList();

      if (points.length < 2) {
        _toast("Not enough travel points");
        return;
      }

      final uri = Uri.parse(
        "https://www.google.com/maps/dir/${points.join('/')}",
      );

      if (!await canLaunchUrl(uri)) {
        _toast("Unable to open Google Maps");
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _toast("Failed to open travel history");
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        _isLaunchingMap = false;
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
