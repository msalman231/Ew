import 'dart:async';
// import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/location_service.dart';
import '../services/restaurant_service.dart';
import 'restaurant_form_page.dart';
import 'drawer_menu.dart';

final String baseUrl = "https://f5vfl9mt-3000.inc1.devtunnels.ms";

class HomePage extends StatefulWidget {
  final String email;
  final int userId;

  const HomePage({super.key, required this.email, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool searchActive = false;
  bool dateFilterActive = false;

  DateTime? fromDate;
  DateTime? toDate;

  Timer? locationTimer;

  List<dynamic> allRestaurants = [];
  List<dynamic> filteredRestaurants = [];
  String searchQuery = "";
  String sortOrder = "latest";

  String selectedType = "All";

  StreamSubscription<Position>? positionStream;

  final List<String> typeFilters = [
    "All",
    "leads",
    "follows",
    "future follows",
    "conversion",
  ];

  @override
  void initState() {
    super.initState();
    loadRestaurants();
    startLocationTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();

    super.dispose();
  }

  Future<void> loadRestaurants() async {
    final list = await RestaurantService.getRestaurants();
    print("API RESTAURANT DATA → $list"); // ADD THIS
    setState(() {
      allRestaurants = list;
      applyFilters();
    });
  }

  void startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters movement
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            // Capture & send location
            String address = await _getAddress(
              position.latitude,
              position.longitude,
            );

            await RestaurantService.trackLocation(
              userId: widget.userId,
              email: widget.email,
              latitude: position.latitude.toString(),
              longitude: position.longitude.toString(),
              address: address,
            );
            print(
              "📍 LIVE LOCATION → ${position.latitude}, ${position.longitude}",
            );
          },
        );
  }

  Future<String> _getAddress(double lat, double lng) async {
    final places = await placemarkFromCoordinates(lat, lng);
    final p = places.first;
    return "${p.street}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
  }

  Future<void> captureAndSendLocation() async {
    try {
      final loc = await LocationService.getLocationDetails();

      await RestaurantService.trackLocation(
        userId: widget.userId,
        email: widget.email, // ✅ added
        address: loc["address"]!,
        latitude: loc["latitude"]!,
        longitude: loc["longitude"]!,
      );

      debugPrint("Location stored successfully");
    } catch (e) {
      debugPrint("Location tracking failed → $e");
    }
  }

  void applyFilters() {
    List<dynamic> list = List.from(allRestaurants);

    if (searchQuery.isNotEmpty) {
      list = list.where((r) {
        final name = (r["name"] ?? "").toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (selectedType != "All") {
      list = list.where((r) {
        final type = (r["res_type"] ?? "").toString().toLowerCase();
        return type == selectedType.toLowerCase();
      }).toList();
    }

    if (fromDate != null && toDate != null) {
      list = list.where((r) {
        if (r["created_at"] == null) return false;

        final created = DateTime.tryParse(r["created_at"]) ?? DateTime(2000);

        return created.isAfter(fromDate!) &&
            created.isBefore(toDate!.add(const Duration(days: 1)));
      }).toList();
    }

    list.sort((a, b) {
      final aTime = DateTime.tryParse(a["created_at"] ?? "") ?? DateTime(2000);
      final bTime = DateTime.tryParse(b["created_at"] ?? "") ?? DateTime(2000);
      return sortOrder == "latest"
          ? bTime.compareTo(aTime)
          : aTime.compareTo(bTime);
    });

    setState(() => filteredRestaurants = list);
  }

  Future<void> pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom)
          fromDate = picked;
        else
          toDate = picked;
      });
    }
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
            onPressed: () async {
              Navigator.pop(context);

              // ⭐ 1. Capture location BEFORE logging out
              try {
                final loc = await LocationService.getLocationDetails();
                await RestaurantService.trackLocation(
                  userId: widget.userId,
                  email: widget.email,
                  latitude: loc["latitude"]!,
                  longitude: loc["longitude"]!,
                  address: loc["address"]!,
                );
                debugPrint("📍 Last location saved before logout");
              } catch (e) {
                debugPrint("🔥 Failed to capture last location: $e");
              }

              // Stop the timer immediately
              positionStream?.cancel();
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
      drawer: DrawerMenu(email: widget.email),
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            color: Colors.white,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // <-- correct
        onPressed: () async {
          bool? saved = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RestaurantFormPage()),
          );
          if (saved == true) loadRestaurants();
        },
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildTopFilter(),

            /// Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.black12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Restaurant List",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  /// 🔽 Restaurant Type Filter Dropdown
                  DropdownButton<String>(
                    value: selectedType,
                    underline: Container(),
                    items: typeFilters.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                      applyFilters();
                    },
                  ),
                ],
              ),
            ),

            /// TABLE VIEW
            Expanded(
              child: filteredRestaurants.isEmpty
                  ? const Center(child: Text("No restaurants found"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.deepPurple.shade100,
                        ),
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Contact")),
                          DataColumn(label: Text("Call")),
                          DataColumn(label: Text("Directions")),
                        ],
                        rows: filteredRestaurants.map<DataRow>((r) {
                          final String name = r["name"] ?? "-";
                          final String contact = r["contact"] ?? "-";
                          final double? lat = r["latitude"] != null
                              ? double.tryParse(r["latitude"].toString())
                              : null;

                          final double? lng = r["longitude"] != null
                              ? double.tryParse(r["longitude"].toString())
                              : null;

                          return DataRow(
                            cells: [
                              DataCell(Text(name)),
                              DataCell(Text(contact)),

                              /// CALL BUTTON
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.call,
                                    color: Colors.green,
                                  ),
                                  onPressed: contact.isNotEmpty
                                      ? () =>
                                            launchUrl(Uri.parse("tel:$contact"))
                                      : null,
                                ),
                              ),

                              /// OPEN GOOGLE MAPS
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.directions,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    final double? lat = r["latitude"] != null
                                        ? double.tryParse(
                                            r["latitude"].toString(),
                                          )
                                        : null;
                                    final double? lng = r["longitude"] != null
                                        ? double.tryParse(
                                            r["longitude"].toString(),
                                          )
                                        : null;

                                    if (lat == null || lng == null) {
                                      debugPrint(
                                        "❌ No location stored for this restaurant",
                                      );
                                      return;
                                    }

                                    final Uri mapUrl = Uri.parse(
                                      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
                                    );

                                    final bool launched = await launchUrl(
                                      mapUrl,
                                      mode: LaunchMode.externalApplication,
                                    );

                                    if (!launched) {
                                      debugPrint(
                                        "❌ Could NOT launch Google Maps → $mapUrl",
                                      );
                                    } else {
                                      debugPrint("✅ Google Maps launched");
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFilter() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              /// ==============================================
              /// SEARCH MODE
              /// ==============================================
              if (searchActive) ...[
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: TextField(
                    autofocus: true,
                    onChanged: (value) {
                      searchQuery = value;
                      applyFilters(); // live update
                    },
                    decoration: InputDecoration(
                      labelText: "Search",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            searchActive = false;
                            searchQuery = "";
                          });
                          applyFilters();
                        },
                      ),
                    ),
                  ),
                ),
              ]
              /// ==============================================
              /// DATE FILTER MODE
              /// ==============================================
              else if (dateFilterActive) ...[
                ElevatedButton(
                  onPressed: () async {
                    await pickDate(isFrom: true);
                    applyFilters();
                  },
                  child: Text(
                    fromDate == null
                        ? "From"
                        : "${fromDate!.day}-${fromDate!.month}-${fromDate!.year}",
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () async {
                    await pickDate(isFrom: false);
                    applyFilters();
                  },
                  child: Text(
                    toDate == null
                        ? "To"
                        : "${toDate!.day}-${toDate!.month}-${toDate!.year}",
                  ),
                ),
                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      sortOrder = sortOrder == "latest" ? "oldest" : "latest";
                    });
                    applyFilters();
                  },
                  child: Text(sortOrder == "latest" ? "Latest" : "Oldest"),
                ),

                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      dateFilterActive = false;
                      fromDate = null;
                      toDate = null;
                    });
                    applyFilters();
                  },
                ),
              ]
              /// ==============================================
              /// NORMAL MODE (default)
              /// ==============================================
              else ...[
                /// SEARCH BOX (non-editable)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        searchActive = true;
                        dateFilterActive = false;
                      });
                    },
                    child: const AbsorbPointer(
                      absorbing: true,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: "Search",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                /// FROM BUTTON
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      dateFilterActive = true;
                      searchActive = false;
                    });
                    pickDate(isFrom: true);
                  },
                  child: const Text("From"),
                ),
                const SizedBox(width: 8),

                /// TO BUTTON
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      dateFilterActive = true;
                      searchActive = false;
                    });
                    pickDate(isFrom: false);
                  },
                  child: const Text("To"),
                ),
                const SizedBox(width: 8),

                /// SORT BUTTON (always visible in normal mode)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      sortOrder = sortOrder == "latest" ? "oldest" : "latest";
                    });
                    applyFilters();
                  },
                  child: Text(sortOrder == "latest" ? "Latest" : "Oldest"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
