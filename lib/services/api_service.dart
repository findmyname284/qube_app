import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:qube/models/booking.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/models/promotion.dart'; // для новостей/акций (Promotion)
import 'package:qube/models/tariff.dart';
import 'package:qube/models/user_token.dart';
import 'package:qube/services/auth_storage.dart';

/// Бросаем это, чтобы UI различал сетевые/HTTP ошибки и мог показать нормальные сообщения
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? inner;
  final Map<String, dynamic>?
  data; // для payload с сервера (error, suggestions, window и т. п.)
  ApiException(this.message, {this.statusCode, this.inner, this.data});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message${inner != null ? ', inner: $inner' : ''}${data != null ? ', data: $data' : ''})';
}

class ApiService {
  ApiService._(this._client);

  static final ApiService instance = ApiService._(http.Client());
  final http.Client _client;

  // --- Конфиг ---
  static const String baseUrl = 'https://qubegg.f1ndnm.site';
  static const Duration _timeout = Duration(seconds: 15);

  // --- Хелперы ---
  static Map<String, String> _baseHeaders({String? token}) => {
    HttpHeaders.contentTypeHeader: 'application/json',
    if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
  };

  static dynamic _decodeBody(http.Response resp) {
    final text = utf8.decode(resp.bodyBytes);
    return text.isEmpty ? null : jsonDecode(text);
  }

  /// Универсальная обвязка для ответов
  T _handle<T>(http.Response resp, T Function(dynamic json) parser) {
    final code = resp.statusCode;
    if (code >= 200 && code < 300) {
      final json = _decodeBody(resp);
      return parser(json);
    }

    // Попробуем достать полезный payload
    Map<String, dynamic>? data;
    String message = 'HTTP $code';
    try {
      final json = _decodeBody(resp);
      if (json is Map<String, dynamic>) {
        data = json;
        if (json['message'] is String) {
          message = json['message'] as String;
        } else if (json['error'] is String) {
          // иногда только error
          message = json['error'] as String;
        }
      }
    } catch (_) {
      /* ignore */
    }

    if (code == 401 || code == 403) {
      AuthStorage.clearToken(); // протух токен
    }

    throw ApiException(message, statusCode: code, data: data);
  }

  // =================== COMPUTERS ===================

