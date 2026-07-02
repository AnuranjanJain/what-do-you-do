import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_controller.dart';
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
    _Destination('Timeline', Icons.monitor_heart_outlined),
    _Destination('Hackathons', Icons.emoji_events_outlined),
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
                      child: _PageBody(
                        index: selectedIndex,
                        controller: controller,
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
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: online ? const Color(0xFF42A86B) : const Color(0xFFE66B6B),
          shape: BoxShape.circle,
        ),
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
    return Material(
      color: selected
          ? (dark ? AppColors.yellow : AppColors.ink)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
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
                color: selected ? (dark ? AppColors.ink : Colors.white) : null,
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
      1 => TimelinePage(controller: controller),
      2 => HackathonsPage(controller: controller),
      3 => PrivacyPage(controller: controller),
      4 => AgentPage(controller: controller),
      5 => WidgetsPage(controller: controller),
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
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.05) : color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 26)),
          Text(
            detail,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
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

class HackathonsPage extends StatelessWidget {
  const HackathonsPage({required this.controller, super.key});
  final AppController controller;

  static const columns = ['watching', 'applied', 'building', 'submitted'];

  @override
  Widget build(BuildContext context) {
    return _StandardPage(
      eyebrow: 'Opportunity tracker',
      title: 'Hackathon corner',
      subtitle: controller.agent.connected
          ? '${controller.agent.hackathons} AiOS source items, ${controller.agent.unreadHackathonUpdates} unread updates.'
          : 'Plans, deadlines, progress, and work logs from local storage.',
      action: IconButton(
        tooltip: 'Refresh',
        onPressed: controller.refresh,
        icon: const Icon(Icons.refresh),
      ),
      child: controller.hackathons.isEmpty
          ? const _EmptyState(
              message:
                  'No hackathons tracked yet. Add them from the existing collector API.',
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final status in columns)
                    _HackathonColumn(
                      status: status,
                      items: controller.hackathons
                          .where((item) => item.status == status)
                          .toList(),
                    ),
                ],
              ),
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
      action: IconButton(
        tooltip: 'Refresh agent services',
        onPressed: controller.refresh,
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AgentConnectionBanner(agent: agent),
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
  const _AgentConnectionBanner({required this.agent});
  final AgentDesktopSnapshot agent;

  @override
  Widget build(BuildContext context) {
    final connected = agent.connected;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: connected
            ? AppColors.yellow.withValues(alpha: 0.22)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: connected ? AppColors.yellow : Colors.grey,
            foregroundColor: AppColors.ink,
            child: Icon(connected ? Icons.link : Icons.link_off),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? 'Paired with AiOS Desktop'
                      : 'AiOS Desktop unavailable',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  connected
                      ? '${agent.baseUrl} · ${agent.desktop ? 'native desktop' : 'browser mode'}'
                      : agent.message,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (connected)
            Chip(
              avatar: const Icon(Icons.lock_outline, size: 14),
              label: const Text('Loopback'),
              backgroundColor: Colors.white.withValues(alpha: 0.52),
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
            SwitchListTile(
              secondary: const Icon(Icons.sensors_outlined),
              title: const Text('Start local collector at sign-in'),
              subtitle: Text(controller.startupMessage),
              value: controller.launchCollectorAtLogin,
              onChanged:
                  controller.startupAvailable &&
                      controller.collectorStartupAvailable
                  ? controller.setLaunchCollectorAtLogin
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
              value: controller.agent.connected ? 'Connected' : 'Unavailable',
            ),
            _SettingRow(
              label: 'AiOS API',
              value: controller.agent.connected
                  ? controller.agent.baseUrl
                  : 'Not paired',
            ),
            const _SettingRow(
              label: 'Collector API',
              value: CollectorEndpoint.label,
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

abstract final class CollectorEndpoint {
  static const label = '127.0.0.1:17321';
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
  const _EmptyState({required this.message});
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
