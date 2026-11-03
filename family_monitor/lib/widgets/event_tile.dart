import 'package:flutter/material.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.time,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String time;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(detail),
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 12, color: Color(0xFF66747B)),
      ),
    );
  }
}
