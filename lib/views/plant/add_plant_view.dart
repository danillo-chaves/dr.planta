import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/plant_controller.dart';
import '../../core/constants/app_limits.dart';
import '../../models/plant_species.dart';
import '../species/species_picker_view.dart';

enum _Watered {
  today('Hoje', 0),
  yesterday('Ontem', 1),
  twoDays('Há 2 dias', 2),
  threeDays('Há 3 dias', 3),
  other('Outra data', null),
  unknown('Não sei', null);

  const _Watered(this.label, this.daysAgo);
  final String label;
  final int? daysAgo;
}

/// Cadastro de planta. A planta é sempre de uma espécie real do catálogo:
/// é ela que define os cuidados. Aqui o usuário informa o contexto (local,
/// luz recebida e última rega com horário), usado depois nos lembretes.
class AddPlantView extends StatefulWidget {
  const AddPlantView({super.key, this.species});

  /// Espécie já escolhida (ex: vindo da ficha do catálogo).
  final PlantSpecies? species;

  /// Abre o cadastro respeitando o limite do plano free.
  /// Retorna true se a planta foi cadastrada.
  static Future<bool> open(BuildContext context, {PlantSpecies? species}) async {
    if (!context.read<PlantController>().canAddPlant) {
      // TODO(fase 5): abrir paywall do Premium.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O plano grátis permite até ${AppLimits.freeMaxPlants} plantas. '
            'Assine o Premium para cadastrar mais.',
          ),
        ),
      );
      return false;
    }
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddPlantView(species: species)),
    );
    return added ?? false;
  }

  @override
  State<AddPlantView> createState() => _AddPlantViewState();
}

class _AddPlantViewState extends State<AddPlantView> {
  static const _locations = [
    'Sala',
    'Quarto',
    'Cozinha',
    'Varanda',
    'Banheiro',
    'Escritório',
    'Jardim',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();

  PlantSpecies? _species;
  LightLevel? _exposure;
  _Watered _watered = _Watered.today;
  DateTime? _otherDate;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _species = widget.species;
    _name.text = widget.species?.name ?? '';
    _location.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  /// Luz escolhida pelo usuário ou, enquanto não escolher, a ideal da espécie.
  LightLevel? get _effectiveExposure => _exposure ?? _species?.light;

  DateTime? get _lastWateredAt {
    final DateTime day;
    final now = DateTime.now();
    switch (_watered) {
      case _Watered.unknown:
        return null;
      case _Watered.other:
        final other = _otherDate;
        if (other == null) return null;
        day = other;
      default:
        day = DateTime(now.year, now.month, now.day - _watered.daysAgo!);
    }
    return DateTime(day.year, day.month, day.day, _time.hour, _time.minute);
  }

  Future<void> _pickSpecies() async {
    final picked = await Navigator.of(context).push<PlantSpecies>(
      MaterialPageRoute(builder: (_) => const SpeciesPickerView()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final previous = _species;
      // Só troca o apelido se o usuário ainda não personalizou.
      if (_name.text.trim().isEmpty || _name.text == previous?.name) {
        _name.text = picked.name;
      }
      _species = picked;
    });
  }

  Future<void> _pickOtherDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _otherDate ?? now,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      helpText: 'Quando foi a última rega?',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _otherDate = picked;
      _watered = _Watered.other;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: _watered == _Watered.unknown
          ? 'Melhor horário para lembretes'
          : 'Que horas você regou?',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final species = _species;
    if (species == null || !_formKey.currentState!.validate()) return;

    final last = _lastWateredAt;
    if (last != null && last.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse horário ainda não chegou. Ajuste a hora da rega.')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final plant = await context.read<PlantController>().addPlant(
          species: species,
          name: _name.text,
          location: _location.text,
          sunExposure: _effectiveExposure!,
          wateringHour: _time.hour,
          wateringMinute: _time.minute,
          lastWateredAt: last,
        );
    navigator.pop(plant != null);
  }

