import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../xmpp/controller/xmpp_controller.dart';

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

  bool badCertsDev = true;

  @override
  void initState() {
    super.initState();
    final xmpp = context.read<XmppController>();
    host.text = xmpp.host;
    domain.text = xmpp.domain;
    user.text = xmpp.username;
    pass.text = xmpp.password;
    badCertsDev = xmpp.allowBadCertificatesInDev;
  }

  @override
  void dispose() {
    host.dispose();
    domain.dispose();
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  Color _mutedAccent(ColorScheme cs) {
    return Color.lerp(cs.primary, cs.onSurface, 0.45)!;
  }

  @override
  Widget build(BuildContext context) {
    final xmpp = context.watch<XmppController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _mutedAccent(cs);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Color.lerp(Colors.black, cs.surface, 0.22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        flexibleSpace: _FrostedBar(
          tint: cs.surface.withOpacity(0.52),
          border: cs.onSurface.withOpacity(0.08),
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
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12 + 64, 14, 18),
          children: [
            const _SectionTitle('XMPP'),
            const SizedBox(height: 10),
            _GlassCard(
              child: Column(
                children: [
                  _Field(
                      label: 'Хост',
                      controller: host,
                      prefixIcon: Icons.dns_rounded),
                  const SizedBox(height: 10),
                  _Field(
                      label: 'Домен',
                      controller: domain,
                      prefixIcon: Icons.public_rounded),
                  const SizedBox(height: 10),
                  _Field(
                      label: 'Логин',
                      controller: user,
                      prefixIcon: Icons.person_rounded),
                  const SizedBox(height: 10),
                  _Field(
                      label: 'Пароль',
                      controller: pass,
                      obscure: true,
                      prefixIcon: Icons.lock_rounded),
                  const SizedBox(height: 10),
                  _GlassSwitchTile(
                    value: badCertsDev,
                    onChanged: (v) => setState(() => badCertsDev = v),
                    title: 'Разрешить “плохие” сертификаты (только DEV)',
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
                            await xmpp.saveConfig(
                              host: host.text,
                              domain: domain.text,
                              username: user.text,
                              password: pass.text,
                            );
                            xmpp.allowBadCertificatesInDev = badCertsDev;

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
                            await xmpp.saveConfig(
                              host: host.text,
                              domain: domain.text,
                              username: user.text,
                              password: pass.text,
                            );
                            xmpp.allowBadCertificatesInDev = badCertsDev;

                            await xmpp.connect();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(xmpp.hint)),
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
                      await xmpp.disconnect();
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

/* ===== glass ===== */

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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(bottom: BorderSide(color: border)),
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.92),
            accent.withOpacity(0.25),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.28),
          ),
        ],
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 26,
                spreadRadius: -10,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: cs.onSurface.withOpacity(0.60),
          letterSpacing: 0.8,
          fontSize: 12,
        ),
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.30),
          border: Border.all(color: cs.onSurface.withOpacity(0.10)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
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

    final Color bg =
        filled ? cs.surface.withOpacity(0.62) : cs.surface.withOpacity(0.30);
    final Color border = danger
        ? Colors.redAccent.withOpacity(0.35)
        : cs.onSurface.withOpacity(0.10);

    final List<Color> grad = filled
        ? [accent.withOpacity(0.80), accent.withOpacity(0.20)]
        : [cs.onSurface.withOpacity(0.06), cs.onSurface.withOpacity(0.02)];

    final Color fg =
        danger ? Colors.redAccent.shade100 : cs.onSurface.withOpacity(0.90);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: grad,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  spreadRadius: -12,
                  offset: const Offset(0, 16),
                  color: Colors.black.withOpacity(0.30),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
