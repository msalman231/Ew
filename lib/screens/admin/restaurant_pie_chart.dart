import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RestaurantPieChart extends StatelessWidget {
  final List<dynamic> restaurants;

  const RestaurantPieChart({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    // Count restaurants by status (res_type)
    final Map<String, int> counts = {};

    for (final r in restaurants) {
      final type = (r["res_type"] ?? "unknown").toString().toLowerCase();
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final Map<String, Color> colors = {
      "leads": Colors.blue,
      "follows": Colors.orange,
      "conversion": Colors.green,
      "installation": Colors.purple,
      "closed": Colors.red,
      "unknown": Colors.grey,
    };

    return AspectRatio(
      aspectRatio: 1.2,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 45,
          sections: counts.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value.toDouble(),
              title: "${entry.key}\n${entry.value}",
              radius: 70,
              color: colors[entry.key] ?? Colors.grey,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
