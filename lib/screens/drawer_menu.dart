import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import 'restaurant_form_page.dart';

class DrawerMenu extends StatelessWidget {
  final int userId;
  final String email;
  final Function()? onVisitCompleted;

  const DrawerMenu({
    super.key,
    required this.userId,
    required this.email,
    this.onVisitCompleted,
  });

  // Simple toast popup
  void showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 10),
          Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // ============================
          // CHECK-IN BUTTON
          // ============================
          ElevatedButton(
            onPressed: () async {
              bool ok = await AttendanceService.checkIn(userId, email);
              if (ok) {
                showMsg(context, "Check-In Successful");
              } else {
                showMsg(context, "Check-In Failed");
              }
            },
            child: const Text("Check In"),
          ),

          const SizedBox(height: 10),

          // ============================
          // CHECK-OUT BUTTON
          // ============================
          ElevatedButton(
            onPressed: () async {
              bool ok = await AttendanceService.checkOut(userId, email);
              if (ok) {
                showMsg(context, "Check-Out Successful");
              } else {
                showMsg(context, "Check-Out Failed");
              }
            },
            child: const Text("Check Out"),
          ),

          const SizedBox(height: 10),

          // ============================
          // VISIT BUTTON
          // ============================
          ElevatedButton(
            onPressed: () async {
              bool? saved = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantFormPage(userId: userId),
                ),
              );

              if (saved == true && onVisitCompleted != null) {
                onVisitCompleted!();
              }
            },
            child: const Text("Visit"),
          ),
        ],
      ),
    );
  }
}
