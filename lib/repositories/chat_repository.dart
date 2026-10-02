import '../models/chat_message.dart';

/// Contrato do chat com a IA.
///
/// A implementação real chamará uma Cloud Function, que monta o system prompt
/// (respostas de no máximo 3-4 frases), injeta o contexto da planta + diário
/// recente e chama o Gemini. O app nunca fala direto com a API da IA.
abstract class ChatRepository {
  Future<ChatMessage> sendMessage({
    required String text,
    String? plantId,
    String? imagePath,
    List<ChatMessage> history = const [],
  });
}
