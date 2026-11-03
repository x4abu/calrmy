import 'package:intl/intl.dart';

class Alarm {
  final int id;
  String time; // "HH:mm" in 24h
  String label;
  String goal;
  List<int> days; // 0=Sun, 1=Mon, ..., 6=Sat. Empty = once
  bool isEnabled;
  String sound;
  bool vibrate;
  double volume;
  bool isTemporary;
  int snoozeMinutes;

  Alarm({
    required this.id,
    required this.time,
    this.label = 'Alarm',
    this.goal = '',
    this.days = const [],
    this.isEnabled = true,
    this.sound = 'zen_singing_bowl.wav',
    this.vibrate = true,
    this.volume = 0.9,
    this.isTemporary = false,
    this.snoozeMinutes = 5,
  });

  int get hour => int.parse(time.split(':')[0]);
  int get minute => int.parse(time.split(':')[1]);

  String get formattedDisplayTime {
    final h = hour;
    final m = minute.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final displayHour = (h % 12 == 0) ? 12 : (h % 12);
    return '$displayHour:$m';
  }

  String get period => hour < 12 ? 'AM' : 'PM';

  String get daysSummary {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(0) && days.contains(6)) {
      return 'Weekends';
    }
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((d) => dayNames[d]).join(' ');
  }

  DateTime nextTriggerDateTime() {
    final now = DateTime.now();
    for (int i = 0; i < 8; i++) {
      final candidate = DateTime(now.year, now.month, now.day + i, hour, minute);
      if (candidate.isAfter(now)) {
        if (days.isEmpty || days.contains(candidate.weekday % 7)) {
          return candidate;
        }
      }
    }
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'label': label,
        'goal': goal,
        'days': days,
        'isEnabled': isEnabled,
        'sound': sound,
        'vibrate': vibrate,
        'volume': volume,
        'isTemporary': isTemporary,
        'snoozeMinutes': snoozeMinutes,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as int,
        time: json['time'] as String,
        label: json['label'] as String? ?? 'Alarm',
        goal: json['goal'] as String? ?? '',
        days: (json['days'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
        isEnabled: json['isEnabled'] as bool? ?? true,
        sound: json['sound'] as String? ?? 'zen_singing_bowl.wav',
        vibrate: json['vibrate'] as bool? ?? true,
        volume: (json['volume'] as num?)?.toDouble() ?? 0.9,
        isTemporary: json['isTemporary'] as bool? ?? false,
        snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      );
}
