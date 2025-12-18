import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/restaurant_service.dart';
import 'restaurant_edit.dart';

import 'package:flutter_svg/flutter_svg.dart';

class RestaurantListPage extends StatefulWidget {
  final int userId;

  const RestaurantListPage({super.key, required this.userId});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  List<dynamic> allRestaurants = [];
  List<dynamic> filteredList = [];

  // FILTER VALUES
  String selectedDate = "Today";
  String selectedStatus = "All";
  TextEditingController searchCtrl = TextEditingController();

  // Map display labels -> normalized backend values (adjust RHS to match your backend)
  final Map<String, String> statusMap = {
    "All": "",
    "Leads": "leads",
    "Follows": "follows",
    "Closed": "closed",
    "Installation": "installation",
    "Conversion": "conversion",
  };

  // helper to normalize a string safely
  String _norm(String? s) => s?.toString().trim().toLowerCase() ?? "";

  @override
  void initState() {
    super.initState();
    loadAllRestaurants();
  }

  // ----------------------------------------------------------------------
  // LOAD RESTAURANTS
  // ----------------------------------------------------------------------
  Future<void> loadAllRestaurants() async {
    final list = await RestaurantService.getRestaurantsByUser(widget.userId);

    setState(() {
      allRestaurants = list;
      filteredList = list;
    });
  }

  // ----------------------------------------------------------------------
  // APPLY FILTERS
  // ----------------------------------------------------------------------
  void applyFilters() {
    List<dynamic> temp = allRestaurants;

    // ------------------------- DATE FILTER -------------------------
    final now = DateTime.now();

    temp = temp.where((r) {
      if (r["created_at"] == null) return false;
      final created = DateTime.parse(r["created_at"]);

      if (selectedDate == "Today") {
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      }

      if (selectedDate == "Yesterday") {
        final y = now.subtract(Duration(days: 1));
        return created.year == y.year &&
            created.month == y.month &&
            created.day == y.day;
      }

      if (selectedDate == "Last Week") {
        final start = now.subtract(Duration(days: 7));
        return created.isAfter(start) &&
            created.isBefore(now.add(Duration(days: 1)));
      }

      if (selectedDate == "This Month") {
        final start = DateTime(now.year, now.month, 1);
        return created.isAfter(start) &&
            created.isBefore(now.add(Duration(days: 1)));
      }

      if (selectedDate == "Last Month") {
        final prevMonth = DateTime(now.year, now.month - 1, 1);
        final lastDay = DateTime(now.year, now.month, 0);
        return created.isAfter(prevMonth) && created.isBefore(lastDay);
      }

      return true;
    }).toList();

    // Save this list to apply search + status independently
    List<dynamic> afterDateFilter = temp;

    // ---------------------------------------------------------
    // 2. SEARCH FILTER (should search across ALL restaurants)
    // ---------------------------------------------------------
    if (searchCtrl.text.isNotEmpty) {
      temp = allRestaurants.where((r) {
        final name = r["name"]?.toString().toLowerCase() ?? "";
        return name.contains(searchCtrl.text.toLowerCase());
      }).toList();
    } else {
      temp = afterDateFilter;
    }

    // ---------------------------------------------------------
    // 3. STATUS FILTER
    // ---------------------------------------------------------
    if (selectedStatus != "All") {
      final expected = _norm(statusMap[selectedStatus]);

      temp = temp.where((r) {
        final raw = r["res_type"];
        final resType = _norm(raw?.toString());

        print("BACKEND res_type: '${r["res_type"]}'  | expected: '$expected'");

        if (expected.isNotEmpty && resType == expected) return true;
        if (expected.isNotEmpty && resType.contains(expected)) return true;
        if (_norm(r["res_type"]) == _norm(selectedStatus)) return true;

        return false;
      }).toList();
    }

    setState(() => filteredList = temp);
  }

  // ----------------------------------------------------------------------
  // UI COMPONENTS
  // ----------------------------------------------------------------------

