import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import 'sound_service.dart';

class AlarmService {
  static final AlarmService instance = AlarmService._internal();
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<Alarm> _alarms = [];
  Timer? _ticker;
  String _lastFiredKey = '';

  final ValueNotifier<List<Alarm>> alarmsNotifier = ValueNotifier([]);
  final ValueNotifier<Alarm?> ringingAlarmNotifier = ValueNotifier(null);

  List<Alarm> get alarms => _alarms;
  Alarm? get ringingAlarm => ringingAlarmNotifier.value;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final alarmId = int.tryParse(details.payload!);
          if (alarmId != null) {
            final match = _alarms.firstWhere(
              (a) => a.id == alarmId,
              orElse: () => _alarms.first,
            );
            triggerRing(match);
          }
        }
      },
    );

    await _loadAlarms();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _checkAlarms());
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final currentKey =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dayKey = '$currentKey-${now.day}-${now.month}';

    if (now.second < 2 && _lastFiredKey != dayKey) {
      for (final alarm in _alarms) {
        if (alarm.isEnabled && alarm.time == currentKey) {
          final isTodayScheduled = alarm.days.isEmpty ||
              alarm.days.contains(now.weekday % 7);
          if (isTodayScheduled) {
            _lastFiredKey = dayKey;
            triggerRing(alarm);
            break;
          }
        }
      }
    }
  }

  void triggerRing(Alarm alarm) {
    ringingAlarmNotifier.value = alarm;
    SoundService.instance.playLooping(alarm.sound, volume: alarm.volume);
    _showNotification(alarm);
  }

  Future<void> _showNotification(Alarm alarm) async {
    const androidDetails = AndroidNotificationDetails(
      'calrmy_alarm_channel',
      'cAlrmy Alarms',
      channelDescription: 'High priority alarm notifications for cAlrmy',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      alarm.id,
      alarm.label,
      'Time to wake up! ${alarm.goal.isNotEmpty ? "Goal: " + alarm.goal : ""}',
      details,
      payload: alarm.id.toString(),
    );
  }

  Future<void> snooze() async {
    final active = ringingAlarm;
    await dismiss();
    if (active != null) {
      final snoozeTime =
          DateTime.now().add(Duration(minutes: active.snoozeMinutes));
      final hh = snoozeTime.hour.toString().padLeft(2, '0');
      final mm = snoozeTime.minute.toString().padLeft(2, '0');

      final snoozeAlarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch,
        time: '$hh:$mm',
        label: '${active.label} (Snooze)',
        goal: active.goal,
        days: [],
        isEnabled: true,
        sound: active.sound,
        vibrate: active.vibrate,
        volume: active.volume,
        isTemporary: true,
      );

      await addAlarm(snoozeAlarm);
    }
  }

  Future<void> dismiss() async {
    ringingAlarmNotifier.value = null;
    await SoundService.instance.stop();

    // Clean up temporary snooze alarms if any
    _alarms.removeWhere((a) => a.isTemporary);
    _notifyAndSave();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('saved_alarms');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonStr);
        _alarms = list.map((e) => Alarm.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error parsing saved alarms: $e');
      }
    }

    if (_alarms.isEmpty) {
      // Default alarms as in the HTML design
      _alarms = [
        Alarm(
          id: 1,
          time: '06:30',
          label: 'Morning routine',
          goal: 'Study session',
          days: [1, 2, 3, 4, 5],
          isEnabled: true,
          sound: 'zen_singing_bowl.wav',
        ),
        Alarm(
          id: 2,
          time: '08:00',
          label: 'Weekend vibe',
          goal: 'Relax & recharge',
          days: [0, 6],
          isEnabled: false,
          sound: 'sunrise_acoustic.wav',
        ),
      ];
      await _saveAlarms();
    }

    _sortAlarms();
    alarmsNotifier.value = List.unmodifiable(_alarms);
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    _sortAlarms();
    await _notifyAndSave();
  }

  Future<void> updateAlarm(Alarm updated) async {
    final idx = _alarms.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _alarms[idx] = updated;
      _sortAlarms();
      await _notifyAndSave();
    }
  }

  Future<void> toggleAlarm(Alarm alarm) async {
    alarm.isEnabled = !alarm.isEnabled;
    await _notifyAndSave();
  }

  Future<void> deleteAlarm(int id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _notifyAndSave();
  }

  void _sortAlarms() {
    _alarms.sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> _notifyAndSave() async {
    alarmsNotifier.value = List.unmodifiable(_alarms);
    await _saveAlarms();
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _alarms.map((a) => a.toJson()).toList();
    await prefs.setString('saved_alarms', jsonEncode(jsonList));
  }

  Alarm? get nextAlarm {
    final active = _alarms.where((a) => a.isEnabled).toList();
    if (active.isEmpty) return null;

    active.sort((a, b) =>
        a.nextTriggerDateTime().compareTo(b.nextTriggerDateTime()));
    return active.first;
  }
}
