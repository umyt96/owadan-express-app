import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранит id последнего сообщения, ответ на которое пользователь уже видел.
/// Бэкенд не различает "прочитано/не прочитано" у сообщений (это простой
/// вопрос-ответ, а не полноценный чат с таким статусом), поэтому подсчёт
/// непрочитанных ответов администратора делается на телефоне: сравниваем
/// id сообщений с ответом с последним просмотренным.
class MessageReadStorage {
  MessageReadStorage._();
  static final MessageReadStorage instance = MessageReadStorage._();

  final _storage = const FlutterSecureStorage();
  static const _lastSeenKey = 'last_seen_message_id';

  Future<int> getLastSeenId() async {
    final value = await _storage.read(key: _lastSeenKey);
    return int.tryParse(value ?? '') ?? 0;
  }

  Future<void> setLastSeenId(int id) async {
    await _storage.write(key: _lastSeenKey, value: id.toString());
  }
}
