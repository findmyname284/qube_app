import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qube/models/booking_models.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/screens/computers/dialogs/duration_picker_sheet.dart';
import 'package:qube/screens/computers/dialogs/tariff_picker_sheet.dart';
import 'package:qube/screens/computers/dialogs/time_picker_sheet.dart';
import 'package:qube/services/api_service.dart';
import 'package:qube/utils/app_snack.dart';
import 'package:qube/utils/date_utils.dart';
import 'package:qube/widgets/time_picker_clock.dart';

import 'computer_helpers.dart';

final api = ApiService.instance;

Future<void> bookComputer({
  required BuildContext context,
  required Computer comp,
  required int maxHours,
  required Duration rollingWindow,
  required VoidCallback onRefresh,
  required Function(Computer, ServerError) onConflict,
}) async {
  final tariff = await showTariffPickerSheet(context, comp);
  if (tariff == null) return;

  final bool isFixedWindow =
      (tariff.startAt != null && tariff.startAt!.isNotEmpty) &&
      (tariff.endAt != null && tariff.endAt!.isNotEmpty);

  DateTime startLocal;
  Duration dur;

  if (isFixedWindow) {
    final win = computeNextFixedWindow(tariff.startAt, tariff.endAt);
    if (win == null) {
      AppSnack.show(
        context,
        message: "Неверные startAt/endAt у тарифа.",
        type: AppSnackType.error,
      );
      return;
    }

    final now = DateTime.now();
    startLocal = now.isBefore(win.startBoundary) ? win.startBoundary : now;

    final byFixed = win.endBoundary;
    final by12h = startLocal.add(Duration(hours: maxHours));
    final by24h = DateTime.now().add(rollingWindow);

    DateTime effectiveEnd = byFixed;
    if (by12h.isBefore(effectiveEnd)) effectiveEnd = by12h;
    if (by24h.isBefore(effectiveEnd)) effectiveEnd = by24h;

    if (!startLocal.isBefore(by24h)) {
      AppSnack.show(
        context,
        message: "Ближайшее окно фикс-тарифа выходит за 24 часа.",
        type: AppSnackType.error,
      );
      return;
    }

    dur = effectiveEnd.difference(startLocal);
    if (dur <= Duration.zero) {
      AppSnack.show(
        context,
        message: "Старт вне доступного окна. Выберите другой тариф/время.",
        type: AppSnackType.error,
      );
      return;
    }

    AppSnack.show(
      context,
      message:
          "Бронируем ПК #${comp.id} • «${tariff.name}» (${hmPretty(tariff.startAt)}–${hmPretty(tariff.endAt)})...",
      type: AppSnackType.info,
    );

    try {
      await api.booking(
        comp.id,
        'maintenance',
        startLocal,
        dur,
        tariffId: tariff.id,
      );
      AppSnack.show(
        context,
        message: "ПК #${comp.id} забронирован!",
        type: AppSnackType.success,
      );
      onRefresh();
    } catch (e) {
      final parsed = ServerError.parse(e);
      if (parsed.code == 'time_conflict') {
        onConflict(comp, parsed);
      } else if (parsed.code == 'out_of_window') {
        AppSnack.show(
          context,
          message:
              "Вне ближайших 24 часов. Доступное окно: ${parsed.windowReadable}",
          type: AppSnackType.error,
        );
      } else {
        AppSnack.show(
          context,
          message: parsed.message.isNotEmpty ? parsed.message : "Ошибка: $e",
          type: AppSnackType.error,
        );
      }
    }
    return;
  }

  final startUtc = await showTimePickerSheet(context, comp);
  if (startUtc == null) return;

  if (tariff.minutes > 0) {
    dur = Duration(minutes: tariff.minutes);
    startLocal = startUtc.toLocal();
  } else {
    final picked = await showDurationPickerSheet(
      context,
      startUtc,
      isNightTariff: false,
      maxHours: maxHours,
      rollingWindow: rollingWindow,
    );
    if (picked == null) return;
    dur = picked;
    startLocal = startUtc.toLocal();
  }

  if (dur > Duration(hours: maxHours)) {
    AppSnack.show(
      context,
      message: "Максимальная длительность — $maxHours часов",
      type: AppSnackType.error,
    );
    return;
  }

  final latestEndAllowed = DateTime.now().add(rollingWindow);
  if (startLocal.add(dur).isAfter(latestEndAllowed)) {
    AppSnack.show(
      context,
      message:
          "Бронь должна быть в пределах ближайших 24 часов (до ${formatDateTime(latestEndAllowed)}).",
      type: AppSnackType.error,
    );
    return;
  }

  AppSnack.show(
    context,
    message: "Бронируем ПК #${comp.id} • «${tariff.name}»...",
    type: AppSnackType.info,
  );

  try {
    await api.booking(
      comp.id,
      'maintenance',
      startLocal,
      dur,
      tariffId: tariff.id,
    );
    AppSnack.show(
      context,
      message: "ПК #${comp.id} забронирован!",
      type: AppSnackType.success,
    );
    onRefresh();
  } catch (e) {
    final parsed = ServerError.parse(e);
    if (parsed.code == 'time_conflict') {
      onConflict(comp, parsed);
    } else if (parsed.code == 'out_of_window') {
      AppSnack.show(
        context,
        message:
            "Нельзя бронировать вне ближайших 24 часов. Доступное окно: ${parsed.windowReadable}",
        type: AppSnackType.error,
      );
    } else {
      AppSnack.show(
        context,
        message: parsed.message.isNotEmpty ? parsed.message : "Ошибка: $e",
        type: AppSnackType.error,
      );
    }
  }
}

Future<List<TimeSlot>> fetchBookedIntervals(Computer comp) async {
  try {
    final bookingData = await api.fetchBookedIntervals(comp.id);
    final List<dynamic> booked = (bookingData['booked'] as List?) ?? const [];

    return booked
        .map((e) {
          final startStr = e['start'] as String?;
          final endStr = e['end'] as String?;
          try {
            final start = DateTime.parse(startStr ?? '');
            final end = DateTime.parse(endStr ?? '');
            return TimeSlot(start, end);
          } catch (_) {
            return null;
          }
        })
        .whereType<TimeSlot>()
        .toList();
  } catch (e) {
    return [];
  }
}
