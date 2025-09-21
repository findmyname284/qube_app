import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:qube/models/booking.dart';
import 'package:qube/models/computer.dart';
import 'package:qube/models/me.dart';
import 'package:qube/models/news.dart';
import 'package:qube/models/user_token.dart';
import 'package:qube/services/auth_storage.dart';

/// Общие исключения API, чтобы различать сетевые/HTTP ошибки в UI
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? inner;
  ApiException(this.message, {this.statusCode, this.inner});
  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message${inner != null ? ', inner: $inner' : ''})';
}

class ApiService {
  ApiService._(this._client);

  static final ApiService instance = ApiService._(http.Client());

  final http.Client _client;

  // --- Конфиг ---
  static const String baseUrl = 'https://qubegg.f1ndnm.site';
  static const Duration _timeout = Duration(seconds: 15);

  // --- Вспомогательные методы ---
  static Map<String, String> _baseHeaders({String? token}) => {
    HttpHeaders.contentTypeHeader: 'application/json',
    if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
  };

  /// Декод JSON с учётом возможной не-UTF8 разметки
  static dynamic _decodeBody(http.Response resp) {
    // используем bodyBytes -> utf8.decode, чтобы безопасно работать с любыми кодировками
    final text = utf8.decode(resp.bodyBytes);
    return text.isEmpty ? null : jsonDecode(text);
  }

  T _handle<T>(http.Response resp, T Function(dynamic json) parser) {
    final code = resp.statusCode;
    if (code >= 200 && code < 300) {
      final json = _decodeBody(resp);
      return parser(json);
    }

    // Попробуем вытащить сообщение об ошибке из JSON {"message": "..."}
    String message = 'HTTP $code';
    try {
      final json = _decodeBody(resp);
      if (json is Map && json['message'] is String) {
        message = json['message'] as String;
      }
    } catch (_) {
      // игнор — оставим дефолт
    }

    // Спец-случаи
    if (code == 401 || code == 403) {
      // токен протух — подчистим сразу
      AuthStorage.clearToken();
    }

    throw ApiException(message, statusCode: code);
  }

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

  /// Пример вызова стороннего эндпоинта (оставлен, но приведён к общему стилю)
  Future<void> fetchRegistrationRequiredFields() async {
    try {
      final uri = Uri.parse(
        'https://featureenv1.app.t.enes.tech/me/v2/registration/required_fields/',
      );
      final resp = await _client
          .get(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              'Origin': 'https://qubegg.shell.enes.tech',
              'Referer': 'https://qubegg.shell.enes.tech/',
            },
          )
          .timeout(_timeout);

      _handle<void>(resp, (_) {});
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

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

      // 401/403 обработаются в _handle и вернут исключение — для UX можно проглотить и вернуть null
      return _handle<Profile?>(
        resp,
        (json) => Profile.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return null;
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  Future<List<News>> getNews() async {
    // TODO: реальный эндпоинт, сейчас — демо
    return [News(), News(), News()];
  }

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

  /// Создание/отмена брони. commandType: 'maintenance' | 'release' и т.п.
  Future<void> booking(int computerId, String commandType) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw ApiException('Пользователь не авторизован');

    try {
      final uri = Uri.parse('$baseUrl/booking/$computerId');
      final resp = await _client
          .post(
            uri,
            headers: _baseHeaders(token: token),
            body: jsonEncode({'command_type': commandType}),
          )
          .timeout(_timeout);

      _handle<void>(resp, (_) {});
    } on ApiException catch (e) {
      // Пример более информативной конфликтной ошибки
      if (e.statusCode == 409) {
        throw ApiException(
          'Компьютер уже забронирован другим пользователем',
          statusCode: 409,
        );
      }
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('Нет соединения с сервером', inner: e);
    }
  }

  // --- Возможное расширение: единый метод закрытия клиента (например, при dispose) ---
  void close() => _client.close();
}
