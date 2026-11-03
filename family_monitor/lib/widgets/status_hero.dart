import 'package:flutter/material.dart';

class StatusHero extends StatelessWidget {
  const StatusHero({
    required this.alarm,
    required this.online,
    required this.personName,
    required this.onAcknowledge,
    super.key,
  });

  final bool alarm;
  final bool online;
  final String personName;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final color = alarm ? const Color(0xFFB43B32) : const Color(0xFF0D6B67);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                alarm ? Icons.warning_amber_rounded : Icons.shield_outlined,
                color: Colors.white,
                size: 30,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: online ? const Color(0xFFB8F0C7) : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      online ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            alarm ? 'Fall alert active' : '$personName is safe',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            alarm
                ? 'Please check on $personName now.'
                : 'The wearable is connected and monitoring.',
            style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 15),
          ),
          if (onAcknowledge != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAcknowledge,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
              ),
              child: const Text('Acknowledge alert'),
            ),
          ],
        ],
      ),
    );
  }
}
