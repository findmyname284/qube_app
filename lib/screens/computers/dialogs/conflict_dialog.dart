import 'package:flutter/material.dart';
import 'package:qube/models/booking_models.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/utils/date_utils.dart';

void showConflictDialog({
  required BuildContext context,
  required Computer comp,
  required ServerError error,
  required Future<void> Function(Computer, Suggestion) onBookSuggested,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Конфликт по времени",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.message.isNotEmpty
                    ? error.message
                    : "Запрошенный интервал пересекается с существующей бронью.",
                style: const TextStyle(color: Colors.white70),
              ),
              if (error.windowReadable.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "Доступное окно: ${error.windowReadable}",
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
              const SizedBox(height: 12),
              if (error.suggestions.isNotEmpty)
                const Text(
                  "Предлагаем варианты:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (error.suggestions.isNotEmpty) const SizedBox(height: 8),
              if (error.suggestions.isNotEmpty)
                ...error.suggestions
                    .take(3)
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await onBookSuggested(comp, s);
                          },
                          child: Text(
                            "${formatDateTime(s.start)} • ${readableDuration(s.end.difference(s.start))}",
                          ),
                        ),
                      ),
                    ),
              if (error.suggestions.isEmpty)
                const Text(
                  "Свободные варианты отсутствуют. Попробуйте выбрать другое время.",
                  style: TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Закрыть"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
