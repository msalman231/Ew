// lib/pages/restaurant_edit_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/restaurant_service.dart';

class RestaurantEditPage extends StatefulWidget {
  final dynamic restaurant; // Map or List
  const RestaurantEditPage({super.key, required this.restaurant});

  @override
  State<RestaurantEditPage> createState() => _RestaurantEditPageState();
}

class _RestaurantEditPageState extends State<RestaurantEditPage> {
  late Map<String, dynamic> r;

  // Basic controllers
  late TextEditingController nameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController contactCtrl;

  // Address controllers
  late TextEditingController addressCtrl;
  late TextEditingController areaCtrl;
  late TextEditingController cityCtrl;

  // Conversion/payment controllers
  final emailCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  final discountCtrl = TextEditingController(); // percent shown like "10"
  final toPayCtrl = TextEditingController(); // readonly shows final amount
  final commentCtrl = TextEditingController();

  // Deposits (session)
  final depositAmountCtrl = TextEditingController();
  List<Map<String, dynamic>> deposits = [];

  // state
  String? restaurantType;
  String selectedTopTab = "Restaurant";
  List<String> selectedPos = [];
  String? selectedPaymentMethod;
  DateTime? createdAt;
  bool isLoading = false;

  final Map<String, int> posPrices = {
    "Mobile Pos": 3000,
    "Web Pos": 2000,
    "Waiter App": 5000,
  };
  final int retailFixedPrice = 5000;

  final List<String> restaurantTypes = [
    "Leads",
    "Follows",
    "Future Follows",
    "Closed",
    "Installation",
    "Conversion",
  ];

  final List<String> posOptions = ["Mobile Pos", "Web Pos", "Waiter App"];
  final List<String> paymentOptions = ["Card", "Cash", "Online-UPI"];

  @override
  void initState() {
    super.initState();
    r = _normalize(widget.restaurant);

    // Basic fields
    nameCtrl = TextEditingController(text: r["name"] ?? "");
    phoneCtrl = TextEditingController(text: r["phone"] ?? "");
    contactCtrl = TextEditingController(text: r["contact"] ?? "");

    // Address
    final locParts = (r["location"] ?? "").toString().split(", ");
    addressCtrl = TextEditingController(
      text: locParts.isNotEmpty ? locParts[0] : "",
    );
    areaCtrl = TextEditingController(
      text: locParts.length > 1 ? locParts[1] : "",
    );
    cityCtrl = TextEditingController(
      text: locParts.length > 2 ? locParts[2] : "",
    );

    // Status
    restaurantType = r["res_type"];

    if (restaurantType != null) {
      restaurantType =
          restaurantType![0].toUpperCase() +
          restaurantType!.substring(1).toLowerCase();
    }

    // Visit type / Retail / Restaurant
    selectedTopTab = (r["product"]?.toString() ?? "Restaurant");
    if (selectedTopTab != "Retail" && selectedTopTab != "Restaurant") {
      selectedTopTab = "Restaurant";
    }

    // Email
    emailCtrl.text = r["email"] ?? "";

    // Cost
    costCtrl.text = _coerce(r["cost"]);

    // -----------------------------
    // DISCOUNT UI FIX
    // DB stores: 10.00 → show: 10
    // -----------------------------
    discountCtrl.text = _displayDiscount(r["discount"]);

    // To Pay
    toPayCtrl.text = _coerce(r["to_pay"]);

    // POS Multi
    selectedPos = [];
    if (r["pos_multi"] != null) {
      final raw = r["pos_multi"];
      if (raw is String && raw.trim().isNotEmpty) {
        selectedPos = raw.split(",").map((e) => e.trim()).toList();
      } else if (raw is List) {
        selectedPos = raw.map((e) => e.toString()).toList();
      }
    }

    // Payment Method (saved as simple text in DB)
    selectedPaymentMethod = r["payment_detials"];

    // Created Date
    if (r["created_at"] != null) {
      createdAt = DateTime.tryParse(r["created_at"].toString());
    }

    // -----------------------------
    // LOAD AMOUNT PAID + BALANCE
    // -----------------------------
    final amountPaidFromDB = double.tryParse(_coerce(r["amount_paid"])) ?? 0;
    final balanceFromDB = double.tryParse(_coerce(r["balance"])) ?? 0;

    // -----------------------------
    // LOAD PAYMENT HISTORY
    // -----------------------------
    deposits.clear();
    _loadPaymentDetails(
      r["payment_detials"],
    ); // IMPORTANT: backend uses payment_detials

    // If DB has amount_paid but no JSON deposit list, create single deposit
    if (deposits.isEmpty && amountPaidFromDB > 0) {
      deposits.add({"amount": amountPaidFromDB, "date": _today()});
    }

    // Recalculate if needed
    if (costCtrl.text.isEmpty) _recalculateCost();
    if (toPayCtrl.text.isEmpty) _recalculateToPay();
  }