  @override
  Widget build(BuildContext context) {
    final species = _species;
    final exposure = _effectiveExposure;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova planta')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _SectionTitle('1', 'Qual planta é?'),
            _SpeciesCard(species: species, onTap: _pickSpecies),
            const SizedBox(height: 24),
            const _SectionTitle('2', 'Apelido e local'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Apelido',
                helperText: 'Ex: "Jiboia da sala"',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Dê um nome à planta' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Onde ela fica?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o local' : null,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final place in _locations)
                  ChoiceChip(
                    label: Text(place),
                    selected: _location.text == place,
                    onSelected: (_) => _location.text = place,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('3', 'Quanta luz ela recebe?'),
            Row(
              children: [
                for (final level in LightLevel.values.reversed) ...[
                  Expanded(
                    child: _LightOption(
                      level: level,
                      selected: exposure == level,
                      onTap: () => setState(() => _exposure = level),
                    ),
                  ),
                  if (level != LightLevel.low) const SizedBox(width: 8),
                ],
              ],
            ),
            if (species != null && exposure != null) ...[
              const SizedBox(height: 12),
              _LightAdvice(species: species, exposure: exposure),
            ],
            const SizedBox(height: 24),
            const _SectionTitle('4', 'Última rega'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in _Watered.values)
                  ChoiceChip(
                    label: Text(
                      option == _Watered.other && _otherDate != null
                          ? _formatDate(_otherDate!)
                          : option.label,
                    ),
                    selected: _watered == option,
                    onSelected: (_) {
                      if (option == _Watered.other) {
                        _pickOtherDate();
                      } else {
                        setState(() => _watered = option);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _TimeField(
              label: _watered == _Watered.unknown
                  ? 'Horário dos lembretes de rega'
                  : 'Horário da rega',
              time: _time,
              onTap: _pickTime,
            ),
            if (species != null && exposure != null) ...[
              const SizedBox(height: 24),
              _CarePlanCard(
                species: species,
                exposure: exposure,
                lastWateredAt: _lastWateredAt,
                time: _time,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: species == null ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                species == null ? 'Escolha a planta primeiro' : 'Cadastrar planta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}';
String _formatTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.number, this.title);

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.species, required this.onTap});

  final PlantSpecies? species;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = species;

    return Material(
      color: s == null ? scheme.primaryContainer.withValues(alpha: 0.4) : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: s == null ? scheme.primary : scheme.outlineVariant,
              width: s == null ? 1.5 : 1,
            ),
          ),
          child: s == null
              ? Row(
                  children: [
                    Icon(Icons.search_rounded, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Escolher a planta do catálogo',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: scheme.primary),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.primary),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(s.emoji, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            s.scientificName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: onTap, child: const Text('Trocar')),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LightOption extends StatelessWidget {
  const _LightOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final LightLevel level;
  final bool selected;
  final VoidCallback onTap;

  static String _hint(LightLevel level) => switch (level) {
        LightLevel.high => 'Várias horas de sol direto',
        LightLevel.medium => 'Clara, sem sol direto',
        LightLevel.low => 'Sombra ou longe da janela',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(level.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                level.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                _hint(level),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightAdvice extends StatelessWidget {
  const _LightAdvice({required this.species, required this.exposure});

  final PlantSpecies species;
  final LightLevel exposure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fit = species.lightFit(exposure);
    final ideal = species.light.label.toLowerCase();

    final (text, bg, fg) = switch (fit) {
      LightFit.ideal => (
          '✅ Luz perfeita para ${species.name}.',
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      LightFit.tooMuch => (
          '⚠️ Esse sol pode ser demais para ${species.name} (ideal: $ideal). '
              'Se as folhas queimarem, afaste da janela. Vou deixar a rega mais frequente.',
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      LightFit.tooLittle => (
          '⚠️ Pode faltar luz para ${species.name} (ideal: $ideal). '
              'Ela cresce mais devagar e pede menos água, então vou espaçar a rega.',
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 13)),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              Text(
                _formatTime(time),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostra o que o app vai fazer com a espécie + luz + última rega.
class _CarePlanCard extends StatelessWidget {
  const _CarePlanCard({
    required this.species,
    required this.exposure,
    required this.lastWateredAt,
    required this.time,
  });

  final PlantSpecies species;
  final LightLevel exposure;
  final DateTime? lastWateredAt;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final interval = species.wateringIntervalFor(exposure);
    final adjusted = interval != species.wateringIntervalDays;

    final last = lastWateredAt;
    String next;
    if (last == null) {
      next = 'Informe a última rega para eu calcular o próximo lembrete.';
    } else {
      final due = DateTime(last.year, last.month, last.day + interval, time.hour, time.minute);
      final today = DateTime.now();
      final days = DateTime(due.year, due.month, due.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      final when = switch (days) {
        < 0 => 'atrasada (era ${_formatDate(due)})',
        0 => 'hoje',
        1 => 'amanhã',
        _ => 'em $days dias (${_formatDate(due)})',
      };
      next = 'Próxima rega: $when às ${_formatTime(time)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plano de cuidados · ${species.name}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            '💧 Regar a cada $interval dias'
            '${adjusted ? ' (ajustado pela luz; padrão ${species.wateringIntervalDays})' : ''}',
          ),
          const SizedBox(height: 4),
          Text('🧪 Adubar a cada ${species.fertilizingIntervalDays} dias'),
          const SizedBox(height: 4),
          Text('🔔 $next'),
        ],
      ),
    );
  }
}
