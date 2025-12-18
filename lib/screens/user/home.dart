import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../services/restaurant_service.dart';
import '../../services/attendance_service.dart';
import 'restaurant_edit.dart';
import 'restaurant_form_page.dart';
import 'restaurant_list.dart';

class HomePage extends StatefulWidget {
  final String email;
  final int userId;
  final String username;

  const HomePage({
    super.key,
    required this.email,
    required this.userId,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Position>? positionStream;
  List<dynamic> filteredRestaurants = [];
  List<dynamic> allRestaurants = [];

  String? checkInTime;
  String? checkOutTime;
  bool hasCheckedIn = false;
  bool hasCheckedOut = false;

  void resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();

    final lastDate = prefs.getString("lastAttendanceDate");
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    if (lastDate != todayStr) {
      // New day → reset UI values
      setState(() {
        checkInTime = null;
        checkOutTime = null;
        hasCheckedIn = false;
        hasCheckedOut = false;
      });

      // New day → reset stored values
      await prefs.setString("checkInTime", "");
      await prefs.setString("checkOutTime", "");
      await prefs.setString("lastAttendanceDate", todayStr);
    }
  }

  @override
  void initState() {
    super.initState();
    loadCheckState().then((_) => resetIfNewDay());
    loadRestaurants();
    startLocationTracking();
  }

  // int _selectedIndex = 0;

  // void _onTabTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  Future<void> loadCheckState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCheckIn = prefs.getString("checkInTime");
    final savedCheckOut = prefs.getString("checkOutTime");

    setState(() {
      checkInTime = (savedCheckIn != null && savedCheckIn.isNotEmpty)
          ? savedCheckIn
          : null;
      checkOutTime = (savedCheckOut != null && savedCheckOut.isNotEmpty)
          ? savedCheckOut
          : null;

      hasCheckedIn = checkInTime != null;
      hasCheckedOut = checkOutTime != null;
    });
  }

  Future<void> saveCheckState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("checkInTime", checkInTime ?? "");
    await prefs.setString("checkOutTime", checkOutTime ?? "");
    await prefs.setBool("hasCheckedIn", hasCheckedIn);
    await prefs.setBool("hasCheckedOut", hasCheckedOut);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$min $period";
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> loadRestaurants() async {
    final list = await RestaurantService.getRestaurantsByUser(widget.userId);

    setState(() {
      allRestaurants = list;
      filteredRestaurants = list;
    });
  }

