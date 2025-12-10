import 'package:flutter/material.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';

class RestaurantEditPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const RestaurantEditPage({super.key, required this.restaurant});

  @override
  State<RestaurantEditPage> createState() => _RestaurantEditPageState();
}

class _RestaurantEditPageState extends State<RestaurantEditPage> {
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController contactCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController areaCtrl;
  late TextEditingController cityCtrl;

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
  void initState() {
    super.initState();

    final r = widget.restaurant;

    nameCtrl = TextEditingController(text: r["name"]);
    phoneCtrl = TextEditingController(text: r["phone"]);
    contactCtrl = TextEditingController(text: r["contact"]);

    // Split stored location
    final locationParts = (r["location"] ?? "").split(", ");

    addressCtrl = TextEditingController(
      text: locationParts.isNotEmpty ? locationParts[0] : "",
    );
    areaCtrl = TextEditingController(
      text: locationParts.length > 1 ? locationParts[1] : "",
    );
    cityCtrl = TextEditingController(
      text: locationParts.length > 2 ? locationParts[2] : "",
    );

    restaurantType = r["res_type"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Restaurant")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Restaurant Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(
                labelText: "Contact Person",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              value: restaurantType,
              items: restaurantTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (v) => setState(() => restaurantType = v),
            ),

            const SizedBox(height: 20),
            const Text(
              "Address Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: areaCtrl,
              decoration: const InputDecoration(
                labelText: "Area",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(
                labelText: "City",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                // Combine address
                String fullAddress =
                    "${addressCtrl.text}, ${areaCtrl.text}, ${cityCtrl.text}";

                // Capture new GPS location
                final loc = await LocationService.getLocationDetails();

                bool ok = await RestaurantService.updateRestaurant(
                  widget.restaurant["id"],
                  nameCtrl.text,
                  restaurantType ?? "",
                  phoneCtrl.text,
                  contactCtrl.text,
                  fullAddress,
                  loc["latitude"].toString(),
                  loc["longitude"].toString(),
                );

                if (ok) Navigator.pop(context, true);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
