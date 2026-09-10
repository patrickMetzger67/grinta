import 'package:flutter/material.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/util/player_task_bar_layout.dart';

/// Week-aligned bars painted under the agenda date strip.
class AgendaPlayerTaskBars extends StatelessWidget {
  const AgendaPlayerTaskBars({
    super.key,
    required this.tasks,
    required this.weekStart,
    required this.onTaskTap,
    this.labelFor,
    this.showAssigneeIcon,
  });

  final List<PlayerTask> tasks;
  final DateTime weekStart;
  final ValueChanged<PlayerTask> onTaskTap;

  /// When set, used instead of [PlayerTask.barLabel] (managers get a richer
  /// `team - task - count` chip).
  final String Function(PlayerTask task)? labelFor;

  /// Managers get a people icon after the assignee count (same glyph as the
  /// agenda training « Joueurs » row).
  final bool Function(PlayerTask task)? showAssigneeIcon;

  static const IconData assigneeCountIcon = Icons.groups_2_outlined;

  static const double _laneHeight = 22.0;
  static const double _laneGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final List<PlayerTaskBarSpan> spans = layoutPlayerTaskBars(
      tasks: tasks,
      weekStart: weekStart,
    );
    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }

    final int laneCount = playerTaskBarLaneCount(spans);
    final Map<int, List<PlayerTaskBarSpan>> byLane =
        <int, List<PlayerTaskBarSpan>>{};
    for (final PlayerTaskBarSpan span in spans) {
      byLane.putIfAbsent(span.lane, () => <PlayerTaskBarSpan>[]).add(span);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (int lane = 0; lane < laneCount; lane++)
            Padding(
              padding: EdgeInsets.only(
                bottom: lane == laneCount - 1 ? 0 : _laneGap,
              ),
              child: SizedBox(
                height: _laneHeight,
                child: _LaneRow(
                  spans: List<PlayerTaskBarSpan>.from(
                    byLane[lane] ?? const <PlayerTaskBarSpan>[],
                  )..sort(
                      (PlayerTaskBarSpan a, PlayerTaskBarSpan b) =>
                          a.startColumn.compareTo(b.startColumn),
                    ),
                  onTaskTap: onTaskTap,
                  labelFor: labelFor,
                  showAssigneeIcon: showAssigneeIcon,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LaneRow extends StatelessWidget {
  const _LaneRow({
    required this.spans,
    required this.onTaskTap,
    this.labelFor,
    this.showAssigneeIcon,
  });

  final List<PlayerTaskBarSpan> spans;
  final ValueChanged<PlayerTask> onTaskTap;
  final String Function(PlayerTask task)? labelFor;
  final bool Function(PlayerTask task)? showAssigneeIcon;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    int cursor = 0;
    for (final PlayerTaskBarSpan span in spans) {
      if (span.startColumn > cursor) {
        children.add(Spacer(flex: span.startColumn - cursor));
      }
      children.add(
        Expanded(
          flex: span.columnSpan,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _TaskBarChip(
              task: span.task,
              label: labelFor?.call(span.task) ?? span.task.barLabel,
              showAssigneeIcon: showAssigneeIcon?.call(span.task) ?? false,
              onTap: () => onTaskTap(span.task),
            ),
          ),
        ),
      );
      cursor = span.endColumn + 1;
    }
    if (cursor < 7) {
      children.add(Spacer(flex: 7 - cursor));
    }

    return Row(children: children);
  }
}

class _TaskBarChip extends StatelessWidget {
  const _TaskBarChip({
    required this.task,
    required this.label,
    required this.showAssigneeIcon,
    required this.onTap,
  });

  final PlayerTask task;
  final String label;
  final bool showAssigneeIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    return Material(
      color: task.colorValue,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
                if (showAssigneeIcon) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    AgendaPlayerTaskBars.assigneeCountIcon,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