  void startLocationTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) async {
          final addr = await _getAddress(pos.latitude, pos.longitude);

          await RestaurantService.trackLocation(
            userId: widget.userId,
            email: widget.email,
            latitude: pos.latitude.toString(),
            longitude: pos.longitude.toString(),
            address: addr,
          );
        });
  }

  Future<String> _getAddress(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    final p = placemarks.first;
    return "${p.street}, ${p.locality}, ${p.country}";
  }

  // ----------------------------------------------------------------------
  // CHECK IN
  // ----------------------------------------------------------------------
  Future<void> doCheckIn() async {
    final now = TimeOfDay.now();

    setState(() {
      // New check-in should always clear old checkout
      checkInTime = _formatTime(now);
      checkOutTime = null;

      hasCheckedIn = true;
      hasCheckedOut = false;
    });

    await saveCheckState();
    await AttendanceService.checkIn(widget.userId, widget.email);
  }

  // ----------------------------------------------------------------------
  // CHECK OUT
  // ----------------------------------------------------------------------
  Future<void> doCheckOut() async {
    final now = TimeOfDay.now();

    setState(() {
      hasCheckedOut = true;
      checkOutTime = _formatTime(now);
    });

    await saveCheckState();
    await AttendanceService.checkOut(widget.userId, widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        centerTitle: true,
        title: const Text(
          "Home",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      bottomNavigationBar: _bottomNavBar(),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greeting(),
            const SizedBox(height: 10),
            _checkInSection(),
            const SizedBox(height: 10),
            _visitButton(),
            const SizedBox(height: 20),
            _latestLeadsHeader(),
            const SizedBox(height: 10),
            _restaurantList(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // GREETING
  // ----------------------------------------------------------------------
  Widget _greeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello Hi !",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Good Morning ${widget.username}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade200,
            child: SvgPicture.asset(
              "assets/icons/user_avatar.svg",
              width: 26,
              height: 26,
              // colorFilter: ColorFilter.mode(
              //   Colors.grey.shade700,
              //   BlendMode.srcIn,
              // ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CHECK-IN UI CARD
  // -------------------------------------------------------------
  Widget _checkInSection() {
    final today = DateTime.now();

    final formattedDate =
        "${_getWeekday(today.weekday)}, ${today.day} ${_getMonth(today.month)} ${today.year} (Today)";

    final isCheckInDisabled = checkInTime != null && checkOutTime == null;
    final isCheckOutDisabled = checkInTime == null || checkOutTime != null;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFE0F7F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // DATE DISPLAY
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 18, color: Colors.black87),
              SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // CENTERED DATE ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _styledButton(
                label: "Check In",
                icon: Icons.login,
                color: Colors.teal,
                disabled: isCheckInDisabled,
                onTap: () async => await doCheckIn(),
              ),
              _styledButton(
                label: "Check Out",
                icon: Icons.logout,
                color: Colors.teal.shade300,
                disabled: isCheckOutDisabled,
                onTap: () async => await doCheckOut(),
              ),
            ],
          ),
          SizedBox(height: 10),

          // CENTERED STATUS TEXT
          Text(
            checkInTime == null
                ? "No check-in yet"
                : checkOutTime == null
                ? "Checkin Time : $checkInTime"
                : "Checkout Time : $checkOutTime",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _styledButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 50,
          margin: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: disabled ? Colors.teal.shade100 : color,
            borderRadius: BorderRadius.circular(40), // Capsule button
            boxShadow: [
              if (!disabled)
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: disabled ? Colors.white70 : Colors.white,
                size: 22,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: disabled ? Colors.white70 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWeekday(int day) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[day - 1];
  }

  String _getMonth(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  // -------------------------------------------------------------
  // CHECK-IN / OUT BUTTON WIDGET
  // -------------------------------------------------------------
  // Widget _checkButton({
  //   required String label,
  //   required Color color,
  //   required bool disabled,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: disabled ? null : onTap,
  //     child: Container(
  //       width: 130,
  //       height: 45,
  //       decoration: BoxDecoration(
  //         color: disabled ? Colors.grey.shade300 : color,
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Center(
  //         child: Text(
  //           label,
  //           style: TextStyle(
  //             color: disabled ? Colors.black38 : Colors.white,
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ----------------------------------------------------------------------
  // VISIT BUTTON
  // ----------------------------------------------------------------------
  Widget _visitButton() {
    return GestureDetector(
      onTap: () async {
        final bool? added = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantFormPage(
              userId: widget.userId,
              email: widget.email,
              username: widget.username,
            ),
          ),
        );

        if (added == true) {
          await loadRestaurants(); // 🔥 refresh immediately
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.teal, Colors.greenAccent],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Visit",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset(
                  "assets/icons/up_arrow.svg",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------------------
  Widget _latestLeadsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        "Latest Leads",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // RESTAURANT LIST
  // ----------------------------------------------------------------------
  Widget _restaurantList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredRestaurants.length > 2
          ? 2
          : filteredRestaurants.length,

      itemBuilder: (context, i) {
        final r = filteredRestaurants[i];

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- TOP ROW ----------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SvgPicture.asset(
                      "assets/icons/restaurant.svg",
                      height: 28,
                      width: 28,
                      color: Colors.teal,
                    ),
                  ),

                  SizedBox(width: 10),

                  // Restaurant Name
                  Expanded(
                    child: Text(
                      r["name"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Edit Icon
                  InkWell(
                    onTap: () async {
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantEditPage(restaurant: r),
                        ),
                      );
                      if (updated == true) loadRestaurants();
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SvgPicture.asset(
                        "assets/icons/edit.svg",
                        height: 22,
                        width: 22,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // ---------------- ADDRESS ----------------
              Text(
                "${r['location'] ?? ''}",
                style: TextStyle(color: Colors.black87, height: 1.4),
              ),

              SizedBox(height: 16),

              Divider(height: 1, color: Colors.grey.shade300),

              // ---------------- BOTTOM BUTTONS ----------------
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse("tel:${r['phone']}")),
                      icon: Icon(Icons.call, color: Colors.teal),
                      label: Text(
                        "Call",
                        style: TextStyle(color: Colors.teal, fontSize: 16),
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
                          // GPS-based navigation
                          uri = Uri.parse(
                            "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
                          );
                        } else {
                          // Manual address-based navigation
                          final encodedAddress = Uri.encodeComponent(
                            address ?? "",
                          );
                          uri = Uri.parse(
                            "https://www.google.com/maps/dir/?api=1&destination=$encodedAddress",
                          );
                        }

                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },

                      icon: Icon(Icons.location_on, color: Colors.teal),
                      label: Text(
                        "Direction",
                        style: TextStyle(color: Colors.teal, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // ----------------------------------------------------------------------
  Widget _bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,

      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantListPage(userId: widget.userId),
            ),
          );
        }
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
