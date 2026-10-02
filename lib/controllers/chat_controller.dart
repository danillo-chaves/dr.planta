import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_limits.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Controller do chat. Se [plantId] for informado, o backend injeta o contexto
/// da planta e do diário recente no prompt.
class ChatController extends ChangeNotifier {
  ChatController({
    required ChatRepository repository,
    this.plantId,
    this.isPremium = false,
  }) : _repository = repository;

  static const _uuid = Uuid();

  final ChatRepository _repository;
  final String? plantId;
  bool isPremium;

  final List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  // TODO(fase 2): persistir o contador (shared_preferences) e validar no backend.
  int _usedToday = 0;
  DateTime _usedDay = _today();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _sending;
  String? get error => _error;

  int get remainingToday {
    _resetCounterIfNewDay();
    return (AppLimits.freeDailyChatMessages - _usedToday).clamp(0, 999);
  }

  bool get canSend => !_sending && (isPremium || remainingToday > 0);

  Future<void> send(String text, {String? imagePath}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && imagePath == null) return;
    if (!canSend) return;

    _error = null;
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
      plantId: plantId,
      imagePath: imagePath,
    );
    final history = List<ChatMessage>.from(_messages);
    _messages.add(userMessage);
    _sending = true;
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(
        text: trimmed,
        plantId: plantId,
        imagePath: imagePath,
        history: history,
      );
      _messages.add(reply);
      _resetCounterIfNewDay();
      _usedToday++;
    } catch (_) {
      _error = 'Não consegui falar com o Dr. FolhaVida. Tente de novo.';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void _resetCounterIfNewDay() {
    final today = _today();
    if (today != _usedDay) {
      _usedDay = today;
      _usedToday = 0;
    }
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
