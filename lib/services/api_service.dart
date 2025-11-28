import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qube/models/bonuses.dart';
import 'package:qube/models/booking.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/models/promotion.dart';
import 'package:qube/models/user_token.dart';
import 'package:qube/screens/profile/models/tariff.dart';
import 'package:qube/screens/profile/models/ticket.dart';
import 'package:qube/screens/profile/models/zone.dart';
import 'package:qube/services/auth_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? inner;
  final Map<String, dynamic>? data;
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
  //   static const String baseUrl = 'https://qubegg.f1ndnm.site';
  //   static const String baseUrl = 'http://10.113.89.31:8080';
  static const String baseUrl = 'http://192.168.10.73:8080';
  //   static const String baseUrl = 'http://127.0.0.1:8080';
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

  /// Основной метод для авторизованных запросов с автоматическим обновлением токенов
  Future<http.Response> _authorizedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final token = await AuthStorage.getAccessToken();
    var uri = Uri.parse('$baseUrl$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    // Первый запрос
    var response = await _makeRequest(method, uri, token, body);

    // Если получили 401, пробуем обновить токен и повторить запрос
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        final newToken = await AuthStorage.getAccessToken();
        response = await _makeRequest(method, uri, newToken, body);
      } else {
        // Не удалось обновить - выбрасываем исключение
        throw ApiException('Сессия истекла. Войдите заново.', statusCode: 401);
      }
    }

    return response;
  }

  /// Вспомогательный метод для создания запроса
  Future<http.Response> _makeRequest(
    String method,
    Uri uri,
    String? token,
    Map<String, dynamic>? body,
  ) async {
    try {
      final request = http.Request(method, uri)
        ..headers.addAll(_baseHeaders(token: token));

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    } on HttpException catch (e) {
      throw ApiException('Ошибка соединения', inner: e);
    }
  }

  /// Метод для обновления токенов
  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await AuthStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('$baseUrl/refresh');
      final response = await _client
          .post(uri, headers: _baseHeaders(token: refreshToken))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = _decodeBody(response);
        final tokens = UserToken.fromJson(json as Map<String, dynamic>);
        await AuthStorage.saveTokens(tokens.accessToken, tokens.refreshToken);
        return true;
      } else {
        // Refresh token истек или невалиден
        await AuthStorage.clearTokens();
        return false;
      }
    } catch (e) {
      await AuthStorage.clearTokens();
      return false;
    }
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
          message = json['error'] as String;
        }
      }
    } catch (_) {
      /* ignore */
    }

    throw ApiException(message, statusCode: code, data: data);
  }

  // =================== COMPUTERS ===================

  Future<List<Computer>> fetchComputers() async {
    final resp = await _authorizedRequest('GET', '/computers');
    return _handle<List<Computer>>(resp, (json) {
      if (json is! List<dynamic>) {
        return const [];
      }
      final list = json;
      return list
          .map((e) => Computer.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Computer> fetchComputer(int id) async {
    final resp = await _authorizedRequest('GET', '/computers/$id');
    return _handle<Computer>(
      resp,
      (json) => Computer.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> fetchBookedIntervals(int computerId) async {
    final resp = await _authorizedRequest(
      'GET',
      '/computers/booked/$computerId',
    );
    return _handle<Map<String, dynamic>>(
      resp,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// Доступные окна и (опционально) подсказки
  Future<Map<String, dynamic>> fetchAvailability(
    int computerId, {
    int? durationHours,
    DateTime? desiredStartLocal,
  }) async {
    final q = <String, String>{};
    if (durationHours != null) q['duration_hours'] = '$durationHours';
    if (desiredStartLocal != null) {
      q['desired_start'] = desiredStartLocal.toUtc().toIso8601String();
    }

    final resp = await _authorizedRequest(
      'GET',
      '/computers/$computerId/availability',
      queryParameters: q.isEmpty ? null : q,
    );

    return _handle<Map<String, dynamic>>(
      resp,
      (json) => (json as Map).cast<String, dynamic>(),
    );
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
            body: jsonEncode({'login': username, 'password': password}),
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

  Future<UserToken> refreshToken() async {
    final token = await AuthStorage.getRefreshToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    try {
      final uri = Uri.parse('$baseUrl/refresh');
      final resp = await _client
          .post(uri, headers: _baseHeaders(token: token))
          .timeout(_timeout);

      if (resp.statusCode == 401) {
        throw ApiException('Пользователь не авторизован');
      }

      return _handle<UserToken>(
        resp,
        (json) => UserToken.fromJson(json as Map<String, dynamic>),
      );
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  Future<Profile?> getProfile() async {
    try {
      final resp = await _authorizedRequest('GET', '/me');
      return _handle<Profile?>(
        resp,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await AuthStorage.clearTokens();
        return null;
      }
      rethrow;
    }
  }

  Future<double?> getDiscount() async {
    try {
      final resp = await _authorizedRequest('GET', '/discount');
      final json = _handle<Map<String, dynamic>>(resp, (json) => json);
      return json['discount'] as double?;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await AuthStorage.clearTokens();
        return null;
      }
      rethrow;
    }
  }

  // =================== NEWS / PROMOTIONS ===================

  Future<List<Promotion>> fetchPromotions() async {
    final resp = await _authorizedRequest('GET', '/news');
    return _handle<List<Promotion>>(resp, (json) {
      final list = (json as List<dynamic>? ?? const []);
      return list.map((e) {
        final m = (e as Map).cast<String, dynamic>();
        final category = (m['category'] ?? 'Акции') as String;
        return Promotion(
          id: m['id'] as String?,
          title: (m['title'] ?? '') as String,
          description: (m['description'] ?? '') as String,
          imageUrl: m['image_url'] as String?,
          category: category,
          endDate:
              (m['end_date'] is String && (m['end_date'] as String).isNotEmpty)
              ? DateTime.parse(m['end_date'] as String).toLocal()
              : null,
          icon: category != 'Акции'
              ? Icons.campaign_rounded
              : Icons.local_offer_rounded,
        );
      }).toList();
    });
  }

  // =================== TARIFFS ===================

  Future<List<Zone>> fetchZones() async {
    final resp = await _authorizedRequest('GET', '/zones');
    return _handle<List<Zone>>(resp, (json) {
      if (json is! List<dynamic>) return const [];
      return json.map((e) => Zone.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<List<Tariff>> fetchTariffs({String? zone}) async {
    final q = zone != null ? {'zone': zone} : null;
    final resp = await _authorizedRequest(
      'GET',
      '/tariffs',
      queryParameters: q,
    );
    return _handle<List<Tariff>>(resp, (json) {
      if (json is! List<dynamic>) return const [];
      return json
          .map((e) => Tariff.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<Ticket>> fetchTickets({String? zone}) async {
    final q = zone != null ? {'zone': zone} : null;
    final resp = await _authorizedRequest(
      'GET',
      '/tickets',
      queryParameters: q,
    );
    return _handle<List<Ticket>>(resp, (json) {
      if (json is! List<dynamic>) return const [];
      return json
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  // =================== BOOKINGS ===================

  Future<List<Booking>> fetchBookings() async {
    final resp = await _authorizedRequest('GET', '/booking');
    return _handle<List<Booking>>(resp, (json) {
      final list = (json as List<dynamic>? ?? const []);
      return list
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<Tariff>> fetchTariffsForComputer(int computerId) async {
    final resp = await _authorizedRequest(
      'GET',
      '/computers/$computerId/tariffs',
    );
    return _handle<List<Tariff>>(resp, (json) {
      final list = (json as List<dynamic>? ?? const []);
      return list
          .map((e) => Tariff.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Старый метод (обратная совместимость)
  Future<void> booking(
    int computerId,
    String commandType,
    DateTime? startLocal,
    Duration? duration, {
    int? graceMin,
    String? bookingId,
    int? tariffId,
  }) async {
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
      if (tariffId != null) body["tariff_id"] = tariffId.toString();
    }

    final resp = await _authorizedRequest(
      'POST',
      '/booking/$computerId',
      body: body,
    );

    _handle<void>(resp, (_) {});
  }

  /// Новый удобный метод: создать бронь
  Future<Map<String, dynamic>> createBooking({
    required int computerId,
    required DateTime startLocal,
    required Duration duration,
    int? graceMin,
    String commandType = 'maintenance',
  }) async {
    final body = <String, dynamic>{
      "command_type": commandType,
      "start": startLocal.toUtc().toIso8601String(),
      "end": startLocal.add(duration).toUtc().toIso8601String(),
      if (graceMin != null) "grace_min": graceMin,
    };

    final resp = await _authorizedRequest(
      'POST',
      '/booking/$computerId',
      body: body,
    );

    return _handle<Map<String, dynamic>>(
      resp,
      (json) => (json as Map).cast<String, dynamic>(),
    );
  }

  /// Отмена одной конкретной брони по bookingId
  Future<void> cancelBookingById({
    required int computerId,
    required String bookingId,
  }) async {
    final resp = await _authorizedRequest(
      'DELETE',
      '/booking/$computerId/$bookingId',
    );

    _handle<void>(resp, (_) {});
  }

  /// Отмена «одной из» броней пользователя на ПК
  Future<void> releaseOneBookingSmart(int computerId) async {
    final resp = await _authorizedRequest(
      'POST',
      '/booking/$computerId',
      body: {"command_type": "release"},
    );

    _handle<void>(resp, (_) {});
  }

  Future<Bonuses> calculateBonus(int amount, {String source = 'app'}) async {
    final resp = await _authorizedRequest('GET', '/calculate/bonus/$amount');

    return _handle<Bonuses>(resp, (json) => Bonuses.fromJson(json));
  }

  Future<String> topUpBalance(int amount, {String source = 'app'}) async {
    final resp = await _authorizedRequest(
      'POST',
      '/account/refill',
      body: {"amount": amount, "source": source},
    );

    // Обрабатываем ответ и извлекаем ссылку
    final jsonData = json.decode(resp.body);
    final String paymentLink = jsonData['invoice']['link'];

    _launchURL(Uri.parse(paymentLink));
    return paymentLink;
  }

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Не удалось открыть';
    }
  }

  // --- Завершение клиента ---
  void close() => _client.close();
}