  Future<List<Computer>> fetchComputers() async {
    final token = await AuthStorage.getToken();
    try {
      final uri = Uri.parse('$baseUrl/computers');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<List<Computer>>(resp, (json) {
        final list = (json as List<dynamic>? ?? const []);
        return list
            .map((e) => Computer.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    } on HttpException catch (e) {
      throw ApiException('Ошибка соединения', inner: e);
    } on FormatException catch (e) {
      throw ApiException('Некорректный ответ сервера', inner: e);
    }
  }

  Future<Computer> fetchComputer(int id) async {
    final token = await AuthStorage.getToken();
    try {
      final uri = Uri.parse('$baseUrl/computers/$id');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<Computer>(
        resp,
        (json) => Computer.fromJson(json as Map<String, dynamic>),
      );
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    } on FormatException catch (e) {
      throw ApiException('Некорректный ответ сервера', inner: e);
    }
  }

  /// Интервалы занятости для часов (уже с учётом grace на бэке)
  Future<Map<String, dynamic>> fetchBookedIntervals(int computerId) async {
    final token = await AuthStorage.getToken();
    try {
      final uri = Uri.parse('$baseUrl/computers/booked/$computerId');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);
      return _handle<Map<String, dynamic>>(
        resp,
        (json) => (json as Map).cast<String, dynamic>(),
      );
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    } on FormatException catch (e) {
      throw ApiException('Некорректный ответ сервера', inner: e);
    }
  }

  /// Доступные окна и (опционально) подсказки
  Future<Map<String, dynamic>> fetchAvailability(
    int computerId, {
    int? durationHours,
    DateTime? desiredStartLocal,
  }) async {
    final token = await AuthStorage.getToken();
    try {
      final q = <String, String>{};
      if (durationHours != null) q['duration_hours'] = '$durationHours';
      if (desiredStartLocal != null) {
        q['desired_start'] = desiredStartLocal.toUtc().toIso8601String();
      }
      final uri = Uri.parse(
        '$baseUrl/computers/$computerId/availability',
      ).replace(queryParameters: q.isEmpty ? null : q);
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);
      return _handle<Map<String, dynamic>>(
        resp,
        (json) => (json as Map).cast<String, dynamic>(),
      );
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  // =================== AUTH & PROFILE ===================

  Future<UserToken> login({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/login');
      final resp = await _client
          .post(
            uri,
            headers: _baseHeaders(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      return _handle<UserToken>(
        resp,
        (json) => UserToken.fromJson(json as Map<String, dynamic>),
      );
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  Future<UserToken> register(String username, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/register');
      final resp = await _client
          .post(
            uri,
            headers: _baseHeaders(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);

      return _handle<UserToken>(
        resp,
        (json) => UserToken.fromJson(json as Map<String, dynamic>),
      );
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  Future<Profile?> getProfile() async {
    final token = await AuthStorage.getToken();
    if (token == null) return null;
    try {
      final uri = Uri.parse('$baseUrl/me');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<Profile?>(
        resp,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return null;
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  // =================== NEWS / PROMOTIONS ===================

  /// Сервер отдаёт список новостей; маппим в твою модель Promotion
  Future<List<Promotion>> fetchPromotions() async {
    final token = await AuthStorage.getToken(); // можно и без токена
    try {
      final uri = Uri.parse('$baseUrl/news');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<List<Promotion>>(resp, (json) {
        final list = (json as List<dynamic>? ?? const []);
        return list.map((e) {
          final m = (e as Map).cast<String, dynamic>();
          // сервер дублирует поля под клиент:
          // title, description, imageUrl, endDate (ISO)
          return Promotion(
            id: m['id'] as String?,
            title: (m['title'] ?? '') as String,
            description: (m['description'] ?? '') as String,
            imageUrl: m['imageUrl'] as String?,
            // если в модели Promotion endDate: DateTime?
            endDate:
                (m['endDate'] is String && (m['endDate'] as String).isNotEmpty)
                ? DateTime.parse(m['endDate'] as String).toLocal()
                : null,
            // gradient/иконку ты задаёшь на клиенте — опционально
          );
        }).toList();
      });
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    } on FormatException catch (e) {
      throw ApiException('Некорректный ответ сервера', inner: e);
    }
  }

  // =================== TARIFFS ===================

  /// Возвращаем в том виде, как ждёт твой UI: {'title': String, 'price': int, 'minutes': int, 'description': String}
  Future<List<Tariff>> fetchTariffs({String? zone}) async {
    final token = await AuthStorage.getToken();
    try {
      final uri = Uri.parse(
        '$baseUrl/tariffs',
      ).replace(queryParameters: zone != null ? {'zone': zone} : null);
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<List<Tariff>>(resp, (json) {
        final list = (json as List<dynamic>? ?? const []);
        return list
            .map((e) => Tariff.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  // =================== BOOKINGS ===================

  Future<List<Booking>> fetchBookings() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    try {
      final uri = Uri.parse('$baseUrl/booking');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<List<Booking>>(resp, (json) {
        final list = (json as List<dynamic>? ?? const []);
        return list
            .map((e) => Booking.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  Future<List<Tariff>> fetchTariffsForComputer(int computerId) async {
    final token = await AuthStorage.getToken();
    try {
      final uri = Uri.parse('$baseUrl/computers/$computerId/tariffs');
      final resp = await _client
          .get(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      return _handle<List<Tariff>>(resp, (json) {
        final list = (json as List<dynamic>? ?? const []);
        return list
            .map((e) => Tariff.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  /// Старый метод (обратная совместимость).
  /// Для создания: передай startLocal + duration (+ graceMin).
  /// Для отмены: commandType='release' и (опционально) bookingId.
  Future<void> booking(
    int computerId,
    String commandType,
    DateTime? startLocal,
    Duration? duration, {
    int? graceMin,
    String? bookingId,
    String? tariffId,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    final body = {"command_type": commandType};

    if (commandType == 'release') {
      if (bookingId != null) {
        body['booking_id'] = bookingId;
      }
    } else {
      if (startLocal == null || duration == null) {
        throw ApiException('Не указаны start/duration для брони');
      }
      body["start"] = startLocal.toUtc().toIso8601String();
      body["end"] = startLocal.add(duration).toUtc().toIso8601String();
      if (graceMin != null) body["grace_min"] = graceMin.toString();
      if (tariffId != null) body["tariff_id"] = tariffId;
    }

    try {
      final uri = Uri.parse('$baseUrl/booking/$computerId');
      final resp = await _client
          .post(
            uri,
            headers: _baseHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      _handle<void>(resp, (_) {});
    } on ApiException catch (e) {
      // Сделаем сообщение более дружелюбным при 409
      if (e.statusCode == 409) {
        final msg =
            e.data?['message'] as String? ??
            'Компьютер уже забронирован на это время';
        throw ApiException(msg, statusCode: 409, data: e.data);
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  /// Новый удобный метод: создать бронь (с поддержкой graceMin)
  Future<Map<String, dynamic>> createBooking({
    required int computerId,
    required DateTime startLocal,
    required Duration duration,
    int? graceMin,
    String commandType = 'maintenance',
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    final body = <String, dynamic>{
      "command_type": commandType,
      "start": startLocal.toUtc().toIso8601String(),
      "end": startLocal.add(duration).toUtc().toIso8601String(),
      if (graceMin != null) "grace_min": graceMin,
    };

    try {
      final uri = Uri.parse('$baseUrl/booking/$computerId');
      final resp = await _client
          .post(
            uri,
            headers: _baseHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handle<Map<String, dynamic>>(
        resp,
        (json) => (json as Map).cast<String, dynamic>(),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // на UI удобно иметь suggestions/free/window
        throw ApiException(
          e.data?['message'] as String? ?? 'Пересечение с существующей бронью',
          statusCode: 409,
          data: e.data,
        );
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  /// Отмена одной конкретной брони по bookingId
  Future<void> cancelBookingById({
    required int computerId,
    required String bookingId,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    try {
      // Можно через DELETE …/booking/<cid>/<booking_id>
      final uri = Uri.parse('$baseUrl/booking/$computerId/$bookingId');
      final resp = await _client
          .delete(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      _handle<void>(resp, (_) {});
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw ApiException('Бронь не найдена', statusCode: 404);
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  /// Отмена «одной из» броней пользователя на ПК (активная → ближайшая → последняя прошлая)
  Future<void> releaseOneBookingSmart(int computerId) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    try {
      final uri = Uri.parse('$baseUrl/booking/$computerId');
      final resp = await _client
          .post(
            uri,
            headers: _baseHeaders(token: token),
            body: jsonEncode({"command_type": "release"}),
          )
          .timeout(_timeout);

      _handle<void>(resp, (_) {});
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw ApiException('Нет брони для отмены', statusCode: 404);
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  // --- Завершение клиента ---
  void close() => _client.close();
}
