import 'package:flutter/material.dart';
import 'package:qube/utils/app_snack.dart';

class TopUpSheet extends StatefulWidget {
  const TopUpSheet({super.key, required this.onSubmit});
  final Future<bool> Function(int amount) onSubmit;

  @override
  State<TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<TopUpSheet> {
  final controller = TextEditingController();
  final presets = const [1000, 2000, 5000, 10000];
  int? selected;
  bool submitting = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = controller.text.trim().isEmpty
        ? selected?.toString() ?? ''
        : controller.text.trim();
    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) {
      AppSnack.show(
        context,
        message: 'Укажите сумму пополнения',
        type: AppSnackType.error,
      );
      return;
    }
    if (amount > 10000) {
      AppSnack.show(
        context,
        message: 'Максимальная сумма пополнения 10000тг',
        type: AppSnackType.error,
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final ok = await widget.onSubmit(amount);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, amount);
      } else {
        AppSnack.show(
          context,
          message: 'Не удалось обновить профиль',
          type: AppSnackType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: 'Ошибка пополнения: $e',
        type: AppSnackType.error,
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Пополнение',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((v) {
              final sel = selected == v;
              return ChoiceChip(
                label: Text('$v ₸'),
                selected: sel,
                onSelected: (_) => setState(() {
                  selected = v;
                  controller.text = selected.toString();
                }),
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: const Color(0xFF6C5CE7),
                backgroundColor: Colors.white.withOpacity(.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: sel
                        ? const Color(0xFF6C5CE7)
                        : Colors.white.withOpacity(.08),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Другая сумма',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(
                Icons.payments_rounded,
                color: Colors.white70,
              ),
              hintText: 'Например, 3500',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(.06),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_card_rounded),
                  label: const Text('Пополнить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
