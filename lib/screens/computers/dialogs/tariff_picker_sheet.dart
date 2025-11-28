import 'package:flutter/material.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/screens/profile/models/tariff.dart';
import 'package:qube/services/api_service.dart';

final api = ApiService.instance;

Future<Tariff?> showTariffPickerSheet(
  BuildContext context,
  Computer comp,
) async {
  try {
    return await showModalBottomSheet<Tariff>(
      context: context,
      backgroundColor: const Color(0xFF1E1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) {
        Tariff? selected;
        final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.66;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Выбор тарифа",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comp.zone.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Tariff>>(
                  future: api.fetchTariffsForComputer(comp.id),
                  builder: (ctx, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Не удалось загрузить тарифы: ${snap.error}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final tariffs = snap.data ?? const <Tariff>[];
                    if (tariffs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Для этой зоны тарифов нет.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return StatefulBuilder(
                      builder: (ctx2, setStateSB) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxHeight,
                            minHeight: 0,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: tariffs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final t = tariffs[i];
                              final fixed = t.minutes > 0;
                              final selectedNow = selected?.id == t.id;

                              return InkWell(
                                onTap: () => setStateSB(() => selected = t),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF23243A),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedNow
                                          ? const Color(0xFF6C5CE7)
                                          : Colors.white.withOpacity(.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<Tariff>(
                                        value: t,
                                        groupValue: selected,
                                        onChanged: (val) =>
                                            setStateSB(() => selected = val),
                                        fillColor: MaterialStateProperty.all(
                                          const Color(0xFF6C5CE7),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    t.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "${t.price} ₸",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              t.description.isNotEmpty
                                                  ? t.description
                                                  : (fixed
                                                        ? "${t.minutes} мин"
                                                        : "Свободная длительность"),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (t.discountApplied > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF00B894,
                                                        ).withOpacity(.18),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "-${t.discountApplied}%",
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF00B894,
                                                          ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetCtx, null),
                        child: const Text("Отмена"),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx, selected);
                        },
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.white.withOpacity(
                            .12,
                          ),
                          disabledForegroundColor: Colors.white70,
                        ),
                        child: Text(
                          selected == null
                              ? "Выбрать"
                              : "Выбрать • ${selected!.price} ₸",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  } catch (e) {
    return null;
  }
}
