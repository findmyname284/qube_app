import 'package:flutter/material.dart';

class LoadingHeader extends StatelessWidget {
  const LoadingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161821).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1F2E).withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F2E).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 180,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1F2E).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F2E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
