import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/restaurant_service.dart';

class RestaurantFormPage extends StatefulWidget {
  final int userId;
  final String email;
  final String username;

  const RestaurantFormPage({
    super.key,
    required this.userId,
    required this.email,
    required this.username,
  });

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
  bool isLoading = false;

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/home",
              (route) => false,
              arguments: {
                "email": widget.email,
                "userId": widget.userId,
                "username": widget.username,
              },
            );
          },
        ),
        title: const Text(
          "Add Restaurant",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),

      backgroundColor: Colors.grey.shade100,

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
                  keyboard: TextInputType.number,
                  maxLen: 10,
                ),
                const SizedBox(height: 12),
                _textField(contactCtrl, "Contact Person Name"),
              ],
            ),

            const SizedBox(height: 20),

            _sectionTitle("Status"),

            _card(
              children: [
                DropdownButtonFormField<String>(
                  decoration: _dropdownStyle("Status"),
                  value: restaurantType,
                  items: restaurantTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => restaurantType = value),
                ),
              ],
            ),

            const SizedBox(height: 10),

            TextButton.icon(
              icon: const Icon(Icons.location_on_outlined),
              label: const Text("Add Address Manually"),
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
            ),

            if (useManualAddress && manualAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Address: $manualAddress",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            /// CONDITIONAL SECTIONS
            if (restaurantType == "Conversion") _buildConversionForm(),
            if (restaurantType == "Closed") _buildClosedReason(),

            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          bool ok = await _saveRestaurant();

                          setState(() => isLoading = false);

                          if (ok == true) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/home",
                              (route) => false,
                              arguments: {
                                "email": widget.email,
                                "userId": widget.userId,
                                "username": widget.username,
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SAVE FUNCTION
  // =============================================================
  Future<bool> _saveRestaurant() async {
    if (nameCtrl.text.trim().isEmpty) {
      _toast("Restaurant Name is required");
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _toast("Phone Number is required");
      return false;
    }
    if (restaurantType == null) {
      _toast("Please select a Status");
      return false;
    }

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
      (discountCtrl.text.isNotEmpty
          ? (double.parse(discountCtrl.text) / 100).toString()
          : ""),
      balanceCtrl.text,
      selectedPaymentMethod,
      commentCtrl.text,
      reasonCtrl.text,
    );

    return ok;
  }

  // =============================================================
  // UI COMPONENTS
  // =============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  InputDecoration _dropdownStyle(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  Widget _buildConversionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionTitle("Conversion Details"),

        _card(
          children: [
            _textField(emailCtrl, "Customer Email"),
            const SizedBox(height: 12),

            DropdownButtonFormField(
              decoration: _dropdownStyle("Product Select"),
              value: selectedProduct,
              items: products
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedProduct = v;
                  selectedPos.clear();
                });
              },
            ),
            const SizedBox(height: 12),

            if (selectedProduct == "Restaurant Pos") ...[
              const Text(
                "POS Options",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                children: posOptions.map((pos) {
                  return CheckboxListTile(
                    title: Text(pos),
                    value: selectedPos.contains(pos),
                    onChanged: (checked) {
                      setState(() {
                        checked!
                            ? selectedPos.add(pos)
                            : selectedPos.remove(pos);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            DropdownButtonFormField(
              decoration: _dropdownStyle("Payment Method"),
              value: selectedPaymentMethod,
              items: paymentOptions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPaymentMethod = v),
            ),
            const SizedBox(height: 12),

            _textField(costCtrl, "Cost", keyboard: TextInputType.number),
            const SizedBox(height: 12),

            _textField(
              discountCtrl,
              "Discount %",
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),

            _textField(
              balanceCtrl,
              "Balance to Pay",
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Comments",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClosedReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Closed - Reason"),

        _card(
          children: [
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Reason",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ],
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
