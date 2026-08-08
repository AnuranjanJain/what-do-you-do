import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_controller.dart';
import 'motion.dart';
import 'models.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  static const destinations = <_Destination>[
    _Destination('Dashboard', Icons.dashboard_outlined),
    _Destination('Planner', Icons.auto_awesome_outlined),
    _Destination('Timeline', Icons.monitor_heart_outlined),
    _Destination('Applications', Icons.work_outline),
    _Destination('Hackathons', Icons.emoji_events_outlined),
    _Destination('College Work', Icons.school_outlined),
    _Destination('Privacy', Icons.shield_outlined),
    _Destination('AI Agent', Icons.smart_toy_outlined),
    _Destination('Widgets', Icons.widgets_outlined),
    _Destination('Settings', Icons.tune_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final controller = widget.controller;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ColoredBox(
        color: colorScheme.surface,
        child: Column(
          children: [
            _TopBar(
              darkMode: controller.darkMode,
              online: controller.collectorOnline,
              onToggleTheme: controller.toggleTheme,
            ),
            Expanded(
              child: Row(
                children: [
                  if (wide)
                    _DesktopNavigation(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onSelected: (index) =>
                          setState(() => selectedIndex = index),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(wide ? 24 : 0),
                      ),
                      child: PageMotion(
                        motionKey: selectedIndex,
                        child: _PageBody(
                          index: selectedIndex,
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: math.min(selectedIndex, 4),
              onDestinationSelected: (index) {
                if (index == 4) {
                  _showMoreMenu(context);
                } else {
                  setState(() => selectedIndex = index);
                }
              },
              destinations: [
                ...destinations
                    .take(4)
                    .map(
                      (item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                    ),
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
            ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 4; index < destinations.length; index++)
              ListTile(
                leading: Icon(destinations[index].icon),
                title: Text(destinations[index].label),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedIndex = index);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.darkMode,
    required this.online,
    required this.onToggleTheme,
  });

  final bool darkMode;
  final bool online;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset('assets/app_icon.png', width: 34, height: 34),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What Do You Do',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Text(
                'Private activity OS',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          _StatusDot(online: online),
          const SizedBox(width: 8),
          IconButton(
            tooltip: darkMode ? 'Use light theme' : 'Use dark theme',
            onPressed: onToggleTheme,
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: online ? 'Collector online' : 'Collector offline',
      child: PulsingStatusDot(
        color: online ? const Color(0xFF42A86B) : const Color(0xFFE66B6B),
      ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF0EFE8)
            : Colors.white.withValues(alpha: 0.025),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < destinations.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: _NavButton(
                destination: destinations[index],
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
          const Spacer(),
          const _LocalBadge(),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        color: selected
            ? (dark ? AppColors.yellow : AppColors.ink)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: ValueKey('nav-${destination.label}'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  destination.icon,
                  size: 18,
                  color: selected
                      ? (dark ? AppColors.ink : Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected
                        ? (dark ? AppColors.ink : Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Local only\nNo cloud server',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.index, required this.controller});

  final int index;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => DashboardPage(controller: controller),
      1 => IntelligencePage(controller: controller),
      2 => TimelinePage(controller: controller),
      3 => ApplicationsPage(controller: controller),
      4 => HackathonsPage(controller: controller),
      5 => CollegeWorkPage(controller: controller),
      6 => PrivacyPage(controller: controller),
      7 => AgentPage(controller: controller),
      8 => WidgetsPage(controller: controller),
      _ => SettingsPage(controller: controller),
    };
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    final sessions = controller.sessions;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _DashboardHero(controller: controller),
          const SizedBox(height: 14),
          _DateStrip(controller: controller),
          const SizedBox(height: 14),
          _IntelligenceStrip(intelligence: controller.agent.intelligence),
          if (!controller.agent.connected ||
              controller.agent.stale ||
              (controller.agent.readiness.hasItems &&
                  !controller.agent.readiness.allReady)) ...[
            const SizedBox(height: 14),
            _DashboardSetupPanel(controller: controller),
          ],
          const SizedBox(height: 14),
          _EmailIntelligenceOverview(portfolio: controller.agent.applications),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1050
                  ? 4
                  : constraints.maxWidth > 580
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: columns == 1 ? 2.2 : 2.15,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    label: 'Tracked time',
                    value: formatMinutes(summary.totalMinutes),
                    detail: '${sessions.length} sessions',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFFFF0B2),
                  ),
                  _MetricCard(
                    label: 'Focused work',
                    value: formatMinutes(summary.focusMinutes),
                    detail: 'coding + research',
                    icon: Icons.bolt,
                    color: AppColors.mint,
                  ),
                  _MetricCard(
                    label: 'Idle / AFK',
                    value: formatMinutes(summary.idleMinutes),
                    detail: 'detected locally',
                    icon: Icons.pause_circle_outline,
                    color: const Color(0xFFFFF0B2),
                  ),
                  _MetricCard(
                    label: 'Data quality',
                    value: '${summary.averageConfidence}%',
                    detail: 'average confidence',
                    icon: Icons.verified_user_outlined,
                    color: AppColors.ice,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth > 820;
              final focusPanel = _Panel(
                eyebrow: 'Focus graph',
                title: 'Energy across the day',
                child: SizedBox(
                  height: 250,
                  child: _FocusChart(sessions: sessions),
                ),
              );
              final activityMix = _ActivityMix(summary: summary);
              final children = [
                Expanded(flex: 3, child: focusPanel),
                const SizedBox(width: 12, height: 12),
                Expanded(flex: 2, child: activityMix),
              ];
              if (horizontal) return Row(children: children);
              return Column(
                children: [
                  SizedBox(width: double.infinity, child: focusPanel),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: activityMix),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          _Panel(
            eyebrow: 'Activity timeline',
            title: 'Detected context',
            trailing: Text('${math.min(sessions.length, 15)} shown'),
            child: sessions.isEmpty
                ? _EmptyState(message: controller.message)
                : Column(
                    children: sessions
                        .take(15)
                        .map((session) => _TimelineTile(session: session))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSetupPanel extends StatelessWidget {
  const _DashboardSetupPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final agent = controller.agent;
    final readiness = agent.readiness;
    final pending = readiness.items.where((item) => !item.ok).take(3).toList();
    final title = !agent.connected
        ? 'Connect AiOS to unlock planning'
        : agent.stale
        ? 'AiOS is reconnecting'
        : '${readiness.ready}/${readiness.total} systems ready';

    return _Panel(
      eyebrow: 'Quick setup',
      title: title,
      trailing: agent.connected
          ? Chip(
              avatar: Icon(
                agent.stale ? Icons.sync_problem_rounded : Icons.tune_rounded,
                size: 15,
              ),
              label: Text(agent.stale ? 'Saved locally' : 'Setup needed'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            !agent.connected
                ? 'Local activity tracking works on its own. Open AiOS once to connect Gmail, planner rows, project context, and local AI status.'
                : agent.stale
                ? agent.message
                : 'Finish the items below to make daily planning and email intelligence useful in real life.',
            style: const TextStyle(color: Colors.grey, height: 1.35),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in pending)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.radio_button_unchecked, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.label}: ${item.action}',
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: controller.openAiOS,
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: Text(
                  agent.connected ? 'Open AiOS settings' : 'Open AiOS',
                ),
              ),
              if (agent.connected)
                OutlinedButton.icon(
                  onPressed: controller.syncIntelligence,
                  icon: const Icon(Icons.sync_rounded, size: 17),
                  label: const Text('Sync now'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmailIntelligenceOverview extends StatelessWidget {
  const _EmailIntelligenceOverview({required this.portfolio});

  final ApplicationPortfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final stats = portfolio.stats;
    final hackathons = portfolio.hackathons.stats;
    final cards = [
      (
        'Applied',
        '${stats.applied}',
        'personal applications',
        Icons.work_outline,
        AppColors.yellow.withValues(alpha: 0.5),
      ),
      (
        'Selected',
        '${stats.selected}',
        '${stats.selectedRate}% reached a further round',
        Icons.trending_up_rounded,
        AppColors.mint,
      ),
      (
        'No response',
        '${stats.noResponse}',
        'waiting at least 7 days',
        Icons.hourglass_empty_rounded,
        AppColors.peach,
      ),
      (
        'No further email',
        '${stats.noFurtherEmail}',
        'only one related message',
        Icons.mark_email_unread_outlined,
        AppColors.ice,
      ),
      (
        'Hackathons',
        '${hackathons.total}',
        '${hackathons.applied} applied or building',
        Icons.emoji_events_outlined,
        const Color(0xFFD9D3FF),
      ),
      (
        'Hackathon selections',
        '${hackathons.selected}',
        '${hackathons.submitted} submitted, ${hackathons.dueSoon} due soon',
        Icons.workspace_premium_outlined,
        const Color(0xFFD9F1E4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMAIL INTELLIGENCE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What happened after applying',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Text(
              '${stats.emailsScanned}/${stats.scanLimit} combined mails',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1080
                ? 6
                : constraints.maxWidth >= 700
                ? 3
                : 2;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 6 ? 1.3 : 1.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final card in cards)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card.$5,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.$1,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Icon(card.$4, size: 18),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          card.$2,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          card.$3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final session = controller.sessions.isEmpty
        ? null
        : controller.sessions.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 720;
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.collectorOnline
                  ? 'LIVE LOCAL DATA'
                  : 'COLLECTOR OFFLINE',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Welcome back.',
              style: TextStyle(
                fontSize: horizontal ? 48 : 36,
                height: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.message,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        );
        final current = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                AppColors.yellow.withValues(alpha: 0.22),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRENT SESSION',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                session == null
                    ? 'No active session'
                    : '${labelFor(session.category)}: ${session.subcategory}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                session == null
                    ? 'Start the collector to begin tracking.'
                    : '${session.appName} · ${formatMinutes(session.durationMinutes)} · ${session.confidence}% confidence',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (session?.confidence ?? 0) / 100,
                minHeight: 7,
                borderRadius: BorderRadius.circular(10),
                color: AppColors.yellow,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
              ),
            ],
          ),
        );
        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 3, child: intro),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: current),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [intro, const SizedBox(height: 18), current],
        );
      },
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final selected =
        DateTime.tryParse(controller.selectedDate) ?? DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                DateFormat('EEE, MMM d, yyyy').format(selected),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _DateButton(
              label: 'Today',
              onPressed: () => controller.selectDate(DateTime.now()),
              highlighted: _sameDay(selected, DateTime.now()),
            ),
            _DateButton(
              label: 'Yesterday',
              onPressed: () => controller.selectDate(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
              highlighted: _sameDay(
                selected,
                DateTime.now().subtract(const Duration(days: 1)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                  initialDate: selected.isAfter(DateTime.now())
                      ? DateTime.now()
                      : selected,
                );
                if (picked != null) await controller.selectDate(picked);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 15),
              label: const Text('Choose date'),
            ),
            IconButton(
              tooltip: 'Refresh data',
              onPressed: controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.onPressed,
    required this.highlighted,
  });
  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return highlighted
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
            ),
            child: Text(label),
          )
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HoverLift(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.05) : color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
              child: Icon(icon, size: 17),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(value, style: const TextStyle(fontSize: 26)),
            Text(
              detail,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FocusChart extends StatelessWidget {
  const _FocusChart({required this.sessions});
  final List<ActivitySession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _EmptyState(message: 'No focus data for this date.');
    }
    final items = sessions.take(12).toList().reversed.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(enabled: true),
        barGroups: [
          for (var index = 0; index < items.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: items[index].category == ActivityCategory.idle
                      ? 22
                      : items[index].confidence.toDouble(),
                  width: 22,
                  borderRadius: BorderRadius.circular(12),
                  color: categoryColor(items[index].category),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityMix extends StatelessWidget {
  const _ActivityMix({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final totals = summary.categoryTotals
        .where((item) => item.minutes > 0)
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2C27) : AppColors.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVITY MIX',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Where time went',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 145,
            child: totals.isEmpty
                ? const Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 38,
                      sectionsSpace: 2,
                      sections: totals
                          .map(
                            (item) => PieChartSectionData(
                              value: item.minutes.toDouble(),
                              color: categoryColor(item.category),
                              radius: 28,
                              showTitle: false,
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          for (final item in totals)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: categoryColor(item.category),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labelFor(item.category),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatMinutes(item.minutes),
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _IntelligenceStrip extends StatelessWidget {
  const _IntelligenceStrip({required this.intelligence});
  final IntelligenceSnapshot intelligence;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 560
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 1 ? 2.05 : 1.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              label: 'Today\'s focus',
              value: intelligence.planningToday.isEmpty
                  ? 'No plan'
                  : '${intelligence.planningToday.length}',
              detail: intelligence.todaySummary.isEmpty
                  ? 'Generated by AiOS'
                  : intelligence.todaySummary,
              icon: Icons.auto_awesome_outlined,
              color: AppColors.yellow.withValues(alpha: 0.42),
            ),
            _MetricCard(
              label: 'Urgent emails',
              value: '${intelligence.urgentEmails}',
              detail: '${intelligence.unreadEmails} unread emails',
              icon: Icons.mark_email_unread_outlined,
              color: AppColors.ice,
            ),
            _MetricCard(
              label: 'Upcoming deadlines',
              value: '${intelligence.deadlines.length}',
              detail: 'Local email understanding',
              icon: Icons.event_available_outlined,
              color: AppColors.mint,
            ),
            _MetricCard(
              label: 'Answer next',
              value: '${intelligence.questionQueue.length}',
              detail:
                  '${intelligence.planningEvents.length} rows, ${intelligence.planningWeek.length} this week',
              icon: Icons.view_timeline_outlined,
              color: const Color(0xFFFFF0B2),
            ),
          ],
        );
      },
    );
  }
}

class IntelligencePage extends StatelessWidget {
  const IntelligencePage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final intelligence = controller.agent.intelligence;
    return _StandardPage(
      eyebrow: 'AiOS intelligence',
      title: 'Life command planner',
      subtitle:
          'Gmail, hackathons, repos, goals, videos, deadlines, and plans are processed locally by AiOS and shown here through loopback.',
      action: IconButton(
        tooltip: 'Sync Gmail and planner',
        onPressed: controller.syncIntelligence,
        icon: const Icon(Icons.sync),
      ),
      child: Column(
        children: [
          _AgentConnectionBanner(
            agent: controller.agent,
            onOpen: controller.openAiOS,
          ),
          const SizedBox(height: 12),
          _ProjectContextPanel(context: controller.agent.projects),
          const SizedBox(height: 12),
          _ReadinessPanel(readiness: controller.agent.readiness),
          const SizedBox(height: 12),
          _QuickAddPlanningEventPanel(onCreate: controller.createPlanningEvent),
          const SizedBox(height: 12),
          _BriefingPanel(briefing: intelligence.briefing),
          const SizedBox(height: 12),
          _QuestionQueuePanel(
            questions: intelligence.questionQueue,
            onAnswer: controller.answerPlanningQuestion,
          ),
          const SizedBox(height: 12),
          _PlanBlocksPanel(intelligence: intelligence),
          const SizedBox(height: 12),
          _PlanningEventsPanel(intelligence: intelligence),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth > 820;
              final today = _Panel(
                eyebrow: 'Today\'s focus',
                title: intelligence.todaySummary.isEmpty
                    ? 'No generated plan yet'
                    : intelligence.todaySummary,
                child: _TextList(
                  items: intelligence.todayItems,
                  empty:
                      'Connect Gmail in AiOS Settings, then run the Email Intelligence worker.',
                ),
              );
              final weekly = _Panel(
                eyebrow: 'Weekly planner',
                title: intelligence.weeklySummary.isEmpty
                    ? 'Waiting for weekly plan'
                    : intelligence.weeklySummary,
                child: _TextList(
                  items: intelligence.weeklyItems,
                  empty: 'AiOS will generate weekly focus days locally.',
                ),
              );
              if (!horizontal) {
                return Column(
                  children: [today, const SizedBox(height: 12), weekly],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: today),
                  const SizedBox(width: 12),
                  Expanded(child: weekly),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth > 820;
              final suggestions = _Panel(
                eyebrow: 'Smart suggestions',
                title: 'Follow-ups and repeated asks',
                child: _TextList(
                  items: intelligence.suggestions,
                  empty: 'No automatic suggestions yet.',
                ),
              );
              final deadlines = _Panel(
                eyebrow: 'Deadlines',
                title: 'Upcoming email commitments',
                child: _TextList(
                  items: intelligence.deadlines,
                  empty: 'No deadline signals found.',
                ),
              );
              final waiting = _Panel(
                eyebrow: 'Waiting for',
                title: 'People and projects',
                child: _TextList(
                  items: intelligence.waitingFor,
                  empty: 'No waiting-on signals found.',
                ),
              );
              if (!horizontal) {
                return Column(
                  children: [
                    suggestions,
                    const SizedBox(height: 12),
                    deadlines,
                    const SizedBox(height: 12),
                    waiting,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: suggestions),
                  const SizedBox(width: 12),
                  Expanded(child: deadlines),
                  const SizedBox(width: 12),
                  Expanded(child: waiting),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CollegeWorkPage extends StatelessWidget {
  const CollegeWorkPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final college = controller.agent.college;
    return _StandardPage(
      eyebrow: 'College work',
      title: college.headline,
      subtitle:
          'AiOS scans connected Gmail accounts locally for PAT classes, exams, assessments, changes, and preparation details.',
      action: IconButton(
        tooltip: 'Sync college mail',
        onPressed: controller.syncIntelligence,
        icon: const Icon(Icons.sync),
      ),
      child: Column(
        children: [
          _AgentConnectionBanner(
            agent: controller.agent,
            onOpen: controller.openAiOS,
          ),
          const SizedBox(height: 12),
          _Panel(
            eyebrow: college.hasClassToday
                ? 'Event today'
                : 'Today · ${college.date.isEmpty ? 'waiting for AiOS' : college.date}',
            title: college.headline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  college.latestSummary.isEmpty
                      ? 'Run Sync after connecting your college Gmail account in AiOS.'
                      : college.latestSummary,
                  style: const TextStyle(color: Colors.grey, height: 1.45),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CollegeFact(
                      icon: Icons.schedule_outlined,
                      label: college.time.isEmpty
                          ? 'Time not stated'
                          : college.time,
                    ),
                    _CollegeFact(
                      icon: Icons.location_on_outlined,
                      label: college.location.isEmpty
                          ? 'Location not stated'
                          : college.location,
                    ),
                    _CollegeFact(
                      icon: college.hasClassToday
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      label: college.status.replaceAll('_', ' '),
                    ),
                    if (college.nextEventDays != null)
                      _CollegeFact(
                        icon: Icons.event_outlined,
                        label: college.nextEventDays == 0
                            ? 'College event today'
                            : '${college.nextEventDays} days to next college event',
                      ),
                    _CollegeFact(
                      icon: Icons.mail_outline,
                      label: 'Latest ${college.emailsScanned} mails scanned',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bring = _Panel(
                eyebrow: 'Prepare',
                title: 'What to bring',
                child: _TextList(
                  items: college.bring,
                  empty: 'No required items were found in recent college mail.',
                ),
              );
              final instructions = _Panel(
                eyebrow: 'Instructions',
                title: 'What you need to know',
                child: _TextList(
                  items: college.instructions,
                  empty: 'No special college instructions were detected.',
                ),
              );
              if (constraints.maxWidth < 780) {
                return Column(
                  children: [bring, const SizedBox(height: 12), instructions],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: bring),
                  const SizedBox(width: 12),
                  Expanded(child: instructions),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _Panel(
            eyebrow: 'Mail timeline',
            title: 'Recent college notices',
            child: college.updates.isEmpty
                ? const _EmptyState(
                    message:
                        'No college messages yet. Connect college Gmail in AiOS Settings and press Sync.',
                  )
                : Column(
                    children: [
                      for (final notice in college.updates.take(12))
                        _PatNoticeRow(notice: notice),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CollegeFact extends StatelessWidget {
  const _CollegeFact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PatNoticeRow extends StatelessWidget {
  const _PatNoticeRow({required this.notice});
  final PatNotice notice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notice.status == 'cancelled'
                ? Icons.event_busy_outlined
                : Icons.event_available_outlined,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.subject,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (notice.summary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notice.summary,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, height: 1.35),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  [
                    if (notice.eventDate.isNotEmpty) notice.eventDate,
                    if (notice.sender.isNotEmpty) notice.sender,
                  ].join(' · '),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectContextPanel extends StatelessWidget {
  const _ProjectContextPanel({required this.context});
  final ProjectContextSnapshot context;

  @override
  Widget build(BuildContext context) {
    final project = this.context.selected;
    if (project == null) {
      return const _Panel(
        eyebrow: 'Selected project',
        title: 'Choose a project in AiOS',
        child: _EmptyState(
          message:
              'Open AiOS Projects to bind a GitHub repository and local working directory.',
        ),
      );
    }
    final timeline = project.timeline
        .take(5)
        .map((event) => '${event.kind.replaceAll('_', ' ')} · ${event.title}')
        .toList();
    return _Panel(
      eyebrow: 'Selected project · ${project.status}',
      title: '${project.title} · ${project.progress}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: project.progress / 100),
          const SizedBox(height: 12),
          if (project.repository.isNotEmpty)
            SelectableText('Repository: ${project.repository}'),
          if (project.workingDirectory.isNotEmpty)
            SelectableText('Working directory: ${project.workingDirectory}'),
          const SizedBox(height: 10),
          Text(
            project.workDone.isEmpty
                ? 'Work done: waiting for GitHub activity.'
                : 'Work done: ${project.workDone}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            project.remainingWork.isEmpty
                ? 'Next: ${project.nextAction}'
                : 'Remaining: ${project.remainingWork}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TextList(items: timeline, empty: ''),
          ],
        ],
      ),
    );
  }
}

class _BriefingPanel extends StatelessWidget {
  const _BriefingPanel({required this.briefing});
  final PlannerBriefing briefing;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'Daily briefing',
      title: briefing.headline.isEmpty
          ? 'Waiting for planner signals'
          : briefing.headline,
      child: briefing.hasSignals
          ? LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth > 900;
                final children = [
                  _BriefingColumn(
                    label: 'Focus',
                    items: briefing.focus,
                    empty: 'No focused block yet.',
                  ),
                  _BriefingColumn(
                    label: 'Due soon',
                    items: briefing.dueSoon,
                    empty: 'No deadlines this week.',
                  ),
                  _BriefingColumn(
                    label: 'At risk',
                    items: briefing.atRisk,
                    empty: 'No urgent project or hiring risk.',
                  ),
                  _BriefingColumn(
                    label: 'Ask next',
                    items: briefing.askNext,
                    empty: 'No questions waiting.',
                  ),
                ];
                if (!horizontal) {
                  return Column(
                    children: [
                      for (final child in children) ...[
                        child,
                        if (child != children.last) const SizedBox(height: 10),
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final child in children) ...[
                      Expanded(child: child),
                      if (child != children.last) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            )
          : const _EmptyState(
              message:
                  'Connect sources or add planning rows to generate a local briefing.',
            ),
    );
  }
}

class _BriefingColumn extends StatelessWidget {
  const _BriefingColumn({
    required this.label,
    required this.items,
    required this.empty,
  });
  final String label;
  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            items.isEmpty ? empty : items.take(3).join('\n'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

enum _PlanRange { today, week, month }

class _PlanBlocksPanel extends StatefulWidget {
  const _PlanBlocksPanel({required this.intelligence});
  final IntelligenceSnapshot intelligence;

  @override
  State<_PlanBlocksPanel> createState() => _PlanBlocksPanelState();
}

class _PlanBlocksPanelState extends State<_PlanBlocksPanel> {
  _PlanRange _range = _PlanRange.today;

  @override
  Widget build(BuildContext context) {
    final intelligence = widget.intelligence;
    final blocks = switch (_range) {
      _PlanRange.today => intelligence.planToday,
      _PlanRange.week => intelligence.planWeek.take(16).toList(),
      _PlanRange.month => intelligence.planMonth.take(30).toList(),
    };
    final label = switch (_range) {
      _PlanRange.today => 'Today',
      _PlanRange.week => 'This week',
      _PlanRange.month => 'This month',
    };
    return _Panel(
      eyebrow: 'Agenda',
      title: blocks.isEmpty ? 'No planned blocks yet' : '$label plan blocks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanRangeSelector(
            selected: _range,
            todayCount: intelligence.planToday.length,
            weekCount: intelligence.planWeek.length,
            monthCount: intelligence.planMonth.length,
            onChanged: (range) => setState(() => _range = range),
          ),
          const SizedBox(height: 10),
          if (blocks.isEmpty)
            const _EmptyState(
              message:
                  'Schedule rows with planned start and minutes to build a real agenda.',
            )
          else
            Column(
              children: blocks
                  .map((block) => _PlanBlockTile(block: block))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PlanRangeSelector extends StatelessWidget {
  const _PlanRangeSelector({
    required this.selected,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    required this.onChanged,
  });
  final _PlanRange selected;
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final ValueChanged<_PlanRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PlanRangeChip(
          label: 'Today',
          count: todayCount,
          selected: selected == _PlanRange.today,
          onSelected: () => onChanged(_PlanRange.today),
        ),
        _PlanRangeChip(
          label: 'Week',
          count: weekCount,
          selected: selected == _PlanRange.week,
          onSelected: () => onChanged(_PlanRange.week),
        ),
        _PlanRangeChip(
          label: 'Month',
          count: monthCount,
          selected: selected == _PlanRange.month,
          onSelected: () => onChanged(_PlanRange.month),
        ),
      ],
    );
  }
}

class _PlanRangeChip extends StatelessWidget {
  const _PlanRangeChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label $count'),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.yellow,
      labelStyle: TextStyle(
        color: selected ? AppColors.ink : null,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PlanBlockTile extends StatelessWidget {
  const _PlanBlockTile({required this.block});
  final PlanningBlock block;

  @override
  Widget build(BuildContext context) {
    final start = _shortDate(block.start);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _eventColor(block.eventType),
            foregroundColor: AppColors.ink,
            child: Text(
              '${block.durationMinutes}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$start - ${block.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (block.project.isNotEmpty)
                  Text(
                    block.project,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                if (block.nextAction.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    block.nextAction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (block.reason.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Why now: ${block.reason}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (block.progress > 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: block.progress / 100),
                ],
                if (block.sourceSignals.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Signals: ${block.sourceSignals.map((value) => value.replaceAll('_', ' ')).join(', ')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Chip(label: Text(block.status)),
              if (block.daysLeft != null)
                Text(
                  block.daysLeft == 0
                      ? 'Due today'
                      : '${block.daysLeft} days left',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessPanel extends StatelessWidget {
  const _ReadinessPanel({required this.readiness});
  final ReadinessSnapshot readiness;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'Real-life readiness',
      title: readiness.hasItems
          ? '${readiness.ready}/${readiness.total} systems ready'
          : 'Waiting for AiOS setup state',
      trailing: readiness.hasItems
          ? Chip(
              label: Text(readiness.allReady ? 'Ready' : 'Setup'),
              backgroundColor: readiness.allReady
                  ? AppColors.mint
                  : AppColors.yellow.withValues(alpha: 0.5),
            )
          : null,
      child: readiness.hasItems
          ? LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 560
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  childAspectRatio: columns == 1 ? 2.55 : 2.05,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: readiness.items
                      .map((item) => _ReadinessTile(item: item))
                      .toList(),
                );
              },
            )
          : const Text(
              'Open AiOS once so WDYD can read Gmail, planner, Ollama, and GitHub setup status.',
            ),
    );
  }
}

class _ReadinessTile extends StatelessWidget {
  const _ReadinessTile({required this.item});
  static const _readyColor = Color(0xFF3C7A57);
  final ReadinessItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.ok
            ? AppColors.mint.withValues(alpha: 0.3)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.ok
              ? _readyColor.withValues(alpha: 0.28)
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 20,
            color: item.ok ? _readyColor : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (item.action.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.action,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddPlanningEventPanel extends StatefulWidget {
  const _QuickAddPlanningEventPanel({required this.onCreate});
  final Future<void> Function(PlanningEventDraft draft) onCreate;

  @override
  State<_QuickAddPlanningEventPanel> createState() =>
      _QuickAddPlanningEventPanelState();
}

class _QuickAddPlanningEventPanelState
    extends State<_QuickAddPlanningEventPanel> {
  final _title = TextEditingController();
  final _project = TextEditingController();
  final _idea = TextEditingController();
  final _workDone = TextEditingController();
  final _workLeft = TextEditingController();
  final _repoUrl = TextEditingController();
  String _eventType = 'goal';
  DateTime? _deadline;
  DateTime? _plannedStart;
  int _plannedMinutes = 45;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _project.dispose();
    _idea.dispose();
    _workDone.dispose();
    _workLeft.dispose();
    _repoUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'Quick add',
      title: 'Create a planner row',
      trailing: FilledButton.icon(
        onPressed: _saving || _title.text.trim().isEmpty ? null : _save,
        icon: _saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_task_outlined),
        label: Text(_saving ? 'Saving' : 'Add row'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          final titleField = _TextInput(
            controller: _title,
            label: 'Event title',
            icon: Icons.flag_outlined,
            onChanged: (_) => setState(() {}),
          );
          final typeMenu = _EventTypeMenu(
            value: _eventType,
            onChanged: (value) => setState(() => _eventType = value),
          );
          final projectField = _TextInput(
            controller: _project,
            label: 'Project or goal',
            icon: Icons.workspaces_outline,
          );
          final repoField = _TextInput(
            controller: _repoUrl,
            label: 'Repo URL',
            icon: Icons.code_outlined,
          );
          return Column(
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(flex: 2, child: titleField),
                    const SizedBox(width: 10),
                    Expanded(child: typeMenu),
                  ],
                )
              else ...[
                titleField,
                const SizedBox(height: 10),
                typeMenu,
              ],
              const SizedBox(height: 10),
              if (wide)
                Row(
                  children: [
                    Expanded(child: projectField),
                    const SizedBox(width: 10),
                    Expanded(child: repoField),
                  ],
                )
              else ...[
                projectField,
                const SizedBox(height: 10),
                repoField,
              ],
              const SizedBox(height: 10),
              _ScheduleRow(
                deadline: _deadline,
                plannedStart: _plannedStart,
                minutes: _plannedMinutes,
                onDeadline: (value) => setState(() => _deadline = value),
                onPlannedStart: (value) =>
                    setState(() => _plannedStart = value),
                onMinutes: (value) => setState(() => _plannedMinutes = value),
              ),
              const SizedBox(height: 10),
              _TextInput(
                controller: _idea,
                label: 'Idea and context',
                icon: Icons.lightbulb_outline,
                minLines: 2,
              ),
              const SizedBox(height: 10),
              _TextInput(
                controller: _workDone,
                label: 'Work done',
                icon: Icons.done_all_outlined,
                minLines: 2,
              ),
              const SizedBox(height: 10),
              _TextInput(
                controller: _workLeft,
                label: 'Work left / next action',
                icon: Icons.pending_actions_outlined,
                minLines: 2,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onCreate(
      PlanningEventDraft(
        eventType: _eventType,
        title: _title.text.trim(),
        project: _project.text.trim(),
        idea: _idea.text.trim(),
        deadline: _deadline?.toIso8601String() ?? '',
        plannedStart: _plannedStart?.toIso8601String() ?? '',
        plannedMinutes: _plannedMinutes,
        workDone: _workDone.text.trim(),
        workLeft: _workLeft.text.trim(),
        repoUrl: _repoUrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _title.clear();
      _project.clear();
      _idea.clear();
      _workDone.clear();
      _workLeft.clear();
      _repoUrl.clear();
      _deadline = null;
      _plannedStart = null;
      _plannedMinutes = 45;
    });
  }
}

class _EventTypeMenu extends StatelessWidget {
  const _EventTypeMenu({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Type',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'goal', child: Text('Goal')),
        DropdownMenuItem(value: 'hackathon', child: Text('Hackathon')),
        DropdownMenuItem(value: 'repo', child: Text('Repo')),
        DropdownMenuItem(value: 'learning_video', child: Text('Learning')),
        DropdownMenuItem(value: 'manual', child: Text('Manual')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.minLines = 1,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int minLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 1 : 4,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.deadline,
    required this.plannedStart,
    required this.minutes,
    required this.onDeadline,
    required this.onPlannedStart,
    required this.onMinutes,
  });
  final DateTime? deadline;
  final DateTime? plannedStart;
  final int minutes;
  final ValueChanged<DateTime?> onDeadline;
  final ValueChanged<DateTime?> onPlannedStart;
  final ValueChanged<int> onMinutes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 760;
        final deadlineButton = _DateTimeButton(
          label: 'Deadline',
          value: deadline,
          icon: Icons.event_outlined,
          onChanged: onDeadline,
        );
        final plannedButton = _DateTimeButton(
          label: 'Planned start',
          value: plannedStart,
          icon: Icons.schedule_outlined,
          onChanged: onPlannedStart,
        );
        final minutesStepper = _MinutesStepper(
          value: minutes,
          onChanged: onMinutes,
        );
        if (wide) {
          return Row(
            children: [
              Expanded(child: deadlineButton),
              const SizedBox(width: 10),
              Expanded(child: plannedButton),
              const SizedBox(width: 10),
              Expanded(child: minutesStepper),
            ],
          );
        }
        return Column(
          children: [
            deadlineButton,
            const SizedBox(height: 10),
            plannedButton,
            const SizedBox(height: 10),
            minutesStepper,
          ],
        );
      },
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final IconData icon;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _pick(context),
      icon: Icon(icon),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value == null ? label : '$label ${_formatDraftDate(value!)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? now),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

class _MinutesStepper extends StatelessWidget {
  const _MinutesStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$value min',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Less time',
            onPressed: value <= 15 ? null : () => onChanged(value - 15),
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'More time',
            onPressed: () => onChanged(value + 15),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _QuestionQueuePanel extends StatelessWidget {
  const _QuestionQueuePanel({required this.questions, required this.onAnswer});
  final List<PlanningQuestion> questions;
  final Future<void> Function(
    PlanningQuestion question,
    PlanningProgressUpdate update,
  )
  onAnswer;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'Answer next',
      title: questions.isEmpty
          ? 'No questions waiting'
          : '${questions.length} questions for your progress check-in',
      child: questions.isEmpty
          ? const _EmptyState(
              message:
                  'AiOS will ask about repo progress, videos completed, notes, blockers, and email follow-ups.',
            )
          : Column(
              children: questions
                  .take(5)
                  .map(
                    (question) =>
                        _QuestionTile(question: question, onAnswer: onAnswer),
                  )
                  .toList(),
            ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.onAnswer});
  final PlanningQuestion question;
  final Future<void> Function(
    PlanningQuestion question,
    PlanningProgressUpdate update,
  )
  onAnswer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _eventColor(question.eventType),
        foregroundColor: AppColors.ink,
        child: Icon(_eventIcon(question.eventType), size: 18),
      ),
      title: Text(
        question.question,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [
          question.title,
          if (question.project.isNotEmpty) question.project,
          if (question.deadline.isNotEmpty)
            'Due ${_shortDate(question.deadline)}',
          if (question.lastProgressNote.isNotEmpty)
            'Last: ${question.lastProgressNote}',
        ].join(' - '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Answer',
        onPressed: () => _showAnswerDialog(context, question, onAnswer),
        icon: const Icon(Icons.edit_note_outlined),
      ),
    );
  }
}

Future<void> _showAnswerDialog(
  BuildContext context,
  PlanningQuestion question,
  Future<void> Function(
    PlanningQuestion question,
    PlanningProgressUpdate update,
  )
  onAnswer,
) async {
  final noteController = TextEditingController();
  final doneController = TextEditingController();
  final leftController = TextEditingController();
  const allowedStatuses = {'planned', 'in_progress', 'blocked', 'done'};
  var status = allowedStatuses.contains(question.status)
      ? question.status
      : 'in_progress';
  final update = await showDialog<PlanningProgressUpdate>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(question.title),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.question),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'planned', child: Text('Planned')),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In progress'),
                    ),
                    DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                    DropdownMenuItem(value: 'done', child: Text('Done')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => status = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: doneController,
                  minLines: 2,
                  maxLines: 4,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Work done',
                    hintText: 'What did you finish since last check-in?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: leftController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Work left',
                    hintText: 'What remains, what is blocked, or what moved?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes to remember',
                    hintText:
                        'Video completed, repo context, decisions, links, or reminders...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              PlanningProgressUpdate(
                progressNote: noteController.text,
                workDone: doneController.text,
                workLeft: leftController.text,
                status: status,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  noteController.dispose();
  doneController.dispose();
  leftController.dispose();
  if (update == null || update.isEmpty) return;
  await onAnswer(question, update);
}

enum _EventRowFilter { all, today, week, month, questions }

class _PlanningEventsPanel extends StatefulWidget {
  const _PlanningEventsPanel({required this.intelligence});
  final IntelligenceSnapshot intelligence;

  @override
  State<_PlanningEventsPanel> createState() => _PlanningEventsPanelState();
}

class _PlanningEventsPanelState extends State<_PlanningEventsPanel> {
  _EventRowFilter _filter = _EventRowFilter.week;

  @override
  Widget build(BuildContext context) {
    final intelligence = widget.intelligence;
    final events = intelligence.planningEvents;
    final visible = _visiblePlanningEvents(intelligence, _filter);
    return _Panel(
      eyebrow: 'Event rows',
      title: events.isEmpty
          ? 'No event rows yet'
          : '${visible.length} showing - ${intelligence.planningToday.length} today - ${intelligence.planningWeek.length} this week - ${intelligence.planningMonth.length} this month',
      child: events.isEmpty
          ? const _EmptyState(
              message:
                  'AiOS will create rows from hackathons, email tasks, repos, learning videos, and goals.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EventRowFilterBar(
                  selected: _filter,
                  intelligence: intelligence,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 10),
                if (visible.isEmpty)
                  const _EmptyState(message: 'No rows match this view yet.')
                else
                  ...visible.map((event) => _PlanningEventTile(event: event)),
              ],
            ),
    );
  }
}

class _EventRowFilterBar extends StatelessWidget {
  const _EventRowFilterBar({
    required this.selected,
    required this.intelligence,
    required this.onChanged,
  });
  final _EventRowFilter selected;
  final IntelligenceSnapshot intelligence;
  final ValueChanged<_EventRowFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _EventFilterChip(
          label: 'All',
          count: intelligence.planningEvents.length,
          selected: selected == _EventRowFilter.all,
          onSelected: () => onChanged(_EventRowFilter.all),
        ),
        _EventFilterChip(
          label: 'Today',
          count: intelligence.planningToday.length,
          selected: selected == _EventRowFilter.today,
          onSelected: () => onChanged(_EventRowFilter.today),
        ),
        _EventFilterChip(
          label: 'Week',
          count: intelligence.planningWeek.length,
          selected: selected == _EventRowFilter.week,
          onSelected: () => onChanged(_EventRowFilter.week),
        ),
        _EventFilterChip(
          label: 'Month',
          count: intelligence.planningMonth.length,
          selected: selected == _EventRowFilter.month,
          onSelected: () => onChanged(_EventRowFilter.month),
        ),
        _EventFilterChip(
          label: 'Questions',
          count: intelligence.questionQueue.length,
          selected: selected == _EventRowFilter.questions,
          onSelected: () => onChanged(_EventRowFilter.questions),
        ),
      ],
    );
  }
}

class _EventFilterChip extends StatelessWidget {
  const _EventFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label $count'),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.yellow,
      labelStyle: TextStyle(
        color: selected ? AppColors.ink : null,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

List<PlanningEventSummary> _visiblePlanningEvents(
  IntelligenceSnapshot intelligence,
  _EventRowFilter filter,
) {
  final selected = switch (filter) {
    _EventRowFilter.all => intelligence.planningEvents,
    _EventRowFilter.today => intelligence.planningToday,
    _EventRowFilter.week => intelligence.planningWeek,
    _EventRowFilter.month => intelligence.planningMonth,
    _EventRowFilter.questions => _eventsForQuestions(intelligence),
  };
  final seen = <int>{};
  return selected.where((event) => seen.add(event.id)).take(20).toList();
}

List<PlanningEventSummary> _eventsForQuestions(
  IntelligenceSnapshot intelligence,
) {
  final questionIds = intelligence.questionQueue
      .map((question) => question.eventId)
      .toSet();
  return intelligence.planningEvents
      .where((event) => questionIds.contains(event.id))
      .toList();
}

class _PlanningEventTile extends StatelessWidget {
  const _PlanningEventTile({required this.event});
  final PlanningEventSummary event;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.grey,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _eventColor(event.eventType),
              foregroundColor: AppColors.ink,
              child: Icon(_eventIcon(event.eventType), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(event.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (event.source.isNotEmpty) 'Source ${event.source}',
                      if (event.project.isNotEmpty) event.project,
                      if (event.deadline.isNotEmpty)
                        'Due ${_shortDate(event.deadline)}',
                      if (event.plannedStart.isNotEmpty)
                        '${event.plannedMinutes}m at ${_shortDate(event.plannedStart)}',
                    ].join('  -  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  if (event.repoUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Repo URL: ${event.repoUrl}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                  if (event.idea.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Idea: ${event.idea}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (event.workDone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Done: ${event.workDone}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (event.workLeft.isNotEmpty ||
                      event.nextQuestion.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.workLeft.isNotEmpty
                          ? 'Left: ${event.workLeft}'
                          : 'Ask: ${event.nextQuestion}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (event.lastProgressNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Latest note: ${event.lastProgressNote}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                  if (event.progressLog.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ProgressLogPreview(entries: event.progressLog),
                  ],
                  if (event.repoLatestActivity.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Repo activity: ${event.repoLatestActivity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressLogPreview extends StatelessWidget {
  const _ProgressLogPreview({required this.entries});
  final List<ProgressLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.grey,
      fontWeight: FontWeight.w600,
    );
    final recent = entries.reversed.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress notes', style: muted),
        const SizedBox(height: 4),
        for (final entry in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              [
                if (entry.at.isNotEmpty) _shortDate(entry.at),
                entry.note,
              ].join(' - '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _TextList extends StatelessWidget {
  const _TextList({required this.items, required this.empty});
  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyState(message: empty);
    return Column(
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(item, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

class TimelinePage extends StatelessWidget {
  const TimelinePage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _StandardPage(
      eyebrow: 'Daily record',
      title: 'Activity timeline',
      subtitle:
          'Every detected session stays local and can be reviewed by date.',
      action: IconButton(
        tooltip: 'Refresh',
        onPressed: controller.refresh,
        icon: const Icon(Icons.refresh),
      ),
      child: controller.sessions.isEmpty
          ? _EmptyState(message: controller.message)
          : Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: controller.sessions
                      .map((session) => _TimelineTile(session: session))
                      .toList(),
                ),
              ),
            ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.session});
  final ActivitySession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 58,
            decoration: BoxDecoration(
              color: categoryColor(session.category),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Text(
              '${session.startTime}\n${session.endTime}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subcategory,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.appName} · ${labelFor(session.category)} · ${session.confidence}% confidence',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                if (session.note?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      session.note!,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            formatMinutes(session.durationMinutes),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

enum _ApplicationFilter {
  all,
  applied,
  selected,
  noResponse,
  noFurtherEmail,
  assessment,
  interview,
  rejected,
  archive,
}

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({required this.controller, super.key});
  final AppController controller;

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  _ApplicationFilter filter = _ApplicationFilter.all;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.controller.agent.applications;
    final visible = _filtered(portfolio);
    return _StandardPage(
      eyebrow: 'Career pipeline',
      title: 'Applications',
      subtitle: widget.controller.agent.connected
          ? '${portfolio.stats.emailsScanned} of the latest ${portfolio.stats.scanLimit} combined emails scanned across ${portfolio.stats.accountsScanned} accounts. Job alerts and generic broadcasts are excluded.'
          : 'Start AiOS Assistant to load locally analyzed job and internship mail.',
      action: IconButton(
        tooltip: 'Sync application mail',
        onPressed: widget.controller.syncIntelligence,
        icon: const Icon(Icons.sync),
      ),
      child: Column(
        children: [
          _AgentConnectionBanner(
            agent: widget.controller.agent,
            onOpen: widget.controller.openAiOS,
          ),
          const SizedBox(height: 14),
          _ApplicationMetrics(stats: portfolio.stats),
          const SizedBox(height: 14),
          _ApplicationControls(
            selected: filter,
            archiveCount: portfolio.stats.archived,
            totalCount: portfolio.stats.total,
            onFilter: (value) => setState(() => filter = value),
            onSearch: (value) => setState(() => query = value.trim()),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final side = _ApplicationIntelligenceRail(portfolio: portfolio);
              final list = _ApplicationList(
                applications: visible,
                archive: filter == _ApplicationFilter.archive,
              );
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [side, const SizedBox(height: 14), list],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: list),
                  const SizedBox(width: 14),
                  SizedBox(width: 350, child: side),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<ApplicationRecord> _filtered(ApplicationPortfolio portfolio) {
    final source = filter == _ApplicationFilter.archive
        ? portfolio.archive
        : portfolio.active;
    return source.where((item) {
      final matchesStage = switch (filter) {
        _ApplicationFilter.all || _ApplicationFilter.archive => true,
        _ApplicationFilter.applied => item.stage == 'applied',
        _ApplicationFilter.selected => item.selectedForNextStep,
        _ApplicationFilter.noResponse => item.responseStatus == 'no_response',
        _ApplicationFilter.noFurtherEmail => !item.hasFurtherEmail,
        _ApplicationFilter.assessment =>
          item.stage == 'assessment' || item.stage == 'project',
        _ApplicationFilter.interview =>
          item.stage == 'interview' || item.stage == 'shortlisted',
        _ApplicationFilter.rejected => item.stage == 'rejected',
      };
      final terms =
          '${item.company} ${item.role} ${item.platform} ${item.sourceAccounts.join(' ')}'
              .toLowerCase();
      return matchesStage &&
          (query.isEmpty || terms.contains(query.toLowerCase()));
    }).toList();
  }
}

class _ApplicationMetrics extends StatelessWidget {
  const _ApplicationMetrics({required this.stats});
  final ApplicationStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Applied',
        '${stats.applied}',
        AppColors.yellow.withValues(alpha: 0.52),
        Icons.work_outline,
      ),
      (
        'Selected',
        '${stats.selected}',
        AppColors.mint,
        Icons.trending_up_rounded,
      ),
      (
        'No response',
        '${stats.noResponse}',
        AppColors.peach,
        Icons.hourglass_empty_rounded,
      ),
      (
        'No further email',
        '${stats.noFurtherEmail}',
        AppColors.ice,
        Icons.mark_email_unread_outlined,
      ),
      (
        'Rejected',
        '${stats.rejected}',
        const Color(0xFFFFD8D2),
        Icons.cancel_outlined,
      ),
      (
        'Selection rate',
        '${stats.selectedRate}%',
        const Color(0xFFD9D3FF),
        Icons.analytics_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 6
            : constraints.maxWidth >= 640
            ? 3
            : 2;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 6 ? 1.72 : 1.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final item in items)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.$3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            item.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(item.$4, size: 22),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ApplicationControls extends StatelessWidget {
  const _ApplicationControls({
    required this.selected,
    required this.archiveCount,
    required this.totalCount,
    required this.onFilter,
    required this.onSearch,
  });
  final _ApplicationFilter selected;
  final int archiveCount;
  final int totalCount;
  final ValueChanged<_ApplicationFilter> onFilter;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filters = Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _filterChip('All $totalCount', _ApplicationFilter.all),
              _filterChip('Applied', _ApplicationFilter.applied),
              _filterChip('Selected', _ApplicationFilter.selected),
              _filterChip('No response', _ApplicationFilter.noResponse),
              _filterChip(
                'No further email',
                _ApplicationFilter.noFurtherEmail,
              ),
              _filterChip('Assessment', _ApplicationFilter.assessment),
              _filterChip('Interview', _ApplicationFilter.interview),
              _filterChip('Rejected', _ApplicationFilter.rejected),
              _filterChip('Archive $archiveCount', _ApplicationFilter.archive),
            ],
          );
          final search = SizedBox(
            width: constraints.maxWidth >= 780 ? 270 : double.infinity,
            height: 44,
            child: TextField(
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Search company, role or email',
                prefixIcon: Icon(Icons.search, size: 19),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          );
          if (constraints.maxWidth < 780) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [filters, const SizedBox(height: 10), search],
            );
          }
          return Row(
            children: [
              Expanded(child: filters),
              const SizedBox(width: 12),
              search,
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, _ApplicationFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onFilter(value),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.applications, required this.archive});
  final List<ApplicationRecord> applications;
  final bool archive;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: archive ? 'Application archive' : 'Recent applications',
      title: archive
          ? '${applications.length} older companies'
          : '${applications.length} grouped companies',
      child: AnimatedSwitcher(
        duration: AppMotion.standard,
        child: applications.isEmpty
            ? _EmptyState(
                key: ValueKey('empty-$archive'),
                message: archive
                    ? 'No archived applications yet.'
                    : 'No matching application mail was found. Sync Gmail in AiOS and try again.',
              )
            : Column(
                key: ValueKey('$archive-${applications.length}'),
                children: [
                  for (final item in applications)
                    _ApplicationRow(
                      application: item,
                      onTap: () => _showApplicationDetails(context, item),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.application, required this.onTap});
  final ApplicationRecord application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = application.sourceEmail;
    final stageColor = _applicationStageColor(application.stage);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final identity = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: stageColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${application.company} - ${application.role}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              application.platform,
                              if (application.appliedAt.isNotEmpty)
                                'Applied ${_applicationDate(application.appliedAt)}',
                            ].join('  |  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          if (source != null && source.accountEmail.isNotEmpty)
                            Text(
                              'Mail: ${source.accountEmail}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
                final stage = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.stageLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${application.responseLabel} | ${application.mailCount} grouped mail${application.mailCount == 1 ? '' : 's'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                );
                final deadline = _ApplicationDeadlinePill(
                  application: application,
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: stage),
                          deadline,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 5, child: identity),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: stage),
                    const SizedBox(width: 10),
                    deadline,
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationDeadlinePill extends StatelessWidget {
  const _ApplicationDeadlinePill({required this.application});
  final ApplicationRecord application;

  @override
  Widget build(BuildContext context) {
    final days = application.daysLeft;
    final label = days == null
        ? application.stage == 'rejected'
              ? 'Closed'
              : application.responseStatus == 'no_response'
              ? '${application.daysWaiting}d no reply'
              : application.hasFurtherEmail
              ? 'Updated'
              : '1 mail'
        : days < 0
        ? 'Overdue'
        : days == 0
        ? 'Today'
        : '$days days';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: _applicationStageColor(
          application.stage,
        ).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ApplicationIntelligenceRail extends StatelessWidget {
  const _ApplicationIntelligenceRail({required this.portfolio});
  final ApplicationPortfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final actionItems = portfolio.active
        .where((item) => item.needsAction)
        .toList();
    final focus = portfolio.today.isNotEmpty
        ? portfolio.today.first
        : portfolio.dueSoon.isNotEmpty
        ? portfolio.dueSoon.first
        : actionItems.isEmpty
        ? null
        : actionItems.first;
    final projects = portfolio.active
        .map((item) => item.project)
        .whereType<ApplicationProject>()
        .toList();
    final project = projects.isEmpty ? null : projects.first;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TODAY'S PLAN",
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                focus == null
                    ? 'No hiring action due today'
                    : '${focus.company} - ${focus.stageLabel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                focus?.nextAction ??
                    'AiOS will move urgent application steps here after the next mail sync.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RailPanel(
          color: AppColors.yellow.withValues(alpha: 0.48),
          eyebrow: 'Deadlines approaching',
          children: portfolio.dueSoon.isEmpty
              ? const [Text('No application deadlines in the next seven days.')]
              : [
                  for (final item in portfolio.dueSoon.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.company} - ${item.daysLeft} days',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            item.nextAction,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
        ),
        const SizedBox(height: 12),
        _RailPanel(
          color: AppColors.ice,
          eyebrow: 'Project signals',
          children: project == null
              ? const [
                  Text(
                    'Link an internship or hackathon project in AiOS to track local files, GitHub and Codex history.',
                  ),
                ]
              : [
                  Text(
                    '${project.title} - ${project.progress}% complete',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: project.progress / 100),
                  const SizedBox(height: 8),
                  Text(
                    project.nextAction.isEmpty
                        ? 'Choose the next concrete project task.'
                        : project.nextAction,
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (project.signals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Sources: ${project.signals.map((value) => value.replaceAll('_', ' ')).join(', ')}',
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
        ),
      ],
    );
  }
}

class _RailPanel extends StatelessWidget {
  const _RailPanel({
    required this.color,
    required this.eyebrow,
    required this.children,
  });
  final Color color;
  final String eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

Future<void> _showApplicationDetails(
  BuildContext context,
  ApplicationRecord item,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.company,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.role,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(item.stageLabel)),
                  Chip(label: Text(item.responseLabel)),
                  Chip(label: Text(item.platform)),
                  Chip(label: Text('${item.mailCount} grouped emails')),
                  Chip(label: Text('${item.confidence.round()}% confidence')),
                  if (item.appliedAt.isNotEmpty)
                    Chip(
                      label: Text(
                        'Applied ${_applicationDate(item.appliedAt)}',
                      ),
                    ),
                  if (item.deadline.isNotEmpty)
                    Chip(label: Text('Due ${_shortDate(item.deadline)}')),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.summary.isEmpty
                    ? 'No local AI summary is available yet.'
                    : item.summary,
                style: const TextStyle(height: 1.45),
              ),
              const SizedBox(height: 16),
              Text(
                'Next action',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(item.nextAction),
              if (item.sourceEmails.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Source email',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final email in item.sourceEmails.take(4))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: Text(
                      email.subject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${email.accountEmail} | ${email.sender}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _applicationDate(email.receivedAt),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
              ],
              if (item.project case final project?) ...[
                const SizedBox(height: 18),
                Text(
                  'Linked project - ${project.progress}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: project.progress / 100),
                const SizedBox(height: 8),
                Text(project.nextAction),
              ],
              if (item.timeline.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Application timeline',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final event in item.timeline)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: _applicationStageColor(event.stage),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    title: Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${event.stage.replaceAll('_', ' ')} | ${_applicationDate(event.at)}',
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class HackathonsPage extends StatelessWidget {
  const HackathonsPage({required this.controller, super.key});
  final AppController controller;

  static const stages = [
    ('discovered', 'Watching'),
    ('applied', 'Applied'),
    ('building', 'Building'),
    ('submitted', 'Submitted'),
    ('selected', 'Results'),
  ];

  @override
  Widget build(BuildContext context) {
    final overview = controller.agent.applications.hackathons;
    final mailStats = overview.stats;
    return _StandardPage(
      eyebrow: 'Opportunity tracker',
      title: 'Hackathon corner',
      subtitle: controller.agent.connected
          ? '${mailStats.total} grouped events from your latest combined mail window. ${mailStats.dueSoon} due soon and ${mailStats.selected} selected.'
          : 'Plans, deadlines, progress, and work logs from local storage.',
      action: FilledButton.icon(
        onPressed: controller.syncIntelligence,
        icon: const Icon(Icons.sync_rounded, size: 18),
        label: const Text('Sync mail'),
      ),
      child: Column(
        children: [
          _HackathonStats(stats: mailStats),
          const SizedBox(height: 14),
          if (overview.items.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final stage in stages)
                    _MailHackathonColumn(
                      label: stage.$2,
                      items: overview.items
                          .where(
                            (item) => stage.$1 == 'selected'
                                ? item.stage == 'selected' ||
                                      item.stage == 'won'
                                : item.stage == stage.$1,
                          )
                          .toList(),
                    ),
                ],
              ),
            )
          else if (controller.hackathons.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final status in const [
                    'watching',
                    'applied',
                    'building',
                    'submitted',
                  ])
                    _HackathonColumn(
                      status: status,
                      items: controller.hackathons
                          .where((item) => item.status == status)
                          .toList(),
                    ),
                ],
              ),
            ),
          if (overview.items.isEmpty && controller.hackathons.isEmpty)
            const _EmptyState(
              message:
                  'No hackathon mail found yet. Connect Gmail in AiOS, then press Sync mail.',
            ),
        ],
      ),
    );
  }
}

class _HackathonStats extends StatelessWidget {
  const _HackathonStats({required this.stats});
  final HackathonMailStats stats;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Tracked', stats.total, Icons.emoji_events_outlined),
      ('Applied+', stats.applied, Icons.send_outlined),
      ('Building', stats.building, Icons.code_rounded),
      ('Selected', stats.selected, Icons.workspace_premium_outlined),
      ('Due soon', stats.dueSoon, Icons.timer_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620
            ? (constraints.maxWidth - 8) / 2
            : (constraints.maxWidth - 32) / 5;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in values)
              Container(
                width: width,
                constraints: const BoxConstraints(minWidth: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(item.$3, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${item.$2}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MailHackathonColumn extends StatelessWidget {
  const _MailHackathonColumn({required this.label, required this.items});
  final String label;
  final List<HackathonMailItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 12,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('No items', style: TextStyle(color: Colors.grey)),
              ),
            ),
          for (final item in items) _MailHackathonCard(item: item),
        ],
      ),
    );
  }
}

class _MailHackathonCard extends StatelessWidget {
  const _MailHackathonCard({required this.item});
  final HackathonMailItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final urgent =
        item.daysLeft != null && item.daysLeft! >= 0 && item.daysLeft! <= 7;
    final deadlineLabel = item.daysLeft == null
        ? 'No deadline found'
        : item.daysLeft! < 0
        ? '${item.daysLeft!.abs()} days overdue'
        : item.daysLeft == 0
        ? 'Due today'
        : '${item.daysLeft} days left';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  item.stage == 'won'
                      ? Icons.workspace_premium_rounded
                      : item.stage == 'selected'
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: item.stage == 'won' || item.stage == 'selected'
                      ? const Color(0xFF3C7A57)
                      : colors.outline,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _HackathonTag(
                  icon: urgent ? Icons.timer_rounded : Icons.event_outlined,
                  label: deadlineLabel,
                  emphasized: urgent,
                ),
                _HackathonTag(
                  icon: Icons.mail_outline,
                  label:
                      '${item.mailCount} mail${item.mailCount == 1 ? '' : 's'}',
                ),
                if (item.platforms.isNotEmpty)
                  _HackathonTag(
                    icon: Icons.public_outlined,
                    label: item.platforms.first,
                  ),
              ],
            ),
            if (item.summary.isNotEmpty) ...[
              const SizedBox(height: 11),
              Text(
                item.summary,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.42,
                ),
              ),
            ],
            if (item.sourceAccounts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.sourceAccounts.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HackathonTag extends StatelessWidget {
  const _HackathonTag({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.yellow.withValues(alpha: 0.32)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HackathonColumn extends StatelessWidget {
  const _HackathonColumn({required this.status, required this.items});
  final String status;
  final List<Hackathon> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 12,
                child: Text(
                  '${items.length}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text('No items', style: TextStyle(color: Colors.grey)),
              ),
            ),
          for (final item in items)
            Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.organizer,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: item.progress / 100,
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.progress}% · ${item.deadline.isEmpty ? 'No deadline' : item.deadline}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    if (item.plan.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        item.plan,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _StandardPage(
      eyebrow: 'Local boundary',
      title: 'Privacy control center',
      subtitle:
          'Inspect the exact signal classes used by the activity pipeline.',
      child: Column(
        children: const [
          _PermissionTile(
            icon: Icons.window_outlined,
            title: 'Active app detection',
            description: 'Process name and high-level window context',
            enabled: true,
          ),
          _PermissionTile(
            icon: Icons.timer_outlined,
            title: 'Idle detection',
            description: 'Time since the last local input event',
            enabled: true,
          ),
          _PermissionTile(
            icon: Icons.language_outlined,
            title: 'Browser domain detection',
            description: 'Optional supported-domain context only',
            enabled: false,
          ),
          _PermissionTile(
            icon: Icons.forum_outlined,
            title: 'Discord high-level state',
            description: 'App state without reading messages',
            enabled: false,
          ),
          _PermissionTile(
            icon: Icons.screenshot_monitor_outlined,
            title: 'Local screenshot understanding',
            description: 'Disabled; no screenshots are currently captured',
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: enabled ? AppColors.yellow : Colors.grey.shade300,
          foregroundColor: AppColors.ink,
          child: Icon(icon, size: 19),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(description),
        trailing: Chip(label: Text(enabled ? 'Enabled' : 'Optional')),
      ),
    );
  }
}

class AgentPage extends StatelessWidget {
  const AgentPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final agent = controller.agent;
    return _StandardPage(
      eyebrow: 'Companion integration',
      title: 'Project AI Agent desktop',
      subtitle: agent.message,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Open AiOS Desktop',
            onPressed: controller.openAiOS,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          IconButton(
            tooltip: 'Refresh agent services',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AgentConnectionBanner(agent: agent, onOpen: controller.openAiOS),
          const SizedBox(height: 12),
          _ReadinessPanel(readiness: agent.readiness),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _FeatureCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Reminders',
                  text: agent.connected
                      ? '${agent.activeReminders} active, ${agent.reminders.length} due soon'
                      : 'Time, task, app, and project-aware reminders.',
                  value: agent.connected ? '${agent.activeReminders}' : null,
                ),
                _FeatureCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Hackathons',
                  text: agent.connected
                      ? '${agent.hackathons} source items, ${agent.unreadHackathonUpdates} unread updates'
                      : 'Gmail and platform opportunity monitoring.',
                  value: agent.connected ? '${agent.hackathons}' : null,
                ),
                _FeatureCard(
                  icon: Icons.work_outline,
                  title: 'Placements',
                  text: agent.connected
                      ? '${agent.placements} jobs, ${agent.unreadPlacementUpdates} unread updates'
                      : 'Applications, interviews, status, and next actions.',
                  value: agent.connected ? '${agent.placements}' : null,
                ),
                _FeatureCard(
                  icon: Icons.school_outlined,
                  title: 'NeoPat',
                  text: agent.connected
                      ? '${agent.neopat} practice or assessment items'
                      : 'Practice-test and training assessment tracking.',
                  value: agent.connected ? '${agent.neopat}' : null,
                ),
                _FeatureCard(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Wellbeing context',
                  text: agent.connected
                      ? '${formatMinutes(agent.wellbeingMinutes)} already known by AiOS'
                      : 'Approved WDYD summaries stay local.',
                  value: agent.connected
                      ? formatMinutes(agent.wellbeingMinutes)
                      : null,
                ),
                _FeatureCard(
                  icon: Icons.memory_outlined,
                  title: 'Desktop services',
                  text: agent.connected
                      ? '${agent.runningWorkers}/${agent.workers.length} services running'
                      : 'Reminder, import, and opportunity workers.',
                  value: agent.connected
                      ? '${agent.runningWorkers}/${agent.workers.length}'
                      : null,
                ),
              ];
              return GridView.count(
                crossAxisCount: constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 620
                    ? 2
                    : 1,
                childAspectRatio: constraints.maxWidth > 620 ? 2.1 : 2.7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 12),
          if (agent.connected) ...[
            _Panel(
              eyebrow: 'Plan',
              title: 'What AiOS recommends today',
              child: Text(
                agent.planSummary.isEmpty
                    ? 'No plan summary yet.'
                    : agent.planSummary,
              ),
            ),
            const SizedBox(height: 12),
            _Panel(
              eyebrow: 'Services',
              title: 'Desktop workers',
              child: Column(
                children: agent.workers
                    .map((worker) => _WorkerRow(worker: worker))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _Panel(
              eyebrow: 'Latest',
              title: 'Agent context',
              child: Column(
                children: [
                  _InfoLine(
                    icon: Icons.insights_outlined,
                    label: 'Latest opportunity',
                    value: agent.latestOpportunityTitle.isEmpty
                        ? 'No opportunity yet'
                        : agent.latestOpportunityTitle,
                  ),
                  _InfoLine(
                    icon: Icons.favorite_border,
                    label: 'Latest wellbeing insight',
                    value: agent.latestActivitySummary.isEmpty
                        ? 'No wellbeing insight yet'
                        : agent.latestActivitySummary,
                  ),
                ],
              ),
            ),
          ] else
            const _EmptyState(
              message:
                  'Start the AiOS Desktop app. WDYD will pair through the local loopback service automatically.',
            ),
        ],
      ),
    );
  }
}

class _AgentConnectionBanner extends StatelessWidget {
  const _AgentConnectionBanner({required this.agent, required this.onOpen});
  final AgentDesktopSnapshot agent;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final connected = agent.connected;
    final stale = agent.stale;
    final colors = Theme.of(context).colorScheme;
    final tone = stale
        ? AppColors.peach
        : connected
        ? AppColors.yellow
        : Colors.grey;
    final lastUpdated = agent.updatedAt.isEmpty
        ? ''
        : _shortDate(agent.updatedAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: connected ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tone,
            foregroundColor: AppColors.ink,
            child: Icon(
              stale
                  ? Icons.sync_problem_rounded
                  : connected
                  ? Icons.link
                  : Icons.link_off,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stale
                      ? 'Reconnecting to AiOS Desktop'
                      : connected
                      ? 'Paired with AiOS Desktop'
                      : 'AiOS Desktop unavailable',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  stale
                      ? agent.message
                      : connected
                      ? '${agent.baseUrl} | ${agent.desktop ? 'native desktop' : 'browser mode'}${lastUpdated.isEmpty ? '' : ' | Updated $lastUpdated'}'
                      : agent.message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!connected || stale)
            IconButton(
              tooltip: 'Open AiOS Desktop',
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
            )
          else
            Chip(
              avatar: Icon(
                stale ? Icons.history_rounded : Icons.lock_outline,
                size: 14,
              ),
              label: Text(stale ? 'Saved locally' : 'Live loopback'),
              backgroundColor: colors.surfaceContainerHighest,
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
    this.value,
  });
  final IconData icon;
  final String title;
  final String text;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.ink,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.worker});
  final AgentWorker worker;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: worker.running
            ? AppColors.yellow
            : Colors.grey.withValues(alpha: 0.28),
        foregroundColor: AppColors.ink,
        child: Icon(worker.running ? Icons.play_arrow : Icons.pause),
      ),
      title: Text(
        worker.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        worker.lastError.isEmpty
            ? (worker.managed ? 'Managed by AiOS Desktop' : worker.id)
            : worker.lastError,
      ),
      trailing: Chip(label: Text(worker.running ? 'Running' : 'Stopped')),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(value),
    );
  }
}

class WidgetsPage extends StatelessWidget {
  const WidgetsPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary;
    return _StandardPage(
      eyebrow: 'Glanceable surfaces',
      title: 'Desktop and mobile widgets',
      subtitle: 'Native widget concepts driven by approved local summaries.',
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _WidgetPreview(
            width: 330,
            title: 'Today',
            value: formatMinutes(summary.totalMinutes),
            detail: '${controller.sessions.length} sessions tracked',
            icon: Icons.monitor_outlined,
          ),
          _WidgetPreview(
            width: 230,
            title: 'Focus',
            value: formatMinutes(summary.focusMinutes),
            detail: 'Private local context',
            icon: Icons.phone_android_outlined,
          ),
          _WidgetPreview(
            width: 280,
            title: 'Current activity',
            value: controller.sessions.isEmpty
                ? 'No session'
                : controller.sessions.first.appName,
            detail: controller.sessions.isEmpty
                ? 'Collector offline'
                : controller.sessions.first.subcategory,
            icon: Icons.bolt,
          ),
        ],
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({
    required this.width,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });
  final double width;
  final String title;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.yellow, size: 19),
              const Spacer(),
              const Icon(Icons.lock_outline, color: Colors.white54, size: 15),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _StandardPage(
      eyebrow: 'Application',
      title: 'Settings',
      subtitle: 'Runtime state and local endpoints for this Flutter client.',
      child: Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              subtitle: const Text('Use the native dark application theme'),
              value: controller.darkMode,
              onChanged: (_) => controller.toggleTheme(),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.rocket_launch_outlined),
              title: const Text('Launch app at sign-in'),
              subtitle: Text(
                controller.startupAvailable
                    ? 'Open What Do You Do automatically after Windows login'
                    : controller.startupMessage,
              ),
              value: controller.launchAppAtLogin,
              onChanged: controller.startupAvailable
                  ? controller.setLaunchAppAtLogin
                  : null,
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.system_security_update_outlined),
              title: const Text('Open in background at sign-in'),
              subtitle: const Text(
                'Start hidden in the tray until you open it from the tray icon',
              ),
              value: controller.launchAppHiddenAtLogin,
              onChanged: controller.startupAvailable
                  ? controller.setLaunchAppHiddenAtLogin
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.keyboard_arrow_down_outlined),
              title: const Text('Hide to tray now'),
              subtitle: const Text('Keep WDYD running without an open window'),
              onTap: controller.hideToTray,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.power_settings_new_outlined),
              title: const Text('Exit What Do You Do'),
              subtitle: const Text('Fully quit the app instead of hiding it'),
              onTap: controller.exitApp,
            ),
            const Divider(height: 1),
            _SettingRow(
              label: 'Collector',
              value: controller.collectorOnline ? 'Online' : 'Offline',
            ),
            _SettingRow(
              label: 'AiOS Desktop',
              value: controller.agent.stale
                  ? 'Reconnecting - saved data visible'
                  : controller.agent.connected
                  ? 'Connected live'
                  : 'Unavailable',
            ),
            _SettingRow(
              label: 'AiOS API',
              value: controller.agent.connected
                  ? controller.agent.baseUrl
                  : 'Not paired',
            ),
            const _SettingRow(
              label: 'Activity engine',
              value: 'In-process Windows native',
            ),
            _SettingRow(label: 'Selected date', value: controller.selectedDate),
            _SettingRow(
              label: 'Storage',
              value: controller.collectorOnline
                  ? 'Local daily JSON'
                  : 'Unavailable',
            ),
            const _SettingRow(
              label: 'Rendering',
              value: 'Flutter native canvas',
            ),
            if (controller.agent.connected) ...[
              _SettingRow(label: 'AiOS data', value: controller.agent.dataDir),
              _SettingRow(
                label: 'AiOS imports',
                value: controller.agent.importsDir,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardPage extends StatelessWidget {
  const _StandardPage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.grey, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

Color categoryColor(ActivityCategory category) {
  return switch (category) {
    ActivityCategory.coding => AppColors.yellow,
    ActivityCategory.browsing => const Color(0xFF8FD5C0),
    ActivityCategory.communication => const Color(0xFF9BADE8),
    ActivityCategory.gaming => const Color(0xFFE89A91),
    ActivityCategory.watching => const Color(0xFFC9B1E3),
    ActivityCategory.idle => const Color(0xFF9FA399),
  };
}

String labelFor(ActivityCategory category) {
  return switch (category) {
    ActivityCategory.coding => 'Coding',
    ActivityCategory.browsing => 'Research',
    ActivityCategory.communication => 'Communication',
    ActivityCategory.gaming => 'Gaming',
    ActivityCategory.watching => 'Learning',
    ActivityCategory.idle => 'Idle',
  };
}

String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours == 0) return '${remainder}m';
  return '${hours}h ${remainder}m';
}

bool _sameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

IconData _eventIcon(String type) {
  return switch (type) {
    'hackathon' => Icons.emoji_events_outlined,
    'application' => Icons.work_outline,
    'email' => Icons.mark_email_unread_outlined,
    'repo' => Icons.code_outlined,
    'learning_video' => Icons.play_circle_outline,
    'goal' => Icons.flag_outlined,
    _ => Icons.task_alt_outlined,
  };
}

Color _eventColor(String type) {
  return switch (type) {
    'hackathon' => AppColors.yellow,
    'application' => AppColors.peach,
    'email' => AppColors.ice,
    'repo' => AppColors.mint,
    'learning_video' => const Color(0xFFC9B1E3),
    'goal' => const Color(0xFFFFF0B2),
    _ => Colors.grey.withValues(alpha: 0.28),
  };
}

String _shortDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('MMM d, h:mm a').format(parsed.toLocal());
}

String _formatDraftDate(DateTime value) {
  return DateFormat('MMM d, h:mm a').format(value);
}

Color _applicationStageColor(String stage) {
  return switch (stage) {
    'offer' || 'interview' || 'shortlisted' => AppColors.mint,
    'assessment' => AppColors.yellow,
    'project' => AppColors.peach,
    'rejected' => Colors.grey.withValues(alpha: 0.42),
    _ => AppColors.ice,
  };
}

String _applicationDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return DateFormat('dd MMM yyyy').format(parsed.toLocal());
}
