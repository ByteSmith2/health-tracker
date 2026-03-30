import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final _db = DatabaseService.instance;
  List<SleepRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _db.getSleepRecords();
    setState(() => _records = records);
  }

  Future<void> _addSleepRecord() async {
    TimeOfDay bedTime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
    int quality = 3;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final suggestedBed = AIService.instance.getSuggestedBedtime(
            DateTime(2024, 1, 1, wakeTime.hour, wakeTime.minute),
          );

          return AlertDialog(
            title: const Text('Ghi nhận giấc ngủ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bedtime),
                    title: const Text('Giờ đi ngủ'),
                    trailing: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: bedTime,
                        );
                        if (t != null) setDialogState(() => bedTime = t);
                      },
                      child: Text(bedTime.format(ctx)),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wb_sunny),
                    title: const Text('Giờ thức dậy'),
                    trailing: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: wakeTime,
                        );
                        if (t != null) setDialogState(() => wakeTime = t);
                      },
                      child: Text(wakeTime.format(ctx)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'AI gợi ý: nên ngủ lúc $suggestedBed',
                          style: const TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chất lượng giấc ngủ'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () => setDialogState(() => quality = i + 1),
                        icon: Icon(
                          i < quality ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  Text(
                    SleepRecord(
                      bedTime: DateTime.now(),
                      wakeTime: DateTime.now(),
                      qualityRating: quality,
                    ).qualityText,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final now = DateTime.now();
      DateTime bed = DateTime(now.year, now.month, now.day, bedTime.hour, bedTime.minute);
      DateTime wake = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);

      // If bed time is in the evening and wake is in the morning, bed was yesterday
      if (bed.isAfter(wake)) {
        bed = bed.subtract(const Duration(days: 1));
      }

      final record = SleepRecord(
        bedTime: bed,
        wakeTime: wake,
        qualityRating: quality,
      );
      await _db.insertSleepRecord(record);
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate average sleep
    double avgHours = 0;
    if (_records.isNotEmpty) {
      final totalMinutes = _records.fold(0, (s, r) => s + r.duration.inMinutes);
      avgHours = totalMinutes / _records.length / 60.0;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Giấc ngủ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trung bình',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          '${avgHours.toStringAsFixed(1)} giờ/đêm',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    avgHours >= 7
                        ? Icons.sentiment_satisfied
                        : Icons.sentiment_dissatisfied,
                    size: 48,
                    color: avgHours >= 7 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lịch sử giấc ngủ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_records.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Chưa có dữ liệu giấc ngủ'),
              ),
            )
          else
            ..._records.map((record) => Dismissible(
                  key: Key(record.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _db.deleteSleepRecord(record.id!);
                    _loadRecords();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _qualityColor(record.qualityRating)
                            .withValues(alpha: 0.2),
                        child: Icon(
                          Icons.bedtime,
                          color: _qualityColor(record.qualityRating),
                        ),
                      ),
                      title: Text(record.durationText),
                      subtitle: Text(
                        '${DateFormat('dd/MM - HH:mm').format(record.bedTime)} → '
                        '${DateFormat('HH:mm').format(record.wakeTime)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < record.qualityRating
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSleepRecord,
        icon: const Icon(Icons.add),
        label: const Text('Ghi nhận'),
      ),
    );
  }

  Color _qualityColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
