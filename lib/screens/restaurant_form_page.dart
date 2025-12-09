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

  // Conversion fields
  final emailCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final balanceCtrl = TextEditingController();
  final commentCtrl = TextEditingController();

  String? selectedProduct;
  String? selectedPaymentMethod;
  List<String> selectedPos = [];

  final List<String> products = ["Retail Pos", "Restaurant Pos"];
  final List<String> posOptions = ["Mobile Pos", "Web Pos", "Waiter App"];
  final List<String> paymentOptions = ["Card", "Cash", "Online-UPI"];

  // Closed field
  final reasonCtrl = TextEditingController();

  // Others
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
            _textField(nameCtrl, "Restaurant Name"),
            const SizedBox(height: 12),

            _textField(
              phoneCtrl,
              "Phone Number",
              keyboard: TextInputType.number,
              maxLen: 10,
            ),
            const SizedBox(height: 12),

            _textField(contactCtrl, "Contact Person Name"),
            const SizedBox(height: 20),

            /// STATUS DROPDOWN
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              value: restaurantType,
              items: restaurantTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
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

            const SizedBox(height: 20),

            /// 🔥 SHOW CONVERSION FIELDS
            if (restaurantType == "Conversion") _buildConversionForm(),

            /// 🔥 SHOW CLOSED REASON FIELD
            if (restaurantType == "Closed") _buildClosedReason(),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveRestaurant,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SAVE FUNCTION
  // =============================================================
  Future<void> _saveRestaurant() async {
    if (nameCtrl.text.trim().isEmpty) {
      return _toast("Restaurant Name is required");
    }
    if (phoneCtrl.text.trim().isEmpty) {
      return _toast("Phone Number is required");
    }
    if (restaurantType == null) {
      return _toast("Please select a Status");
    }

    // Get address
    final loc = await LocationService.getLocationDetails();
    final addressToSend = useManualAddress ? manualAddress! : loc["address"];

    bool ok = await RestaurantService.addRestaurant(
      widget.userId,
      nameCtrl.text,
      restaurantType ?? "",
      phoneCtrl.text,
      contactCtrl.text,
      addressToSend ?? "",
      loc["latitude"].toString(),
      loc["longitude"].toString(),

      emailCtrl.text,
      selectedProduct ?? "",
      selectedPos.join(","),

      costCtrl.text,
      discountCtrl.text,
      balanceCtrl.text,
      selectedPaymentMethod,
      commentCtrl.text,
      reasonCtrl.text,
    );

    Navigator.pop(context, ok);
  }

  // =============================================================
  // UI COMPONENTS
  // =============================================================

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboard = TextInputType.text,
    int? maxLen,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLength: maxLen,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildConversionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          "Conversion Form",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Email
        _textField(emailCtrl, "E-Mail"),
        const SizedBox(height: 12),

        // PRODUCT SELECT
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: "Product Select",
            border: OutlineInputBorder(),
          ),
          value: selectedProduct,
          items: products
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) {
            setState(() {
              selectedProduct = v;
              selectedPos.clear(); // Reset POS when product changes
            });
          },
        ),
        const SizedBox(height: 12),

        // ⭐ SHOW POS OPTIONS ONLY IF "Restaurant Pos" SELECTED
        if (selectedProduct == "Restaurant Pos") ...[
          const Text(
            "Select POS Options:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          Column(
            children: posOptions.map((pos) {
              return CheckboxListTile(
                title: Text(pos),
                value: selectedPos.contains(pos),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedPos.add(pos);
                    } else {
                      selectedPos.remove(pos);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // PAYMENT METHOD DROPDOWN
        DropdownButtonFormField(
          decoration: const InputDecoration(
            labelText: "Payment Method",
            border: OutlineInputBorder(),
          ),
          value: selectedPaymentMethod,
          items: paymentOptions
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => selectedPaymentMethod = v),
        ),
        const SizedBox(height: 12),

        // COST
        _textField(costCtrl, "Cost", keyboard: TextInputType.number),
        const SizedBox(height: 12),

        // DISCOUNT
        _textField(discountCtrl, "Discount %", keyboard: TextInputType.number),
        const SizedBox(height: 12),

        // BALANCE
        _textField(
          balanceCtrl,
          "Balance to Pay",
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 12),

        // COMMENT FIELD
        TextField(
          controller: commentCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Comment",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildClosedReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          "Closed Reason",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Reason",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
  final commentCtrl = TextEditingController();

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
