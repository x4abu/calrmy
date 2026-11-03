import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class NewAlarmModal extends StatefulWidget {
  final Alarm? existingAlarm;
  final bool isDark;
  final Function(Alarm) onSave;

  const NewAlarmModal({
    super.key,
    this.existingAlarm,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<NewAlarmModal> createState() => _NewAlarmModalState();
}

class _NewAlarmModalState extends State<NewAlarmModal> {
  late TimeOfDay _selectedTime;
  late final TextEditingController _labelController;
  late final TextEditingController _goalController;
  late List<int> _selectedDays;
  late String _selectedSound;
  late double _volume;
  late bool _vibrate;
  late String _mission;
  late bool _gradualWake;

  final SoundService _soundService = SoundService.instance;
  bool _isPlayingPreview = false;

  @override
  void initState() {
    super.initState();
    final al = widget.existingAlarm;
    if (al != null) {
      _selectedTime = TimeOfDay(hour: al.hour, minute: al.minute);
      _labelController = TextEditingController(text: al.label);
      _goalController = TextEditingController(text: al.goal);
      _selectedDays = List.from(al.days);
      _selectedSound = al.sound;
      _volume = al.volume;
      _vibrate = al.vibrate;
      _mission = al.mission;
      _gradualWake = al.gradualWake;
    } else {
      _selectedTime = const TimeOfDay(hour: 6, minute: 30);
      _labelController = TextEditingController(text: 'Wake up');
      _goalController = TextEditingController(text: '');
      _selectedDays = [1, 2, 3, 4, 5];
      _selectedSound = 'zen_singing_bowl.wav';
      _volume = 0.9;
      _vibrate = true;
      _mission = 'none';
      _gradualWake = true;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _goalController.dispose();
    _soundService.stop();
    super.dispose();
  }

  void _togglePreview() async {
    if (_isPlayingPreview) {
      await _soundService.stop();
      setState(() => _isPlayingPreview = false);
    } else {
      setState(() => _isPlayingPreview = true);
      await _soundService.previewSound(_selectedSound, volume: _volume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;

    final displayHour = (_selectedTime.hour % 12 == 0)
        ? 12
        : (_selectedTime.hour % 12);
    final displayMin =
        _selectedTime.minute.toString().padLeft(2, '0');
    final displayPeriod = _selectedTime.hour < 12 ? 'AM' : 'PM';

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkBg2 : AppColors.lightBg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: mute.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingAlarm == null ? 'Set Alarm' : 'Edit Alarm',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: ink,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: mute),
                  onPressed: () {
                    _soundService.stop();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Giant 64pt Time Selector
            Center(
              child: InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$displayHour:$displayMin',
                        style: GoogleFonts.interTight(
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -3,
                          color: ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayPeriod,
                        style: GoogleFonts.interTight(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: acc,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Repeating Days Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(index);
                      } else {
                        _selectedDays.add(index);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? acc
                          : (widget.isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04)),
                      border: Border.all(
                        color: isSelected
                            ? acc
                            : (widget.isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.08)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? (widget.isDark
                                ? AppColors.darkAccentInk
                                : Colors.black)
                            : mute,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Label & Goal Input
            GlassBox(
              isDark: widget.isDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  TextField(
                    controller: _labelController,
                    style: TextStyle(color: ink, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Label',
                      labelStyle: TextStyle(color: mute, fontSize: 12),
                      border: InputBorder.none,
                      hintText: 'Morning routine, Gym, Study…',
                      hintStyle: TextStyle(color: mute.withOpacity(0.4)),
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  TextField(
                    controller: _goalController,
                    style: TextStyle(color: ink, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'AI Goal for this alarm',
                      labelStyle: TextStyle(color: mute, fontSize: 12),
                      border: InputBorder.none,
                      hintText: 'e.g. Finish math homework, hit 5k run…',
                      hintStyle: TextStyle(color: mute.withOpacity(0.4)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Wake-up Mission Challenge Selector
            Text(
              'DISMISS CHALLENGE / MISSION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: mute,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMissionChip('none', 'Standard Dismiss', acc, ink, mute),
                _buildMissionChip('math', '🧮 Math Puzzle', acc, ink, mute),
                _buildMissionChip('riddle', '🧩 AI Riddle', acc, ink, mute),
                _buildMissionChip('shake', '📱 Fast Taps', acc, ink, mute),
                _buildMissionChip('roast', '🔥 Savage Roast', acc, ink, mute),
              ],
            ),
            const SizedBox(height: 18),

            // Sound Selector with Preview
            Text(
              'ALARM TONE (24 Available)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: mute,
              ),
            ),
            const SizedBox(height: 8),
            GlassBox(
              isDark: widget.isDark,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSound,
                        dropdownColor: widget.isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        style: TextStyle(color: ink, fontSize: 14),
                        isExpanded: true,
                        items: SoundService.availableSounds.map((snd) {
                          return DropdownMenuItem<String>(
                            value: snd.filename,
                            child: Text(
                              '${snd.title} (${snd.category})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSound = val);
                            if (_isPlayingPreview) {
                              _soundService.previewSound(val, volume: _volume);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlayingPreview ? Icons.stop : Icons.play_arrow,
                      color: acc,
                    ),
                    onPressed: _togglePreview,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ascending Volume Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gradual Wake (Ascending Volume)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    Text(
                      'Starts softly at 15% and ramps up over 25s',
                      style: TextStyle(fontSize: 11, color: mute),
                    ),
                  ],
                ),
                Switch(
                  value: _gradualWake,
                  onChanged: (val) => setState(() => _gradualWake = val),
                  activeColor: acc,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Vibration Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vibrate on ring',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                Switch(
                  value: _vibrate,
                  onChanged: (val) => setState(() => _vibrate = val),
                  activeColor: acc,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions: [ Cancel | Save ]
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _soundService.stop();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    child: Text('Cancel', style: TextStyle(color: ink)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _soundService.stop();
                      final hh =
                          _selectedTime.hour.toString().padLeft(2, '0');
                      final mm =
                          _selectedTime.minute.toString().padLeft(2, '0');
                      final alarm = Alarm(
                        id: widget.existingAlarm?.id ??
                            DateTime.now().millisecondsSinceEpoch,
                        time: '$hh:$mm',
                        label: _labelController.text.trim().isEmpty
                            ? 'Alarm'
                            : _labelController.text.trim(),
                        goal: _goalController.text.trim(),
                        days: _selectedDays,
                        isEnabled: true,
                        sound: _selectedSound,
                        volume: _volume,
                        vibrate: _vibrate,
                        mission: _mission,
                        gradualWake: _gradualWake,
                      );
                      widget.onSave(alarm);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: acc,
                      foregroundColor: widget.isDark
                          ? AppColors.darkAccentInk
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    child: const Text(
                      'Save Alarm',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionChip(
      String key, String label, Color acc, Color ink, Color mute) {
    final isSelected = _mission == key;

    return InkWell(
      onTap: () => setState(() => _mission = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? acc.withOpacity(0.2)
              : (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? acc : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? acc : ink,
          ),
        ),
      ),
    );
  }
}
