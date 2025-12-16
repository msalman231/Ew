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
  String? paymentDateFromDB;

  String _formatDate(dynamic date) {
    if (date == null) return "N/A";

    try {
      final d = DateTime.parse(date.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (_) {
      return date.toString(); // fallback if bad format
    }
  }

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

  String _mapResTypeToUI(String? resType) {
    if (resType == null) return "";

    switch (resType.toLowerCase()) {
      case "leads":
        return "Leads";
      case "follows":
        return "Follows";
      case "future_follows":
        return "Future Follows";
      case "closed":
        return "Closed";
      case "installation":
        return "Installation";
      case "conversion":
        return "Conversion";
      default:
        return "";
    }
  }

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
    restaurantType = _mapResTypeToUI(r["res_type"]);

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
    final pm = r["payment_detials"]?.toString();

    if (pm == "Card" || pm == "Cash" || pm == "Online-UPI") {
      selectedPaymentMethod = pm;
    } else {
      // Covers: "Settled", null, empty, garbage
      selectedPaymentMethod = null;
    }

    // Created Date
    if (r["created_at"] != null) {
      createdAt = DateTime.tryParse(r["created_at"].toString());
    }

    // -----------------------------
    // LOAD AMOUNT PAID + BALANCE
    // -----------------------------
    final amountPaidFromDB = double.tryParse(_coerce(r["amount_paid"])) ?? 0;
    final toPayFromDB = double.tryParse(_coerce(r["to_pay"])) ?? 0;

    // -----------------------------
    // LOAD PAYMENT HISTORY
    // -----------------------------
    deposits.clear();
    // IMPORTANT: backend uses payment_detials

    // If DB has amount_paid but no JSON deposit list, create single deposit
    if (amountPaidFromDB > 0) {
      deposits.add({
        "amount": amountPaidFromDB,
        "date": _formatDate(r["created_at"]),
      });
    }

    // Recalculate if needed
    if (costCtrl.text.isEmpty) _recalculateCost();
    if (toPayCtrl.text.isEmpty) _recalculateToPay();

    // -----------------------------
    // LOAD CLOSED REASON (IMPORTANT)
    // -----------------------------
    commentCtrl.text = r["closed_reason"]?.toString() ?? "";
  }

  String _displayDiscount(dynamic d) {
    if (d == null) return "";
    final parsed = double.tryParse(d.toString());
    if (parsed == null) return "";

    // DB: 0.05 → UI: 5
    return (parsed * 100).toStringAsFixed(0);
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
    return DateTime.now().toIso8601String().split("T").first;
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

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
      ),
    );
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
        "conversion",

        name: nameCtrl.text,
        email: emailCtrl.text,
        product: selectedTopTab,
        posMulti: selectedPos.join(","),

        cost: costCtrl.text,
        discount: backendDiscount,
        toPay: toPayValue.toStringAsFixed(0),
        amountPaid: amountPaid.toStringAsFixed(0),
        balance: balanceValue.toStringAsFixed(0),

        paymentDetails: paymentDetialsPayload,

        contact: contactCtrl.text,
        phone: phoneCtrl.text,
        location: fullAddress,
        latitude: loc["latitude"].toString(),
        longitude: loc["longitude"].toString(),
      );
    }
    // --------------------------------------------------------
    // CASE 2: Closed (backend accepts ONLY closed_reason + res_type)
    // --------------------------------------------------------
    else if (restaurantType?.toLowerCase() == "closed") {
      ok = await RestaurantService.updateRestaurant(
        r["id"],
        "closed",
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
                  backgroundColor: const Color(0xFF0F766E), // modern teal
                  foregroundColor: Colors.white, // text & icon color
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Pay",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Payment History
          ...deposits.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE (Payment + Date)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payment : ${index + 1}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(p["date"]),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  // RIGHT SIDE (AMOUNT)
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
          }).toList(),

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
                value: restaurantTypes.contains(restaurantType)
                    ? restaurantType
                    : null,
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
            //-------------------------------------------------------------
            // CREATED AT (READ-ONLY)
            //-------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Created At",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            createdAt == null
                                ? "Not available"
                                : "${createdAt!.day}/${createdAt!.month}/${createdAt!.year}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(
                          Icons.event,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
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
                    // ---------------------------------------------------------------------
                    // POS SECTION (Only for Restaurant)
                    // ---------------------------------------------------------------------
                    if (selectedTopTab == "Restaurant") ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select POS",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),

                          // POS DROPDOWN
                          DropdownButtonFormField<String>(
                            decoration: _dropdownDecoration("Select POS"),
                            items: posOptions
                                .map(
                                  (p) => DropdownMenuItem<String>(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null &&
                                  !selectedPos.contains(value)) {
                                setState(() {
                                  selectedPos.add(value);
                                });
                                _recalculateCost();
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          // SELECTED POS TAGS
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedPos.map((pos) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF061341),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pos,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedPos.remove(pos);
                                        });
                                        _recalculateCost();
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Payment Method",
                        border: OutlineInputBorder(),
                      ),
                      value: paymentOptions.contains(selectedPaymentMethod)
                          ? selectedPaymentMethod
                          : null,
                      items: paymentOptions
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

            // --------------------------------------------------
            // CLOSED REASON SECTION (EDIT MODE)
            // --------------------------------------------------
            if (restaurantType?.toLowerCase() == "closed") ...[
              const SizedBox(height: 18),
              const Text(
                "Closed - Reason",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter reason for closing",
                    border: OutlineInputBorder(),
                  ),
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
                          color: Colors.white,
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
