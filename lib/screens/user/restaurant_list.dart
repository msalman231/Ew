import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/restaurant_service.dart';
import 'restaurant_edit.dart';

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
      filteredList = list; // default full list
    });
  }

  // ----------------------------------------------------------------------
  // APPLY FILTERS
  // ----------------------------------------------------------------------
  void applyFilters() {
    List<dynamic> temp = allRestaurants;

    // SEARCH FILTER
    if (searchCtrl.text.isNotEmpty) {
      temp = temp.where((r) {
        final name = r["name"]?.toString().toLowerCase() ?? "";
        return name.contains(searchCtrl.text.toLowerCase());
      }).toList();
    }

    // DATE FILTER
    temp = temp.where((r) {
      if (r["created_at"] == null) return true;

      final created = DateTime.parse(r["created_at"]);
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      if (selectedDate == "Today") {
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      }

      if (selectedDate == "Yesterday") {
        return created.year == yesterday.year &&
            created.month == yesterday.month &&
            created.day == yesterday.day;
      }

      return true;
    }).toList();

    // STATUS FILTER
    if (selectedStatus != "All") {
      temp = temp.where((r) {
        final status = r["status"]?.toString().toLowerCase() ?? "";
        return status == selectedStatus.toLowerCase();
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
          Image.asset(
            "assets/images/search.png", // <-- your search icon
            width: 22,
            height: 22,
          ),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDate,
          icon: Image.asset(
            "assets/images/down_arrow.png", // <-- your dropdown arrow
            width: 18,
          ),
          items: ["Today", "Yesterday"].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Image.asset(
                    "assets/images/calendar.png", // <-- your calendar icon
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(width: 8),
                  Text(e),
                ],
              ),
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
      "Future Follows",
      "Closed",
      "Installation",
      "Conversion",
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: Image.asset(
            "assets/images/down_arrow.png", // <-- your dropdown arrow
            width: 18,
          ),
          items: statuses.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Image.asset(
                    "assets/images/setting.png", // <-- your filter icon
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(width: 8),
                  Text(e),
                ],
              ),
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
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  "assets/images/shop.png",
                  width: 28,
                  height: 28,
                  color: Colors.teal,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  r["name"],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    "assets/images/edit.png",
                    width: 20,
                    height: 20,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          // ADDRESS
          Text(r["location"] ?? "", style: TextStyle(height: 1.3)),

          SizedBox(height: 16),
          Divider(color: Colors.grey.shade300),

          // CALL & DIRECTION BUTTONS
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse("tel:${r['phone']}")),
                  icon: Icon(Icons.call, color: Colors.teal),
                  label: Text("Call", style: TextStyle(color: Colors.teal)),
                ),
              ),
              Container(height: 30, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    final uri = Uri.parse(
                      "https://www.google.com/maps/dir/?api=1&destination=${r['latitude']},${r['longitude']}",
                    );
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: Icon(Icons.location_on, color: Colors.teal),
                  label: Text(
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
      currentIndex: 1, // current page is "My Leads"
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 0) Navigator.pop(context);
      },
      items: [
        BottomNavigationBarItem(
          icon: Image.asset("assets/images/home.png", width: 28),
          activeIcon: Image.asset("assets/images/home_filled.png", width: 30),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Image.asset("assets/images/leads.png", width: 28),
          activeIcon: Image.asset("assets/images/leads_filled.png", width: 30),
          label: "My Leads",
        ),
      ],
    );
  }
}
