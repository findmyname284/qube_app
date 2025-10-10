import 'dart:convert';

import 'package:qube/utils/date_utils.dart';

class ServerError {
  final String code;
  final String message;
  final List<Suggestion> suggestions;
  final String windowReadable;

  const ServerError({
    this.code = '',
    this.message = '',
    this.suggestions = const [],
    this.windowReadable = '',
  });

  static ServerError parse(Object e) {
    Map<String, dynamic>? map;
    if (e is Map<String, dynamic>) {
      map = e;
    } else if (e is String) {
      try {
        final decoded = json.decode(e);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {}
    } else if (e.runtimeType.toString().contains('Api')) {
      try {
        final body =
            (e as dynamic).response?.data ??
            (e as dynamic).data ??
            (e as dynamic).body;
        if (body is Map<String, dynamic>) {
          map = body;
        } else if (body is String) {
          final decoded = json.decode(body);
          if (decoded is Map<String, dynamic>) map = decoded;
        }
      } catch (_) {}
    }

    if (map == null) {
      return const ServerError();
    }

    String code = (map['error'] ?? map['code'] ?? '').toString();
    String message = (map['message'] ?? '').toString();

    List<Suggestion> suggestions = [];
    if (map['suggestions'] is List) {
      for (final s in (map['suggestions'] as List)) {
        try {
          final start = DateTime.parse(s['start'] as String);
          final end = DateTime.parse(s['end'] as String);
          suggestions.add(Suggestion(start: start, end: end));
        } catch (_) {}
      }
    }

    String windowReadable = '';
    if (map['window'] is Map) {
      try {
        final w = map['window'] as Map;
        final ws = DateTime.parse(w['start'] as String);
        final we = DateTime.parse(w['end'] as String);
        windowReadable = "${formatDateTime(ws)} — ${formatDateTime(we)}";
      } catch (_) {}
    }

    return ServerError(
      code: code,
      message: message,
      suggestions: suggestions,
      windowReadable: windowReadable,
    );
  }
}

class Suggestion {
  final DateTime start;
  final DateTime end;
  const Suggestion({required this.start, required this.end});
}
