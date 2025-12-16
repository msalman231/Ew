import 'package:efficient_works/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/attendance_service.dart';
import 'user_list_page.dart';
import 'restaurant_list_page.dart';
import 'restaurant_pie_chart.dart';

class AdminHomePage extends StatefulWidget {
  final String email;
  final int userId;
  final String username;

  const AdminHomePage({
    super.key,
    required this.email,
    required this.userId,
    required this.username,
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String? checkInTime;
  String? checkOutTime;
  bool hasCheckedIn = false;
  bool hasCheckedOut = false;

  // bool get hasCheckedIn => checkInTime != null;
  // bool get hasCheckedOut => checkOutTime != null;

  @override
  void initState() {
    super.initState();
    _loadCheckState().then((_) => _resetIfNewDay());
  }

  // ------------------------------------------------------
  // LOAD / RESET DAILY STATE
  // ------------------------------------------------------
  Future<void> _loadCheckState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      checkInTime = prefs.getString("checkInTime");
      checkOutTime = prefs.getString("checkOutTime");
    });
  }

  Future<void> _resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    final lastDate = prefs.getString("lastAttendanceDate");

    if (lastDate != today) {
      await prefs.setString("lastAttendanceDate", today);
      await prefs.setString("checkInTime", "");
      await prefs.setString("checkOutTime", "");

      setState(() {
        checkInTime = null;
        checkOutTime = null;
      });
    }
  }

  Future<void> saveCheckState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("checkInTime", checkInTime ?? "");
    await prefs.setString("checkOutTime", checkOutTime ?? "");
    await prefs.setBool("hasCheckedIn", hasCheckedIn);
    await prefs.setBool("hasCheckedOut", hasCheckedOut);
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

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$min $period";
  }

  // ------------------------------------------------------
  // UI
  // ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isCheckInDisabled = hasCheckedIn && !hasCheckedOut;
    final isCheckOutDisabled = !hasCheckedIn || hasCheckedOut;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,

      appBar: AppBar(
        title: const Text("Admin Home"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutPopup(context),
          ),
        ],
      ),

      bottomNavigationBar: _bottomMenu(context),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greeting(),

            _checkInCard(),

            // -------------------------------
            // PIE CHART SECTION (ADD HERE)
            // -------------------------------
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Leads Distribution",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<dynamic>>(
                    future:
                        RestaurantService.getRestaurants(), // ✅ ALL restaurants
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("No restaurants found"),
                        );
                      }

                      return RestaurantPieChart(
                        restaurants: snapshot.data!, // ✅ pass all data
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            backgroundImage: AssetImage("assets/images/user_avatar.png"),
          ),
        ],
      ),
    );
  }

  Widget _checkInCard() {
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

  void _showLogoutPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
      ),
    );
  }

  Widget _bottomMenu(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.people, size: 32),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserListPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu, size: 32),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RestaurantListPage()),
            ),
          ),
        ],
      ),
    );
  }
}
