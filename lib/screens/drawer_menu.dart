import 'package:flutter/material.dart';

class DrawerMenu extends StatelessWidget {
  final String email;

  const DrawerMenu({super.key, required this.email});

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
          ElevatedButton(onPressed: () {}, child: const Text("Check In")),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: const Text("Check Out")),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: const Text("Visit")),
        ],
      ),
    );
  }
}
