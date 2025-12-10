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

  // conversion fields
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController costCtrl = TextEditingController();
  final TextEditingController discountCtrl = TextEditingController();
  final TextEditingController balanceCtrl = TextEditingController();
  final TextEditingController commentCtrl = TextEditingController();

  String? restaurantType;
  String? selectedProduct;
  String? selectedPaymentMethod;
  List<String> selectedPos = [];

  DateTime? savedDate;

  final List<String> restaurantTypes = [
    "Leads",
    "Follows",
    "Future Follows",
    "Closed",
    "Installation",
    "Conversion",
  ];

  final List<String> products = ["Retail Pos", "Restaurant Pos"];
  final List<String> posOptions = ["Mobile Pos", "Web Pos", "Waiter App"];
  final List<String> paymentOptions = ["Card", "Cash", "Online-UPI"];

  @override
  void initState() {
    super.initState();

    final r = widget.restaurant;

    nameCtrl = TextEditingController(text: r["name"] ?? "");
    phoneCtrl = TextEditingController(text: r["phone"] ?? "");
    contactCtrl = TextEditingController(text: r["contact"] ?? "");

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

    // Load POS Multi if exists
    String? posMulti = r["pos_multi"];
    if (posMulti != null && posMulti.isNotEmpty) {
      selectedPos = posMulti.split(",").map((e) => e.trim()).toList();
    }
    // Load discount as percentage instead of decimal
    String? discountValue = r["discount"];
    if (discountValue != null && discountValue.isNotEmpty) {
      double dec = double.tryParse(discountValue) ?? 0;
      discountCtrl.text = (dec * 100).toStringAsFixed(
        0,
      ); // show 5 instead of 0.05
    }

    restaurantType = r["res_type"];

    // Try to prefill conversion fields if present in restaurant map
    // Adjust keys below as per your API response
    selectedProduct = r["product"] != null ? r["product"].toString() : null;
    selectedPaymentMethod = r["payment_method"] != null
        ? r["payment_method"].toString()
        : null;

    // selectedPos stored as comma separated values in DB (if so)
    final posRaw = r["pos_options"] ?? r["pos"] ?? r["selected_pos"];
    if (posRaw != null && posRaw is String && posRaw.isNotEmpty) {
      selectedPos = posRaw.split(",").map((s) => s.trim()).toList();
    }

    emailCtrl.text = r["customer_email"] ?? r["email"] ?? "";
    costCtrl.text = r["cost"]?.toString() ?? "";
    discountCtrl.text = r["discount"]?.toString() ?? "";
    balanceCtrl.text = r["balance"]?.toString() ?? "";
    commentCtrl.text = r["comment"] ?? r["comments"] ?? "";

    // Parse saved_date if exists (accepts ISO string)
    final sd = r["saved_date"] ?? r["form_saved_date"] ?? r["savedAt"];
    if (sd != null && sd is String && sd.isNotEmpty) {
      try {
        savedDate = DateTime.tryParse(sd);
      } catch (_) {
        savedDate = null;
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    contactCtrl.dispose();
    addressCtrl.dispose();
    areaCtrl.dispose();
    cityCtrl.dispose();

    emailCtrl.dispose();
    costCtrl.dispose();
    discountCtrl.dispose();
    balanceCtrl.dispose();
    commentCtrl.dispose();

    super.dispose();
  }

  Future<void> _pickSavedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: savedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => savedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Restaurant"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Basic Information"),
            _card(
              children: [
                _textField(nameCtrl, "Restaurant Name"),
                const SizedBox(height: 12),
                _textField(
                  phoneCtrl,
                  "Phone Number",
                  keyboard: TextInputType.phone,
                  maxLen: 10,
                ),
                const SizedBox(height: 12),
                _textField(contactCtrl, "Contact Person"),
              ],
            ),

            const SizedBox(height: 16),
            _sectionTitle("Status"),
            _card(
              children: [
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
              ],
            ),

            const SizedBox(height: 16),
            _sectionTitle("Address Details"),
            _card(
              children: [
                _textField(addressCtrl, "Address"),
                const SizedBox(height: 10),
                _textField(areaCtrl, "Area"),
                const SizedBox(height: 10),
                _textField(cityCtrl, "City"),
              ],
            ),

            // Saved date picker
            const SizedBox(height: 16),
            _sectionTitle("Form Saved Date"),
            _card(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        savedDate == null
                            ? "No date selected"
                            : "${savedDate!.day}-${savedDate!.month}-${savedDate!.year}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Pick Date"),
                      onPressed: _pickSavedDate,
                    ),
                  ],
                ),
              ],
            ),

            // Conditional sections
            if (restaurantType == "Conversion") ...[
              const SizedBox(height: 16),
              _sectionTitle("Conversion Details"),
              _card(children: _conversionFields()),
            ],

            if (restaurantType == "Closed") ...[
              const SizedBox(height: 16),
              _sectionTitle("Closed Reason"),
              _card(
                children: [
                  TextField(
                    controller:
                        commentCtrl, // reuse commentCtrl or create dedicated reasonCtrl
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _updateRestaurant,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: const Text("Update"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _conversionFields() {
    return [
      _textField(emailCtrl, "Customer Email"),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "Product Select",
          border: OutlineInputBorder(),
        ),
        value: selectedProduct,
        items: products
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (v) => setState(() {
          selectedProduct = v;
          selectedPos.clear();
        }),
      ),
      const SizedBox(height: 12),
      if (selectedProduct == "Restaurant Pos") ...[
        const Text(
          "POS Options",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Column(
          children: posOptions.map((pos) {
            return CheckboxListTile(
              title: Text(pos),
              value: selectedPos.contains(pos),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    if (!selectedPos.contains(pos)) {
                      selectedPos.add(pos);
                    }
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
      DropdownButtonFormField<String>(
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
      _textField(costCtrl, "Cost", keyboard: TextInputType.number),
      const SizedBox(height: 12),
      _textField(discountCtrl, "Discount %", keyboard: TextInputType.number),
      const SizedBox(height: 12),
      _textField(balanceCtrl, "Balance to Pay", keyboard: TextInputType.number),
      const SizedBox(height: 12),
      TextField(
        controller: commentCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: "Comments",
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

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
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> _updateRestaurant() async {
    // Basic validation
    if (nameCtrl.text.trim().isEmpty) {
      _toast("Restaurant name is required");
      return;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _toast("Phone number is required");
      return;
    }

    // Rebuild full address
    String fullAddress =
        "${addressCtrl.text}, ${areaCtrl.text}, ${cityCtrl.text}";

    // Get current GPS (optional) — keep as before
    final loc = await LocationService.getLocationDetails();

    // If your RestaurantService.updateRestaurant signature doesn't accept savedDate,
    // add a corresponding parameter or create a new API method.
    // Here we attempt to pass savedDate as an ISO string (or null).
    bool ok = await RestaurantService.updateRestaurant(
      widget.restaurant["id"],
      nameCtrl.text,
      restaurantType ?? "",
      phoneCtrl.text,
      contactCtrl.text,
      fullAddress,
      loc["latitude"].toString(),
      loc["longitude"].toString(),

      email: emailCtrl.text,
      product: selectedProduct,
      posMulti: selectedPos.join(","),
      cost: costCtrl.text,
      discount: (discountCtrl.text.isNotEmpty
          ? (double.parse(discountCtrl.text) / 100).toString()
          : ""),
      balance: balanceCtrl.text,
      paymentMethod: selectedPaymentMethod,
      comment: commentCtrl.text,
      closedReason: restaurantType == "Closed" ? commentCtrl.text : null,
      savedDate: savedDate?.toIso8601String(),
    );

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _toast("Update failed");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
