import 'package:flutter/material.dart';
import '../../services/attendance_service.dart';
import 'restaurant_form_page.dart';
import 'dart:ui';

class DrawerMenu extends StatelessWidget {
  final int userId;
  final String email;
  final String username;
  final Function()? onVisitCompleted;

  const DrawerMenu({
    super.key,
    required this.userId,
    required this.email,
    required this.username,
    this.onVisitCompleted,
  });

  // Simple toast popup
  void showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          /// ---- Background Gradient (same as login.dart) ----
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 247, 247, 247), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// ---- Liquid Glass Blob Effects (same as login.dart) ----
          Positioned(
            top: -60,
            right: -40,
            child: _blob(220, Colors.pinkAccent),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _blob(250, Colors.blueAccent),
          ),

          /// ---- Glass Drawer Box ----
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),

                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    color: Colors.white.withOpacity(0.1),
                  ),

                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      /// Avatar
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// USERNAME
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      /// EMAIL
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// ---- Buttons ----
                      _drawerButton(
                        label: "Check In",
                        icon: Icons.login,
                        onTap: () async {
                          bool ok = await AttendanceService.checkIn(
                            userId,
                            email,
                          );
                          showMsg(
                            context,
                            ok ? "Check-In Successful" : "Check-In Failed",
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      _drawerButton(
                        label: "Check Out",
                        icon: Icons.logout,
                        onTap: () async {
                          bool ok = await AttendanceService.checkOut(
                            userId,
                            email,
                          );
                          showMsg(
                            context,
                            ok ? "Check-Out Successful" : "Check-Out Failed",
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      _drawerButton(
                        label: "Visit",
                        icon: Icons.store,
                        onTap: () async {
                          bool? saved = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RestaurantFormPage(userId: userId),
                            ),
                          );

                          if (saved == true && onVisitCompleted != null) {
                            onVisitCompleted!();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.5),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: const SizedBox(),
      ),
    );
  }
}
