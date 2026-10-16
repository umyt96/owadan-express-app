import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'api_client.dart';

/// Меняется, когда суперпользователь прочитал/ответил на сообщения —
/// бейдж в профиле слушает его и сразу обновляется.
final ValueNotifier<int> adminMessagesTick = ValueNotifier(0);

class ChatUser {
  final int id;
  final String username;
  final String email;
  final String name;

  ChatUser({required this.id, required this.username, required this.email, required this.name});

  String get label => name.isNotEmpty ? '$name ($username)' : username;

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
        id: json['id'],
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
      );
}

/// Раздел "Сообщения клиентов" — только для суперпользователя.
class AdminChatService {
  final Dio _dio = ApiClient.instance.dio;

  List _unwrap(dynamic data) =>
      data is Map && data['results'] != null ? data['results'] as List : data as List;

  Future<({List<ChatMessage> items, bool hasMore})> getMessages({
    int page = 1,
    bool unansweredOnly = false,
  }) async {
    try {
      final response = await _dio.get('/admin-messages/', queryParameters: {
        'page': page,
        if (unansweredOnly) 'unanswered': 1,
      });
      final data = response.data;
      final items = _unwrap(data).map((e) => ChatMessage.fromJson(e)).toList();
      final hasMore = data is Map && data['next'] != null;
      return (items: items, hasMore: hasMore);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<ChatMessage> reply(int messageId, String answer) async {
    try {
      final response = await _dio.patch('/admin-messages/$messageId/', data: {'answer': answer});
      adminMessagesTick.value++;
      return ChatMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Отправить сообщение одному клиенту ([userId]) или всем ([toAll]).
  Future<void> send(String message, {int? userId, bool toAll = false}) async {
    try {
      await _dio.post('/admin-messages/send/', data: {
        'message': message,
        if (userId != null) 'user_id': userId,
        'to_all': toAll,
      });
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get('/admin-messages/unread-count/');
      return response.data['count'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/admin-messages/mark-read/');
      adminMessagesTick.value++;
    } catch (_) {}
  }

  Future<List<ChatUser>> searchUsers(String query) async {
    try {
      final response = await _dio.get('/admin-messages/users/', queryParameters: {'search': query});
      return (response.data as List).map((e) => ChatUser.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
