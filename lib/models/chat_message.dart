enum ChatRole { user, assistant }

/// Mensagem do chat com o Dr. FolhaVida.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.plantId,
    this.imagePath,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  /// Planta de origem da conversa. O backend usa para injetar o contexto
  /// (nome, local e registros recentes do diário) no system prompt.
  final String? plantId;

  /// Foto anexada (análise multimodal).
  final String? imagePath;

  bool get isUser => role == ChatRole.user;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.byName(json['role'] as String),
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      plantId: json['plantId'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'plantId': plantId,
        'imagePath': imagePath,
      };
}
