import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/chat_controller.dart';
import '../../models/chat_message.dart';
import '../../models/plant.dart';
import '../../repositories/chat_repository.dart';

/// Chat com o Dr. FolhaVida, aberto a partir de uma planta.
class ChatView extends StatelessWidget {
  const ChatView({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatController(
        repository: context.read<ChatRepository>(),
        plantId: plant.id,
      ),
      child: _ChatScaffold(plant: plant),
    );
  }
}

class _ChatScaffold extends StatefulWidget {
  const _ChatScaffold({required this.plant});

  final Plant plant;

  @override
  State<_ChatScaffold> createState() => _ChatScaffoldState();
}

class _ChatScaffoldState extends State<_ChatScaffold> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text;
    _input.clear();
    context.read<ChatController>().send(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. FolhaVida · ${widget.plant.name}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              chat.isPremium
                  ? 'Consultas ilimitadas'
                  : '${chat.remainingToday} consultas restantes hoje',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? const Center(child: Text('Pergunte algo sobre sua planta 🌿'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, i) => _Bubble(message: chat.messages[i]),
                  ),
          ),
          if (chat.isSending) const LinearProgressIndicator(),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                chat.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: chat.canSend,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: chat.canSend
                            ? 'Descreva o problema...'
                            : 'Limite diário atingido',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: chat.canSend ? _send : null,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text),
      ),
    );
  }
}
