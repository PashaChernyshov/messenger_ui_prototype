import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:app_design/app/state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final host = TextEditingController();
  final domain = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();
  final micRecorder = AudioRecorder();

  bool badCertsDev = true;
  List<InputDevice> micDevices = const [];
  InputDevice? selectedMicDevice;
  StreamSubscription<Amplitude>? micAmplitudeSub;
  bool micTesting = false;
  double micLevel = 0;
  String micStatus = 'Выберите микрофон и запустите тест.';

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    host.text = app.xmpp.host;
    domain.text = app.xmpp.domain;
    user.text = app.xmpp.username;
    pass.text = app.xmpp.password;
    badCertsDev = app.xmpp.allowBadCertificatesInDev;
    _loadMicrophones();
  }

  @override
  void dispose() {
    host.dispose();
    domain.dispose();
    user.dispose();
    pass.dispose();
    micAmplitudeSub?.cancel();
    micRecorder.dispose();
    super.dispose();
  }

  Color _mutedAccent(ColorScheme cs) {
    // приглушаем primary (чтобы не "фиолетило" и не уходило в бирюзу)
    return Color.lerp(cs.primary, cs.onSurface, 0.45)!;
  }

  Future<void> _loadMicrophones() async {
    try {
      final devices = await micRecorder.listInputDevices();
      if (!mounted) return;
      final selectedId = context.read<AppState>().selectedMicrophoneId;
      final selected = devices.where((device) => device.id == selectedId);
      setState(() {
        micDevices = devices;
        selectedMicDevice = selected.isNotEmpty
            ? selected.first
            : devices.isEmpty
                ? null
                : devices.first;
        micStatus = devices.isEmpty
            ? 'Микрофоны не найдены.'
            : 'Найдено устройств: ${devices.length}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => micStatus = 'Не удалось получить микрофоны: $e');
    }
  }

  Future<void> _toggleMicrophoneTest() async {
    if (micTesting) {
      await micAmplitudeSub?.cancel();
      micAmplitudeSub = null;
      await micRecorder.stop();
      if (!mounted) return;
      setState(() {
        micTesting = false;
        micLevel = 0;
        micStatus = 'Тест остановлен.';
      });
      return;
    }

    try {
      final hasPermission = await micRecorder.hasPermission();
      if (!hasPermission) {
        setState(() => micStatus = 'Нет доступа к микрофону.');
        return;
      }
      await micRecorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
          device: selectedMicDevice,
          autoGain: true,
        ),
      );
      await micAmplitudeSub?.cancel();
      micAmplitudeSub = micRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amplitude) {
        if (!mounted) return;
        final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
        setState(() {
          micLevel = normalized;
          micStatus = normalized > 0.08
              ? 'Сигнал микрофона есть.'
              : 'Говорите в микрофон для проверки уровня.';
        });
      });
      if (!mounted) return;
      setState(() {
        micTesting = true;
        micStatus = 'Тест микрофона запущен.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => micStatus = 'Не удалось запустить тест: $e');
    }
  }

  Widget _buildMicrophoneSection(Color accent) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Устройство ввода',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<InputDevice>(
          value: selectedMicDevice,
          isExpanded: true,
          dropdownColor: cs.surfaceContainerHighest,
          iconEnabledColor: cs.onSurface.withOpacity(0.70),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.mic_rounded),
            labelText: 'Микрофон',
          ),
          items: micDevices
              .map(
                (device) => DropdownMenuItem(
                  value: device,
                  child: Text(
                    device.label.isEmpty ? device.id : device.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: micTesting
              ? null
              : (device) {
                  setState(() => selectedMicDevice = device);
                  context
                      .read<AppState>()
                      .updateSelectedMicrophoneId(device?.id);
                },
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: micLevel,
            minHeight: 8,
            backgroundColor: cs.onSurface.withOpacity(0.10),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          micStatus,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.68),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassButton(
                kind: _GlassButtonKind.outline,
                icon: Icons.refresh_rounded,
                label: 'Обновить',
                onTap: micTesting ? () {} : _loadMicrophones,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassButton(
                kind: _GlassButtonKind.filled,
                icon: micTesting ? Icons.stop_rounded : Icons.graphic_eq,
                label: micTesting ? 'Остановить' : 'Тест',
                onTap: _toggleMicrophoneTest,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _mutedAccent(cs);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cs.surface,
        toolbarHeight: 64,
        flexibleSpace: _FrostedBar(
          tint: cs.surface,
          border: Colors.transparent,
        ),
        titleSpacing: 14,
        title: Row(
          children: [
            _AppMark(icon: Icons.tune_rounded, accent: accent),
            const SizedBox(width: 10),
            Text(
              'Настройки',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
          children: [
            _SettingsSection(
              icon: Icons.text_fields_rounded,
              title: 'Интерфейс',
              subtitle: 'Общий размер текста и плотность элементов.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Размер текста',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GlassSlider(
                    value: app.fontSize,
                    min: 11,
                    max: 18,
                    divisions: 14,
                    label: app.fontSize.toStringAsFixed(0),
                    accent: accent,
                    onChanged: (v) => app.setFontSize(v),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Текущее: ${app.fontSize.toStringAsFixed(0)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              icon: Icons.forum_rounded,
              title: 'Сообщения',
              subtitle: 'Вид пузырей, технические подписи и читаемость чата.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Размер текста сообщений',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GlassSlider(
                    value: app.messageDisplay.messageFontSize,
                    min: 12,
                    max: 20,
                    divisions: 8,
                    label:
                        app.messageDisplay.messageFontSize.toStringAsFixed(0),
                    accent: accent,
                    onChanged: (value) => app.updateMessageDisplay(
                      app.messageDisplay.copyWith(messageFontSize: value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedShell(
                    accent: accent,
                    child: SegmentedButton<ChatDensity>(
                      segments: const [
                        ButtonSegment(
                          value: ChatDensity.compact,
                          label: Text('Плотно'),
                        ),
                        ButtonSegment(
                          value: ChatDensity.normal,
                          label: Text('Обычно'),
                        ),
                        ButtonSegment(
                          value: ChatDensity.comfortable,
                          label: Text('Свободно'),
                        ),
                      ],
                      selected: {app.messageDisplay.density},
                      onSelectionChanged: (value) => app.updateMessageDisplay(
                        app.messageDisplay.copyWith(density: value.first),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GlassSwitchTile(
                    value: app.messageDisplay.showMessageTime,
                    onChanged: (value) => app.updateMessageDisplay(
                      app.messageDisplay.copyWith(showMessageTime: value),
                    ),
                    title: 'Показывать время сообщений',
                    subtitle:
                        'Отображает время и локальный статус под пузырями.',
                    accent: accent,
                  ),
                  const SizedBox(height: 10),
                  _GlassSwitchTile(
                    value: app.messageDisplay.showTechnicalIds,
                    onChanged: (value) => app.updateMessageDisplay(
                      app.messageDisplay.copyWith(showTechnicalIds: value),
                    ),
                    title: 'Показывать JID',
                    subtitle:
                        'Показывает технические адреса в шапках и списках.',
                    accent: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              icon: Icons.mic_rounded,
              title: 'Микрофон',
              subtitle: 'Выбор устройства и проверка входного сигнала.',
              child: _buildMicrophoneSection(accent),
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              icon: Icons.hub_rounded,
              title: 'XMPP',
              subtitle: 'Подключение к серверу, учетная запись и сертификаты.',
              child: Column(
                children: [
                  _ConnectionStatusCard(
                    status: app.connection,
                    hint: app.connectionHint,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Хост',
                    controller: host,
                    prefixIcon: Icons.dns_rounded,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Домен',
                    controller: domain,
                    prefixIcon: Icons.public_rounded,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Логин',
                    controller: user,
                    prefixIcon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Пароль',
                    controller: pass,
                    obscure: true,
                    prefixIcon: Icons.lock_rounded,
                  ),
                  const SizedBox(height: 10),
                  _GlassSwitchTile(
                    value: badCertsDev,
                    onChanged: (v) => setState(() => badCertsDev = v),
                    title: 'Разрешить плохие сертификаты',
                    subtitle: 'Включай только для локалки/самоподписанного.',
                    accent: accent,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassButton(
                          kind: _GlassButtonKind.outline,
                          icon: Icons.save_rounded,
                          label: 'Сохранить',
                          onTap: () async {
                            await app.xmpp.saveConfig(
                              host: host.text,
                              domain: domain.text,
                              username: user.text,
                              password: pass.text,
                            );
                            app.xmpp.allowBadCertificatesInDev = badCertsDev;

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Сохранено')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassButton(
                          kind: _GlassButtonKind.filled,
                          icon: Icons.link_rounded,
                          label: 'Подключиться',
                          onTap: () async {
                            await app.xmpp.saveConfig(
                              host: host.text,
                              domain: domain.text,
                              username: user.text,
                              password: pass.text,
                            );
                            app.xmpp.allowBadCertificatesInDev = badCertsDev;

                            await app.connect();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(app.connectionHint)),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _GlassButton(
                    kind: _GlassButtonKind.outlineDanger,
                    icon: Icons.logout_rounded,
                    label: 'Отключиться',
                    onTap: () async {
                      await app.disconnect();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Отключено')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== UI BLOCKS (glass) ===================== */

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.56),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.onSurface.withOpacity(0.07)),
                ),
                child: Icon(
                  icon,
                  color: cs.onSurface.withOpacity(0.82),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.58),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
class _SegmentedShell extends StatelessWidget {
  final Widget child;
  final Color accent;

  const _SegmentedShell({
    required this.child,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accent.withOpacity(0.18);
              }
              return cs.surfaceContainerHighest.withOpacity(0.34);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return cs.onSurface.withOpacity(0.95);
              }
              return cs.onSurface.withOpacity(0.66);
            }),
            side: WidgetStatePropertyAll(
              BorderSide(color: cs.onSurface.withOpacity(0.07)),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w800),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
class _ConnectionStatusCard extends StatelessWidget {
  final ConnectionStatus status;
  final String hint;

  const _ConnectionStatusCard({
    required this.status,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = switch (status) {
      ConnectionStatus.connected => const Color(0xFF6F9A79),
      ConnectionStatus.connecting => const Color(0xFFC39A54),
      ConnectionStatus.error => const Color(0xFFC76666),
      ConnectionStatus.disconnected => cs.onSurface.withOpacity(0.52),
    };
    final label = switch (status) {
      ConnectionStatus.connected => 'Подключено',
      ConnectionStatus.connecting => 'Подключение',
      ConnectionStatus.error => 'Ошибка',
      ConnectionStatus.disconnected => 'Отключено',
    };
    final text = hint.trim().isEmpty ? label : hint.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.onSurface.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withOpacity(0.92),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.58),
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _FrostedBar extends StatelessWidget {
  final Color tint;
  final Color border;

  const _FrostedBar({
    required this.tint,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: tint,
          border: Border(
            bottom: BorderSide(color: border),
          ),
        ),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _AppMark({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: accent.withOpacity(0.18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.28),
          ),
        ],
        border: Border.all(color: Colors.transparent),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Color.lerp(Colors.black, cs.surface, 0.68),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.onSurface.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: -16,
              offset: const Offset(0, 14),
              color: Colors.black.withOpacity(0.40),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final IconData? prefixIcon;

  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.92),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: cs.onSurface.withOpacity(0.60)),
        filled: true,
        fillColor: cs.surface.withOpacity(0.35),
        labelStyle: TextStyle(
          color: cs.onSurface.withOpacity(0.58),
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.18)),
        ),
      ),
    );
  }
}

class _GlassSwitchTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final Color accent;

  const _GlassSwitchTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.36),
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.62),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          activeColor: Colors.white,
          activeTrackColor: accent.withOpacity(0.55),
          inactiveTrackColor: cs.onSurface.withOpacity(0.18),
          inactiveThumbColor: cs.onSurface.withOpacity(0.60),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
      ),
    );
  }
}

enum _GlassButtonKind { filled, outline, outlineDanger }

class _GlassButton extends StatelessWidget {
  final _GlassButtonKind kind;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.kind,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  Color _mutedAccent(ColorScheme cs) {
    return Color.lerp(cs.primary, cs.onSurface, 0.45)!;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _mutedAccent(cs);

    final bool filled = kind == _GlassButtonKind.filled;
    final bool danger = kind == _GlassButtonKind.outlineDanger;

    final Color bg = filled
        ? accent.withOpacity(0.16)
        : cs.surfaceContainerHighest.withOpacity(0.30);
    final Color border =
        danger ? Colors.redAccent.withOpacity(0.35) : Colors.transparent;

    final List<Color> grad = filled ? [bg, bg] : [bg, bg];

    final Color fg =
        danger ? Colors.redAccent.shade100 : cs.onSurface.withOpacity(0.90);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: grad,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                spreadRadius: -12,
                offset: const Offset(0, 16),
                color: Colors.black.withOpacity(0.30),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double> onChanged;
  final Color accent;

  const _GlassSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.accent,
    this.divisions,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        sliderTheme: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: accent.withOpacity(0.60),
          inactiveTrackColor: cs.onSurface.withOpacity(0.14),
          thumbColor: Colors.white,
          overlayColor: accent.withOpacity(0.12),
          valueIndicatorColor: cs.surface.withOpacity(0.85),
          valueIndicatorTextStyle: TextStyle(
            color: cs.onSurface.withOpacity(0.92),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }
}
