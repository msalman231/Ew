import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final String baseUrl = "https://f5vfl9mt-3000.inc1.devtunnels.ms";

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
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.deepPurple.shade100,
                        ),
                        columns: const [
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Live Location")),
                          DataColumn(label: Text("Travel History")),
                        ],
                        rows: filteredUsers.map<DataRow>((u) {
                          final int userId = u["id"];
                          final String email = u["email"];

                          return DataRow(
                            cells: [
                              DataCell(Text(email)),

                              /// LIVE LOCATION BUTTON
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => openLiveLocation(userId),
                                ),
                              ),

                              /// TRAVEL HISTORY BUTTON
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.timeline,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => openTravelHistory(userId),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
