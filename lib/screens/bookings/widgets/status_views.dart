import 'package:flutter/material.dart';

class StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  const StatusView._({
    required this.icon,
    required this.title,
    this.description,
    this.onRetry,
  });

  const StatusView.empty({required String title, String? description})
    : this._(icon: Icons.event_busy, title: title, description: description);

  const StatusView.error({
    required String title,
    String? description,
    VoidCallback? onRetry,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         description: description,
         onRetry: onRetry,
       );

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F2E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 56, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