  Widget _searchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          SvgPicture.asset("assets/icons/search.svg", width: 22, height: 22),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => applyFilters(),
              decoration: InputDecoration(
                hintText: "Search by Restaurant Name",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateFilterDropdown() {
    final dateOptions = [
      "Today",
      "Yesterday",
      "Last Week",
      "This Month",
      "Last Month",
    ];

    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDate,
          icon: SvgPicture.asset("assets/icons/down_arrow.svg", width: 18),

          // Selected item display ONLY
          selectedItemBuilder: (_) {
            return dateOptions.map((e) {
              return Row(
                children: [
                  SvgPicture.asset(
                    "assets/icons/calendar.svg",
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    e,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }).toList();
          },

          // Dropdown List Items (NO ICONS)
          items: dateOptions.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e, style: TextStyle(fontSize: 15)),
            );
          }).toList(),

          onChanged: (value) {
            setState(() => selectedDate = value!);
            applyFilters();
          },
        ),
      ),
    );
  }

  Widget _statusFilterDropdown() {
    final statuses = [
      "All",
      "Leads",
      "Follows",
      "Closed",
      "Installation",
      "Conversion",
    ];

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: SvgPicture.asset("assets/icons/down_arrow.svg", width: 18),

          // Selected item shows icon if it is the selected item
          selectedItemBuilder: (_) {
            return statuses.map((status) {
              return Row(
                children: [
                  // Show icon ONLY for the currently selected status
                  if (selectedStatus == status)
                    SvgPicture.asset(
                      "assets/icons/status.svg",
                      width: 20,
                      height: 20,
                    ),
                  if (selectedStatus == status) SizedBox(width: 8),

                  Text(
                    status,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }).toList();
          },

          // Dropdown items — NO ICONS inside the list
          items: statuses.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status, style: TextStyle(fontSize: 15)),
            );
          }).toList(),

          onChanged: (value) {
            setState(() => selectedStatus = value!);
            applyFilters();
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // RESTAURANT LIST CARD
  // ----------------------------------------------------------------------

  Widget _restaurantCard(r) {
    Color statusColor(String? status) {
      switch (status) {
        case "leads":
          return Colors.blue;
        case "follows":
          return Colors.orange;
        case "installation":
          return Colors.purple;
        case "conversion":
          return Colors.green;
        case "closed":
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String statusLabel(String? status) {
      if (status == null || status.isEmpty) return "Unknown";
      return status[0].toUpperCase() + status.substring(1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- TOP ROW ----------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.asset(
                  "assets/icons/restaurant.svg",
                  width: 28,
                  height: 28,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r["name"] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor(r["res_type"]).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel(r["res_type"]),
                  style: TextStyle(
                    color: statusColor(r["res_type"]),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  bool? updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantEditPage(restaurant: r),
                    ),
                  );
                  if (updated == true) loadAllRestaurants();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    "assets/icons/edit.svg",
                    width: 20,
                    height: 20,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ---------------- STATUS BADGE ----------------

          // ---------------- ADDRESS ----------------
          Text(r["location"] ?? "", style: const TextStyle(height: 1.3)),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),

          // ---------------- CALL & DIRECTION ----------------
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse("tel:${r['phone']}")),
                  icon: const Icon(Icons.call, color: Colors.teal),
                  label: const Text(
                    "Call",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    final lat = r["latitude"];
                    final lng = r["longitude"];
                    final address = r["location"];

                    Uri uri;
                    if (lat != null &&
                        lng != null &&
                        lat.toString().isNotEmpty) {
                      uri = Uri.parse(
                        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
                      );
                    } else {
                      final encodedAddress = Uri.encodeComponent(address ?? "");
                      uri = Uri.parse(
                        "https://www.google.com/maps/dir/?api=1&destination=$encodedAddress",
                      );
                    }

                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.location_on, color: Colors.teal),
                  label: const Text(
                    "Direction",
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // MAIN UI
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text("My Leads", style: TextStyle(color: Colors.white)),
      ),

      bottomNavigationBar: _bottomNavBar(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),

            _searchBar(),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _dateFilterDropdown()),
                SizedBox(width: 12),
                Expanded(child: _statusFilterDropdown()),
              ],
            ),

            SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredList.length,
              itemBuilder: (context, i) => _restaurantCard(filteredList[i]),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // ----------------------------------------------------------------------
  Widget _bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,

      onTap: (index) {
        if (index == 0) Navigator.pop(context);
      },

      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/icons/home.svg",
            width: 26,
            colorFilter: ColorFilter.mode(
              Colors.grey.shade600,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            "assets/icons/home.svg",
            width: 28,
            colorFilter: const ColorFilter.mode(Colors.teal, BlendMode.srcIn),
          ),
          label: "Home",
        ),

        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            "assets/icons/leads.svg",
            width: 26,
            colorFilter: ColorFilter.mode(
              Colors.grey.shade600,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            "assets/icons/leads.svg",
            width: 28,
            colorFilter: const ColorFilter.mode(Colors.teal, BlendMode.srcIn),
          ),
          label: "My Leads",
        ),
      ],
    );
  }
}
