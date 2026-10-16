import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../storage/message_read_storage.dart';
import 'api_client.dart';

/// Увеличивается каждый раз, когда сообщения отмечаются прочитанными —
/// бейдж "Сообщение" в профиле слушает это, чтобы сразу пропасть при
/// открытии чата, даже если сам профиль не пересоздавался.
final ValueNotifier<int> messagesSeenTick = ValueNotifier(0);

class MessageService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ChatMessage>> getMessages() async {
    try {
      final response = await _dio.get('/messages/');
      final data = response.data;
      final list = data is Map && data['results'] != null ? data['results'] : data;
      return (list as List).map((e) => ChatMessage.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }

  /// Сколько сообщений с ответом администратора пользователь ещё не открывал
  /// на экране "Сообщения" — для красного бейджа в профиле.
  Future<int> getUnreadCount() async {
    try {
      final messages = await getMessages();
      final lastSeen = await MessageReadStorage.instance.getLastSeenId();
      return messages.where((m) => m.answer != null && m.id > lastSeen).length;
    } catch (_) {
      return 0;
    }
  }

  /// Отмечает все текущие сообщения как просмотренные — вызывается при
  /// открытии экрана "Сообщения".
  Future<void> markAllAsSeen(List<ChatMessage> messages) async {
    if (messages.isEmpty) return;
    final maxId = messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
    await MessageReadStorage.instance.setLastSeenId(maxId);
    messagesSeenTick.value++;
  }

  Future<ChatMessage> sendMessage(String message, {int? productId}) async {
    try {
      final response = await _dio.post('/messages/', data: {
        'message': message,
        if (productId != null) 'product': productId,
      });
      return ChatMessage.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiClient.instance.toApiException(e);
    }
  }
}
