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
    } else {
      _selectedTime = const TimeOfDay(hour: 6, minute: 30);
      _labelController = TextEditingController(text: 'Wake up');
      _goalController = TextEditingController(text: '');
      _selectedDays = [1, 2, 3, 4, 5];
      _selectedSound = 'zen_singing_bowl.wav';
      _volume = 0.9;
      _vibrate = true;
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
    final bg = widget.isDark ? AppColors.darkBg2 : AppColors.lightBg2;

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: bg.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(widget.isDark ? 0.15 : 0.6),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: mute.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Big 64pt Time Picker display
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                  builder: (context, child) {
                    return Theme(
                      data: widget.isDark ? ThemeData.dark() : ThemeData.light(),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
              child: Center(
                child: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.interTight(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2,
                    color: ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Label Field
            TextField(
              controller: _labelController,
              style: TextStyle(color: ink),
              decoration: InputDecoration(
                labelText: 'Label',
                labelStyle: TextStyle(color: mute),
                filled: true,
                fillColor: Colors.white.withOpacity(widget.isDark ? 0.08 : 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Goal Field
            TextField(
              controller: _goalController,
              style: TextStyle(color: ink),
              decoration: InputDecoration(
                labelText: 'Goal for this alarm (optional)',
                hintText: 'e.g. Study Physics at 6 AM',
                hintStyle: TextStyle(color: mute.withOpacity(0.6)),
                labelStyle: TextStyle(color: mute),
                filled: true,
                fillColor: Colors.white.withOpacity(widget.isDark ? 0.08 : 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sound Selector (24 studio sounds) with Play button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSound,
                    dropdownColor: bg,
                    style: TextStyle(color: ink, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Alarm Sound (24 available)',
                      labelStyle: TextStyle(color: mute),
                      filled: true,
                      fillColor:
                          Colors.white.withOpacity(widget.isDark ? 0.08 : 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: SoundService.availableSounds.map((s) {
                      return DropdownMenuItem(
                        value: s.filename,
                        child: Text('${s.title} (${s.category})'),
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
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _togglePreview,
                  icon: Icon(
                    _isPlayingPreview ? Icons.stop : Icons.play_arrow,
                    color: widget.isDark
                        ? AppColors.darkAccent
                        : AppColors.lightAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Day Selector Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isSelected = _selectedDays.contains(i);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(i);
                      } else {
                        _selectedDays.add(i);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? acc
                          : Colors.white.withOpacity(widget.isDark ? 0.1 : 0.4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (widget.isDark
                                ? AppColors.darkAccentInk
                                : Colors.white)
                            : ink,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),

            // Volume & Vibration
            Row(
              children: [
                Icon(Icons.volume_up, color: mute, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.1,
                    max: 1.0,
                    activeColor: acc,
                    onChanged: (v) {
                      setState(() => _volume = v);
                    },
                  ),
                ),
                Text(
                  '${(_volume * 100).toInt()}%',
                  style: TextStyle(color: mute, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
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
}
