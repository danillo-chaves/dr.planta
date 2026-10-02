# Dr. FolhaVida

Assistente de jardinagem e guia de cuidados com plantas para casa/apartamento, com diário de cuidados e chat conversacional com IA. Flutter + Firebase + Gemini. Meta: publicar na Play Store.

## Produto (MVP)

- **Meus Vasos (Home):** lista de plantas, registro de 1 toque (🪵 Reguei · 🧪 Adubei · ✂️ Podei) e indicador de estado ("Solo úmido", "Regar hoje").
- **Catálogo de espécies:** fichas com o que pode/não pode (luz, rega, pet friendly). 100% offline.
- **Chat Dr. FolhaVida:** IA com contexto automático (planta, local, diário recente) e análise de fotos. Respostas de no máximo 3–4 frases.
- **Notificações locais:** lembretes de rega/adubação agendados no aparelho (`flutter_local_notifications`).

## Monetização

| | Free | Premium (assinatura / lifetime) |
|---|---|---|
| Plantas | até 3 | ilimitadas |
| Chat IA | 3 consultas/dia | ilimitado |
| Anúncios | AdMob discretos | sem anúncios |

Apenas Chat/Fotos chamam a IA (via Cloud Functions, nunca direto do app). Catálogo e notificações são locais.

## Arquitetura: MVC

```
lib/
├── main.dart / app.dart        # entrada + providers (troque implementações aqui)
├── core/                       # tema, constantes (limites do free), rotas
├── models/                     # M: Plant, DiaryEntry, ChatMessage (dados puros)
├── repositories/               # contratos de acesso a dados (+ memory/ = implementações temporárias)
├── controllers/                # C: ChangeNotifier com a lógica (PlantController, ChatController)
└── views/                      # V: telas e widgets, só leem o controller e disparam ações
```

Regras: View nunca acessa Repository; Controller nunca importa `package:flutter/material.dart`; Model não conhece ninguém. Estado via `provider`.

## Roadmap

1. **Base (feito):** models, repositories em memória, PlantController, ChatController, Home e Chat básicos.
2. Persistência local + catálogo de espécies offline.
3. Notificações locais.
4. Firebase (auth, Firestore) + Cloud Function com Gemini (system prompt, contexto, fotos).
5. AdMob + assinatura (paywall).
6. Polimento, ícones, Play Console.
