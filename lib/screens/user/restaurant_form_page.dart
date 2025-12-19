import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/restaurant_service.dart';
// import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String? selectedProduct;
  String? selectedPaymentMethod;
  List<String> selectedPos = [];

  final List<String> posOptions = ["Mobile Pos", "Web Pos", "Waiter App"];
  final List<String> paymentOptions = ["Card", "Cash", "Online-UPI"];

  final Map<String, int> posPrices = {
    "Mobile Pos": 3000,
    "Web Pos": 2000,
    "Waiter App": 5000,
  };

  final int retailFixedPrice = 5000;

  // Closed field
  final reasonCtrl = TextEditingController();

  // Others
  String? restaurantType;
  String? manualAddress;
  bool useManualAddress = false;
  bool isLoading = false;

  String selectedTopTab = "Restaurant";

  final List<String> restaurantTypes = [
    "Leads",
    "Follows",
    "Closed",
    "Installation",
    "Conversion",
  ];

  // Installation Date
  DateTime installationDate = DateTime.now();

  // Payment Mode
  String paymentType = "Full Settlement";

  // Deposit list
  List<Map<String, dynamic>> deposits = [];
  // Example:   { "amount": 400, "date": "2025-01-12" }

  final depositAmountCtrl = TextEditingController();

  // Auto Price Fields (from your POS selection)
  double cost = 0;
  double toPay = 0;

  void _recalculateCost() {
    if (selectedTopTab == "Retail") {
      // Retail always fixed price
      costCtrl.text = retailFixedPrice.toString();
      _recalculateToPay();
      return;
    }

    // Restaurant mode → calculate based on POS
    int total = 0;

    for (var pos in selectedPos) {
      total += posPrices[pos] ?? 0;
    }

    costCtrl.text = total.toString();

    _recalculateToPay();
  }

  bool _validateByStatus() {
    // ---------------- BASIC VALIDATION ----------------
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

    // ---------------- STATUS SPECIFIC ----------------
    switch (restaurantType) {
      case "Conversion":
        if (emailCtrl.text.trim().isEmpty) {
          _toast("Customer Email is required");
          return false;
        }

        if (selectedTopTab == "Restaurant" && selectedPos.isEmpty) {
          _toast("Please select at least one POS");
          return false;
        }

        final cost = double.tryParse(costCtrl.text);
        if (cost == null || cost <= 0) {
          _toast("Cost must be greater than zero");
          return false;
        }

        final toPay = double.tryParse(balanceCtrl.text);
        if (toPay == null || toPay <= 0) {
          _toast("To Pay amount is required");
          return false;
        }

        final totalPaid = deposits.fold<double>(
          0,
          (sum, p) => sum + (p["amount"] as double),
        );

        // 🔴 NEW: payment amount validation
        if (totalPaid <= 0) {
          _toast("Please enter payment amount");
          return false;
        }

        if (totalPaid > toPay) {
          _toast("Entered amount exceeds payable amount");
          return false;
        }

        if (totalPaid < toPay && selectedPaymentMethod == null) {
          _toast("Please select payment method");
          return false;
        }

        break;

      case "Closed":
        if (reasonCtrl.text.trim().isEmpty) {
          _toast("Please enter reason for closing");
          return false;
        }
        break;

      case "Installation":
        if (installationDate == null) {
          _toast("Please select installation date");
          return false;
        }
        break;
    }

    return true;
  }

  bool get _canPay {
    final amt = double.tryParse(depositAmountCtrl.text.trim()) ?? 0;
    return selectedPaymentMethod != null && amt > 0;
  }

  String safeAddress(String? address) {
    if (address == null) return "";
    if (address.trim().isEmpty) return "";
    if (address.toLowerCase() == "null") return "";
    return address.trim();
  }

  void _recalculateToPay() {
    final cost = double.tryParse(costCtrl.text) ?? 0;
    final discountAmount = double.tryParse(discountCtrl.text) ?? 0;

    final toPay = (cost - discountAmount).clamp(0, double.infinity);
    balanceCtrl.text = toPay.toStringAsFixed(0);

    setState(() {});
  }

  void _addDepositPayment() {
    if (selectedPaymentMethod == null) {
      _toast("Please select payment method");
      return;
    }

    final txt = depositAmountCtrl.text.trim();
    if (txt.isEmpty) return;

    final amt = double.tryParse(txt);
    if (amt == null || amt <= 0) {
      _toast("Enter a valid amount");
      return;
    }

    final toPayTotal = double.tryParse(balanceCtrl.text) ?? 0;
    final paidSoFar = deposits.fold<double>(
      0,
      (sum, p) => sum + (p["amount"] as double),
    );

    if (amt > (toPayTotal - paidSoFar)) {
      _toast("Entered amount exceeds balance due");
      return;
    }

    depositAmountCtrl.clear();

    deposits.add({"amount": amt, "date": _today()});

    setState(() {});
  }

  String _today() {
    return "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";
  }

  // void _updatePrices() {
  //   cost = 0;

  //   if (selectedPos.contains("Mobile Pos")) cost += 3000;
  //   if (selectedPos.contains("Web Pos")) cost += 2000;
  //   if (selectedPos.contains("Waiter App")) cost += 5000;

  //   // Apply discount
  //   final discountPercent = double.tryParse(discountCtrl.text) ?? 0;
  //   final discountValue = cost * (discountPercent / 100);

  //   toPay = cost - discountValue;
  //   balanceDue = toPay;

  //   setState(() {});
  // }

  Future<void> _pickInstallationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: installationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => installationDate = picked);
    }
  }

  Widget _buildInstallationDateUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Installation Details",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Installation Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickInstallationDate,
                child: Container(
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
                          "${installationDate.day}/${installationDate.month}/${installationDate.year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    double toPayTotal = double.tryParse(balanceCtrl.text) ?? 0;
    double totalPaid = deposits.fold(0.0, (sum, p) => sum + p["amount"]);
    bool isSettled = totalPaid >= toPayTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //-------------------------------------------------------------
        // INSTALLATION DATE
        //-------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Installation Date",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickInstallationDate,
                child: Container(
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
                          "${installationDate.day}/${installationDate.month}/${installationDate.year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        //-------------------------------------------------------------
        // PAYMENT DETAILS
        //-------------------------------------------------------------
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Payment Details",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 15),

              //-------------------------------------------------------------
              // PAYMENT METHOD DROPDOWN
              //-------------------------------------------------------------
              DropdownButtonFormField<String>(
                decoration: _dropdownDecoration("Select Payment Method"),
                value: selectedPaymentMethod,
                items: ["Cash", "Card", "Online-UPI"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => selectedPaymentMethod = v),
              ),

              const SizedBox(height: 20),

              //-------------------------------------------------------------
              // IF SETTLED → SHOW SETTLED UI
              //-------------------------------------------------------------
              if (isSettled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Settled",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        totalPaid.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              //-------------------------------------------------------------
              // IF NOT SETTLED → SHOW DEPOSITS UI
              //-------------------------------------------------------------
              if (!isSettled) _buildDepositContainer(),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildFullSettlementContainer() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //     margin: const EdgeInsets.only(top: 10),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: Colors.grey.shade300),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         const Text(
  //           "Settled",
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  //         ),
  //         Text(
  //           "${balanceCtrl.text}", // NO £ SYMBOL
  //           style: const TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.green,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> openInGoogleMaps({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildDepositContainer() {
    final toPayTotal = double.tryParse(balanceCtrl.text) ?? 0;
    final paidTotal = deposits.fold<double>(
      0,
      (sum, p) => sum + (p["amount"] as double),
    );
    final balance = (toPayTotal - paidTotal).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // ENTER AMOUNT + PAY BUTTON
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: depositAmountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
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
                onPressed: _canPay ? _addDepositPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
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

          // PAYMENT HISTORY
          ...deposits.map((p) => _paymentTile(p)),

          const SizedBox(height: 10),

          // BALANCE DUE (NOW CORRECT)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Balance Due",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                balance.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentTile(Map<String, dynamic> p) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment : ${deposits.indexOf(p) + 1}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(p["date"], style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(
            p["amount"].toStringAsFixed(0),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add Visit",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------
            // TOP TABS (Restaurant / Retail)
            // ---------------------------------------------------
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // ---------------------- RESTAURANT TAB ----------------------
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTopTab = "Restaurant";
                          selectedPos.clear(); // restaurant POS reset
                          costCtrl.text = ""; // clear cost
                          balanceCtrl.text = ""; // clear ToPay
                        });
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedTopTab == "Restaurant"
                              ? Colors.teal.shade700
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/restaurant.svg",
                                height: 20,
                                width: 20,
                                color: selectedTopTab == "Restaurant"
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Restaurant",
                                style: TextStyle(
                                  color: selectedTopTab == "Restaurant"
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ---------------------- RETAIL TAB ----------------------
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTopTab = "Retail";
                          selectedPos.clear();

                          // SET COST = 5000 for Retail
                          costCtrl.text = retailFixedPrice.toString();

                          // APPLY DISCOUNT IF EXISTS
                          _recalculateToPay();
                        });
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selectedTopTab == "Retail"
                              ? Colors.teal.shade700
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/icons/retail.svg",
                                height: 20,
                                width: 20,
                                color: selectedTopTab == "Retail"
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Retail",
                                style: TextStyle(
                                  color: selectedTopTab == "Retail"
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------------
            // BASIC INFORMATION SECTION
            // ---------------------------------------------------
            const Text(
              "Basic Information",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _styledTextField(nameCtrl, "Restaurant Name"),
                  const SizedBox(height: 14),
                  _styledTextField(contactCtrl, "Contact Person Name"),
                  const SizedBox(height: 14),
                  _styledTextField(
                    phoneCtrl,
                    "Phone Number",
                    keyboard: TextInputType.number,
                    maxLen: 10,
                  ),
                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: () {
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
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Add Address Manually",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (useManualAddress && manualAddress != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Address: $manualAddress",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ---------------------------------------------------
            // STATUS SECTION
            // ---------------------------------------------------
            const Text(
              "Status",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                decoration: _dropdownDecoration("Select Visit Status"),
                value: restaurantType,
                items: restaurantTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() => restaurantType = value);
                },
              ),
            ),

            const SizedBox(height: 20),

            if (restaurantType == "Conversion") _buildConversionFormUI(),

            if (restaurantType == "Closed") _buildClosedReasonUI(),

            if (restaurantType == "Installation") _buildInstallationDateUI(),

            const SizedBox(height: 30),

            // ---------------------------------------------------
            // SAVE BUTTON (BIG)
            // ---------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!_validateByStatus()) return; // ⛔ STOP HERE

                        setState(() => isLoading = true);

                        bool ok = await _saveRestaurant();

                        setState(() => isLoading = false);

                        if (ok) {
                          Navigator.pop(context, true);
                        }
                      },

                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.teal.shade700,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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

  // -------------------------------------------------------------
  // Styled TextField for matching design
  // -------------------------------------------------------------
  Widget _styledTextField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int? maxLen,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLength: maxLen,
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ----------------------------------------------------------------
  // Conversion and Closed Reason UI updated similarly for consistency
  // ----------------------------------------------------------------

  Widget _buildConversionFormUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Conversion Details",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        _sectionCard([
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Email is required";
              }

              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

              if (!emailRegex.hasMatch(value)) {
                return "Enter a valid email address";
              }

              return null;
            },
            decoration: InputDecoration(
              hintText: "Customer Email",
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ---------------------------------------------------------------------
          // POS SECTION (Only for Restaurant)
          // ---------------------------------------------------------------------
          if (selectedTopTab == "Restaurant")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select POS",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),

                DropdownButtonFormField<String>(
                  decoration: _dropdownDecoration("Select POS"),
                  items: posOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null && !selectedPos.contains(value)) {
                      setState(() {
                        selectedPos.add(value);
                      });
                      _recalculateCost();
                    }
                  },
                ),

                const SizedBox(height: 12),

                // TAGS (chips)
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

          // ---------------------------------------------------------------------
          // COST (AUTO CALCULATED)
          // ---------------------------------------------------------------------
          TextField(
            controller: costCtrl,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Cost",
              filled: true,
              fillColor: Colors.grey.shade300,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ---------------------------------------------------------------------
          // DISCOUNT %
          // ---------------------------------------------------------------------
          TextField(
            controller: discountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => _recalculateToPay(),
            decoration: InputDecoration(
              hintText: "Discount Amount",
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ---------------------------------------------------------------------
          // TO PAY (AUTO)
          // ---------------------------------------------------------------------
          TextField(
            controller: balanceCtrl,
            readOnly: true,
            decoration: InputDecoration(
              hintText: "To Pay",
              filled: true,
              fillColor: Colors.grey.shade300,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---------------------------------------------------------------------
          // INSTALLATION DATE + PAYMENT DETAIL SECTION (SEPARATE WIDGET)
          // ---------------------------------------------------------------------
          _buildPaymentSection(),
        ]),
      ],
    );
  }

  Widget _buildClosedReasonUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Closed - Reason",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        _sectionCard([
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Reason",
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
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

    // Convert discount % → decimal for backend
    String discountForBackend = discountCtrl.text.trim();

    Map<String, dynamic>? loc;
    String addressToSend;
    String? latitude;
    String? longitude;

    if (useManualAddress) {
      addressToSend = safeAddress(manualAddress);

      if (addressToSend.isEmpty) {
        _toast("Please enter address");
        return false;
      }

      latitude = null;
      longitude = null;
    } else {
      loc = await LocationService.getLocationDetails();

      addressToSend = safeAddress(loc["address"]);
      latitude = loc["latitude"]?.toString();
      longitude = loc["longitude"]?.toString();

      if (addressToSend.isEmpty && latitude != null && longitude != null) {
        addressToSend = "$latitude,$longitude"; // Maps-safe fallback
      }
    }

    // ---------------------------
    // PAYMENT CALCULATIONS
    // ---------------------------
    double toPay = double.tryParse(balanceCtrl.text) ?? 0;
    double totalPaid = deposits.fold(0.0, (sum, p) => sum + p["amount"]);
    double balance = (toPay - totalPaid).clamp(0, double.infinity);

    String paymentDetails = "";

    // NEW LOGIC → always store the payment method text

    if (totalPaid >= toPay) {
      paymentDetails = "Settled";
    } else {
      paymentDetails = selectedPaymentMethod ?? "";
    }

    bool ok = await RestaurantService.addRestaurant(
      widget.userId,
      nameCtrl.text,
      restaurantType ?? "",
      phoneCtrl.text,
      contactCtrl.text,
      addressToSend,
      latitude,
      longitude,

      email: emailCtrl.text,
      product: selectedTopTab,
      posMulti: selectedPos.join(","),

      cost: costCtrl.text,
      discount: discountForBackend,

      toPay: toPay.toString(),
      amountPaid: totalPaid.toString(),
      balance: balance.toString(),

      paymentDetails: paymentDetails,
      closedReason: reasonCtrl.text,
    );

    return ok;
  }

  // =============================================================
  // UI COMPONENTS
  // =============================================================

  // Widget _sectionTitle(String title) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Text(
  //       title,
  //       style: const TextStyle(
  //         fontSize: 18,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.black87,
  //       ),
  //     ),
  //   );
  // }

  // Widget _card({required List<Widget> children}) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),

  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 6,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: children,
  //     ),
  //   );
  // }

  // Widget _textField(
  //   TextEditingController ctrl,
  //   String label, {
  //   TextInputType keyboard = TextInputType.text,
  //   int? maxLen,
  // }) {
  //   return TextField(
  //     controller: ctrl,
  //     keyboardType: keyboard,
  //     maxLength: maxLen,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //       filled: true,
  //       fillColor: Colors.grey.shade100,
  //     ),
  //   );
  // }

  // InputDecoration _dropdownStyle(String label) {
  //   return InputDecoration(
  //     labelText: label,
  //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  //     filled: true,
  //     fillColor: Colors.grey.shade100,
  //   );
  // }

  // Widget _buildClosedReason() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _sectionTitle("Closed - Reason"),

  //       _card(
  //         children: [
  //           TextField(
  //             controller: reasonCtrl,
  //             maxLines: 3,
  //             decoration: InputDecoration(
  //               labelText: "Reason",
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               filled: true,
  //               fillColor: Colors.grey.shade100,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

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
  final TextEditingController addressCtrl = TextEditingController();

  void _save() {
    if (addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter address")));
      return;
    }

    widget.onSave(addressCtrl.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- TITLE ----------------
            const Text(
              "Add Address Manually",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            const Text(
              "Add full address from Google or type manually",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            // ---------------- TEXT AREA ----------------
            TextField(
              controller: addressCtrl,
              maxLines: 6,
              minLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ---------------- ACTION BUTTONS ----------------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Save Address",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
