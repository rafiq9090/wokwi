import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({required this.icon, required this.label, required this.value, super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1DED5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0D6B67), size: 22),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: Color(0xFF66747B), fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