  String _displayDiscount(dynamic d) {
    if (d == null) return "";
    final parsed = double.tryParse(d.toString());
    if (parsed == null) return "";
    return parsed.toStringAsFixed(0); // DB: 10.00 → UI: "10"
  }

  Map<String, dynamic> _normalize(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw.first);
    }
    return {};
  }

  String _coerce(dynamic v) {
    if (v == null) return "";
    return v.toString();
  }

  void _loadPaymentDetails(dynamic pd) {
    deposits.clear();

    double paid = double.tryParse(_coerce(r["amount_paid"])) ?? 0;

    if (pd == null || pd.toString().isEmpty) {
      if (paid > 0) {
        deposits.add({"amount": paid, "date": _today()});
      }
      return;
    }

    final s = pd.toString().trim();

    if (s.toLowerCase() == "settled") {
      if (paid > 0) {
        deposits.add({"amount": paid, "date": _today()});
      }
      return;
    }

    // Means: Card, Online-UPI, Cash
    if (!s.startsWith("[") && !s.contains("{")) {
      if (paid > 0) {
        deposits.add({"amount": paid, "date": _today()});
      }
      return;
    }

    // JSON case
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        for (var item in decoded) {
          deposits.add({
            "amount": double.tryParse(item["amount"].toString()) ?? 0,
            "date": item["date"] ?? _today(),
          });
        }
      }
    } catch (_) {
      if (paid > 0) {
        deposits.add({"amount": paid, "date": _today()});
      }
    }
  }

  // price logic
  void _recalculateCost() {
    if (selectedTopTab == "Retail") {
      costCtrl.text = retailFixedPrice.toString();
    } else {
      int total = 0;
      for (var p in selectedPos) total += posPrices[p] ?? 0;
      costCtrl.text = total.toString();
    }
    _recalculateToPay();
  }

  void _recalculateToPay() {
    final c = double.tryParse(costCtrl.text) ?? 0;
    final discPercent = double.tryParse(discountCtrl.text) ?? 0;
    final toPay = c - (c * (discPercent / 100));
    toPayCtrl.text = toPay.toStringAsFixed(0);
    setState(() {}); // update balance display
  }

  // deposits
  String _today() {
    final d = DateTime.now();
    return "${d.day}-${d.month}-${d.year}";
  }

  void _addDeposit() {
    final txt = depositAmountCtrl.text.trim();
    if (txt.isEmpty) return;
    final amt = double.tryParse(txt) ?? 0;
    if (amt <= 0) return;

    final currentToPay = double.tryParse(toPayCtrl.text) ?? 0;
    final paidSoFar = deposits.fold<double>(
      0,
      (s, it) => s + (it["amount"] as double),
    );
    final newPaid = paidSoFar + amt;

    depositAmountCtrl.clear();

    if (newPaid >= currentToPay) {
      deposits.clear();
      deposits.add({"amount": currentToPay, "date": _today()});
    } else {
      deposits.add({"amount": amt, "date": _today()});
    }

    setState(() {});
  }

  double get _sumDeposits =>
      deposits.fold<double>(0, (s, it) => s + (it["amount"] as double));
  bool get _isSettled =>
      (_sumDeposits >= (double.tryParse(toPayCtrl.text) ?? 0)) &&
      (double.tryParse(toPayCtrl.text) ?? 0) > 0;

  // ------------------ update send to backend ------------------
  Future<void> _updateRestaurant() async {
    setState(() => isLoading = true);

    final fullAddress =
        "${addressCtrl.text}, ${areaCtrl.text}, ${cityCtrl.text}";

    final loc = await LocationService.getLocationDetails();

    // Payment calculations
    final double toPayValue = double.tryParse(toPayCtrl.text) ?? 0;
    final double amountPaid = _sumDeposits;
    final double balanceValue = (toPayValue - amountPaid).clamp(
      0.0,
      double.infinity,
    );

    // Your backend DOES NOT store JSON deposit history.
    // payment_detials is only a plain string (Card / Cash / Online-UPI / Settled)
    String paymentDetialsPayload = selectedPaymentMethod ?? "";

    // Convert UI discount (10) → backend decimal (0.10)
    String backendDiscount = "";
    if (discountCtrl.text.trim().isNotEmpty) {
      final p = double.tryParse(discountCtrl.text) ?? 0;
      backendDiscount = (p / 100).toString();
    }

    bool ok = false;

    // --------------------------------------------------------
    // CASE 1: Conversion (send all conversion fields)
    // --------------------------------------------------------
    if (restaurantType?.toLowerCase() == "conversion") {
      ok = await RestaurantService.updateRestaurant(
        r["id"],
        nameCtrl.text,
        "conversion", // backend requires lowercase
        phoneCtrl.text,
        contactCtrl.text,
        fullAddress,
        loc["latitude"].toString(),
        loc["longitude"].toString(),

        email: emailCtrl.text,
        visitType: selectedTopTab, // product
        posMulti: selectedPos.join(","), // pos_multi
        cost: costCtrl.text,
        discount: backendDiscount,
        balance: balanceValue.toStringAsFixed(0),
        toPay: toPayValue.toStringAsFixed(0),
        amount: amountPaid.toStringAsFixed(0),
        paymentDetails: paymentDetialsPayload,
        closedReason: null,
      );
    }
    // --------------------------------------------------------
    // CASE 2: Closed (backend accepts ONLY closed_reason + res_type)
    // --------------------------------------------------------
    else if (restaurantType?.toLowerCase() == "closed") {
      ok = await RestaurantService.updateRestaurant(
        r["id"],
        nameCtrl.text,
        "closed",
        phoneCtrl.text,
        contactCtrl.text,
        fullAddress,
        loc["latitude"].toString(),
        loc["longitude"].toString(),

        closedReason: commentCtrl.text,
      );
    }

    setState(() => isLoading = false);

    if (ok) {
      if (mounted) Navigator.pop(context, true);
    } else {
      _toast("Update failed. Check backend logs.");
    }
  }

  Widget _depositEditor(double toPay, double paid) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: depositAmountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter amount",
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  _addDeposit();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const Text("Pay"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Payment History
          ...deposits.map((p) {
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Payment ${deposits.indexOf(p) + 1} - ${p["date"]}"),
                  Text(
                    "${p["amount"]}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          // Balance Due
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Balance Due",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                (toPay - paid).toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- UI helpers ----------------
  Widget _tabItem(String label) {
    final active = selectedTopTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTopTab = label;
            selectedPos.clear();
            _recalculateCost();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.teal.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    bool readOnly = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final tp = double.tryParse(toPayCtrl.text) ?? 0;
    final paid = _sumDeposits;
    final settled = _isSettled;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text("Edit Visit"),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top tabs
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _tabItem("Restaurant"),
                  const SizedBox(width: 8),
                  _tabItem("Retail"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Basic Information",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _textField(nameCtrl, "Restaurant Name"),
                  const SizedBox(height: 10),
                  _textField(contactCtrl, "Contact Person"),
                  const SizedBox(height: 10),
                  _textField(
                    phoneCtrl,
                    "Phone Number",
                    keyboard: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Status",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Select Status",
                  border: OutlineInputBorder(),
                ),
                value: restaurantType,
                items: restaurantTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => restaurantType = v),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Address",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _textField(addressCtrl, "Address"),
                  const SizedBox(height: 10),
                  _textField(areaCtrl, "Area"),
                  const SizedBox(height: 10),
                  _textField(cityCtrl, "City"),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Created At",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                createdAt == null
                    ? "Not available"
                    : "${createdAt!.day}-${createdAt!.month}-${createdAt!.year}",
              ),
            ),

            if (restaurantType?.toLowerCase() == "conversion") ...[
              const SizedBox(height: 18),
              const Text(
                "Conversion Details",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _textField(emailCtrl, "Customer Email"),
                    const SizedBox(height: 12),
                    if (selectedTopTab == "Restaurant") ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "POS Options",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...posOptions
                          .map(
                            (p) => CheckboxListTile(
                              title: Text(p),
                              value: selectedPos.contains(p),
                              onChanged: (ch) {
                                setState(() {
                                  if (ch == true)
                                    selectedPos.add(p);
                                  else
                                    selectedPos.remove(p);
                                  _recalculateCost();
                                });
                              },
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Payment Method",
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPaymentMethod,
                      items: ["Card", "Cash", "Online-UPI"]
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedPaymentMethod = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: costCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Cost",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discountCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculateToPay(),
                      decoration: const InputDecoration(
                        labelText: "Discount %",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: toPayCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "To Pay",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 8),
                    _paymentSectionUI(
                      settled: settled,
                      toPay: tp,
                      paid: paid,
                      paymentMethod: selectedPaymentMethod,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _updateRestaurant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _paymentSectionUI({
    required bool settled,
    required double toPay,
    required double paid,
    required String? paymentMethod, // remove usage
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Details",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        // Settled
        if (settled)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Settled", style: TextStyle(fontSize: 16)),
                Text(
                  paid.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          _depositEditor(toPay, paid),
      ],
    );
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
    toPayCtrl.dispose();
    commentCtrl.dispose();
    depositAmountCtrl.dispose();
    super.dispose();
  }
}
