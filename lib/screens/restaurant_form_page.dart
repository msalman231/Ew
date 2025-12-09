import 'package:flutter/material.dart';
import '../services/location_service.dart';

import '../services/restaurant_service.dart';

class RestaurantFormPage extends StatefulWidget {
  final int userId;

  const RestaurantFormPage({super.key, required this.userId});

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final contactCtrl = TextEditingController();

  String? restaurantType;
  String? manualAddress;
  bool useManualAddress = false;

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
                labelText: "Restaurant Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            /// Phone (Integer keyboard)
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.number,
              maxLength: 10,
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
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ManualAddressPopup(
                    onSave: (address) {
                      setState(() {
                        manualAddress = address;
                        useManualAddress = true;
                      });
                    },
                  ),
                );
              },
              child: const Text("Add Address Manually"),
            ),

            ElevatedButton(
              onPressed: () async {
                // ⭐ VALIDATION
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Restaurant Name is required"),
                    ),
                  );
                  return;
                }

                if (phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Phone Number is required")),
                  );
                  return;
                }

                if (restaurantType == null || restaurantType!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a Status")),
                  );
                  return;
                }

                late String addressToSend;

                if (useManualAddress) {
                  addressToSend = manualAddress ?? "";
                } else {
                  final loc = await LocationService.getLocationDetails();
                  addressToSend = loc["address"] ?? "";
                }

                final loc = await LocationService.getLocationDetails();

                bool ok = await RestaurantService.addRestaurant(
                  widget.userId,
                  nameCtrl.text,
                  restaurantType ?? "",
                  phoneCtrl.text,
                  contactCtrl.text,
                  addressToSend,
                  (loc["latitude"] ?? "").toString(),
                  (loc["longitude"] ?? "").toString(),
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

class ManualAddressPopup extends StatefulWidget {
  final Function(String) onSave;

  const ManualAddressPopup({super.key, required this.onSave});

  @override
  State<ManualAddressPopup> createState() => _ManualAddressPopupState();
}

class _ManualAddressPopupState extends State<ManualAddressPopup> {
  final addressCtrl = TextEditingController();
  final areaCtrl = TextEditingController();
  final cityCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter Address"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: addressCtrl,
            decoration: const InputDecoration(labelText: "Address"),
          ),
          TextField(
            controller: areaCtrl,
            decoration: const InputDecoration(labelText: "Area"),
          ),
          TextField(
            controller: cityCtrl,
            decoration: const InputDecoration(labelText: "City"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final fullAddress =
                "${addressCtrl.text}, ${areaCtrl.text}, ${cityCtrl.text}"
                    .trim();

            widget.onSave(fullAddress);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
