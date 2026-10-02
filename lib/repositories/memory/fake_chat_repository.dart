import 'package:uuid/uuid.dart';

import '../../models/chat_message.dart';
import '../chat_repository.dart';

/// Resposta simulada até a Cloud Function + Gemini existirem.
class FakeChatRepository implements ChatRepository {
  static const _uuid = Uuid();

  @override
  Future<ChatMessage> sendMessage({
    required String text,
    String? plantId,
    String? imagePath,
    List<ChatMessage> history = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      plantId: plantId,
      createdAt: DateTime.now(),
      text: 'Olá! Sou o Dr. FolhaVida 🌱. Ainda estou em modo de testes, '
          'mas em breve vou analisar sua planta de verdade.',
    );
  }
}
