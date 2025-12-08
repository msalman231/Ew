import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';

class RestaurantFormPage extends StatefulWidget {
  const RestaurantFormPage({super.key});

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  String? restaurantType;

  final List<String> restaurantTypes = [
    "Leads",
    "Follows",
    "Future Follows",
    "Closed",
    "Installation",
    "Conversion",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Restaurant")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Restaurent Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// Phone (Integer keyboard)
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// Contact (Integer keyboard)
            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(
                labelText: "Contact Person Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            /// RESTAURANT TYPE DROPDOWN
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              value: restaurantType,
              items: restaurantTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => restaurantType = value),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                bool ok = await RestaurantService.addRestaurant(
                  nameCtrl.text,
                  restaurantType ?? "",
                  phoneCtrl.text,
                  contactCtrl.text,
                );

                Navigator.pop(context, ok);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
