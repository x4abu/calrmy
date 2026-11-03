import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class TimerStopwatchScreen extends StatefulWidget {
  final bool isDark;

  const TimerStopwatchScreen({super.key, required this.isDark});

  @override
  State<TimerStopwatchScreen> createState() => _TimerStopwatchScreenState();
}

class _TimerStopwatchScreenState extends State<TimerStopwatchScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMode = 0; // 0 = Stopwatch, 1 = Timer

  // Stopwatch state
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTicker;
  final List<int> _laps = [];

  // Timer state
  int _timerTotalSeconds = 300; // default 5 mins
  int _timerRemainingSeconds = 300;
  bool _timerRunning = false;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _stopwatchTicker?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // --- Stopwatch Methods ---
  void _startStopwatch() {
    _stopwatch.start();
    _stopwatchTicker =
        Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _pauseStopwatch() {
    _stopwatch.stop();
    _stopwatchTicker?.cancel();
    setState(() {});
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    _laps.clear();
    setState(() {});
  }

  void _recordLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _stopwatch.elapsedMilliseconds);
      });
    }
  }

  String _formatStopwatchTime(int ms) {
    final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final hundredths = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$hundredths';
  }

  // --- Timer Methods ---
  void _setTimerPreset(int seconds) {
    if (_timerRunning) _pauseTimer();
    setState(() {
      _timerTotalSeconds = seconds;
      _timerRemainingSeconds = seconds;
    });
  }

  void _startTimer() {
    if (_timerRemainingSeconds <= 0) {
      _timerRemainingSeconds = _timerTotalSeconds;
    }
    _timerRunning = true;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerRemainingSeconds > 0) {
        setState(() => _timerRemainingSeconds--);
      } else {
        _timerRunning = false;
        timer.cancel();
        SoundService.instance.playLooping('zen_singing_bowl.wav', volume: 0.9);
        _showTimerCompleteDialog();
        setState(() {});
      }
    });
    setState(() {});
  }

  void _pauseTimer() {
    _timerRunning = false;
    _countdownTimer?.cancel();
    setState(() {});
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => _timerRemainingSeconds = _timerTotalSeconds);
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.darkCard : AppColors.lightCard,
        title: const Text('⏳ Time is Up!'),
        content: const Text('Your countdown timer has completed.'),
        actions: [
          TextButton(
            onPressed: () {
              SoundService.instance.stop();
              Navigator.pop(context);
            },
            child: const Text('Dismiss', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  String _formatTimerTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? AppColors.darkInk : AppColors.lightInk;
    final mute = widget.isDark ? AppColors.darkMute : AppColors.lightMute;
    final acc = widget.isDark ? AppColors.darkAccent : AppColors.lightAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mode Switcher Header [ Stopwatch | Timer ]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMode = 0),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 0
                            ? (widget.isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedMode == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 16,
                              color: _selectedMode == 0 ? acc : mute),
                          const SizedBox(width: 6),
                          Text(
                            'Stopwatch',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedMode == 0 ? ink : mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMode = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 1
                            ? (widget.isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedMode == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_bottom,
                              size: 16,
                              color: _selectedMode == 1 ? acc : mute),
                          const SizedBox(width: 6),
                          Text(
                            'Timer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedMode == 1 ? ink : mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Render Selected Mode
          if (_selectedMode == 0)
            _buildStopwatchView(ink, mute, acc)
          else
            _buildTimerView(ink, mute, acc),
        ],
      ),
    );
  }

  // --- STOPWATCH VIEW ---
  Widget _buildStopwatchView(Color ink, Color mute, Color acc) {
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final timeStr = _formatStopwatchTime(elapsedMs);

    return Column(
      children: [
        // Giant Bezel Time Display
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDark
                ? AppColors.darkCard.withOpacity(0.5)
                : AppColors.lightCard.withOpacity(0.6),
            border: Border.all(
              color: _stopwatch.isRunning
                  ? acc.withOpacity(0.6)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08)),
              width: 3,
            ),
            boxShadow: [
              if (_stopwatch.isRunning)
                BoxShadow(
                  color: acc.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'STOPWATCH',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: mute,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeStr,
                  style: GoogleFonts.interTight(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Action Buttons: [ Lap | Start / Pause | Reset ]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Lap Button
            ElevatedButton(
              onPressed: _stopwatch.isRunning ? _recordLap : null,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                foregroundColor: ink,
                elevation: 0,
              ),
              child: const Text('Lap',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),

            // Start / Pause Primary Button
            ElevatedButton(
              onPressed: _stopwatch.isRunning
                  ? _pauseStopwatch
                  : _startStopwatch,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(26),
                backgroundColor: _stopwatch.isRunning
                    ? const Color(0xFFEF4444)
                    : acc,
                foregroundColor: Colors.black,
                elevation: 4,
              ),
              child: Icon(
                _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: _stopwatch.isRunning ? Colors.white : Colors.black,
              ),
            ),

            // Reset Button
            ElevatedButton(
              onPressed: elapsedMs > 0 ? _resetStopwatch : null,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                foregroundColor: ink,
                elevation: 0,
              ),
              child: const Text('Reset',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Lap Times List
        if (_laps.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'LAPS (${_laps.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: mute,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _laps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final lapMs = _laps[index];
              final lapNum = _laps.length - index;

              return GlassBox(
                isDark: widget.isDark,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lap ${lapNum.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    Text(
                      _formatStopwatchTime(lapMs),
                      style: GoogleFonts.interTight(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: acc,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // --- TIMER VIEW ---
  Widget _buildTimerView(Color ink, Color mute, Color acc) {
    final progress = _timerTotalSeconds > 0
        ? (_timerRemainingSeconds / _timerTotalSeconds)
        : 0.0;
    final timeStr = _formatTimerTime(_timerRemainingSeconds);

    return Column(
      children: [
        // Circular Progress Timer Display
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(acc),
              ),
            ),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isDark
                    ? AppColors.darkCard.withOpacity(0.5)
                    : AppColors.lightCard.withOpacity(0.6),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timerRunning ? 'COUNTDOWN' : 'READY',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: mute,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: GoogleFonts.interTight(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Quick Preset Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTimerPresetChip('1m Tea', 60, acc, ink, mute),
              const SizedBox(width: 8),
              _buildTimerPresetChip('5m Meditate', 300, acc, ink, mute),
              const SizedBox(width: 8),
              _buildTimerPresetChip('15m Power Nap', 900, acc, ink, mute),
              const SizedBox(width: 8),
              _buildTimerPresetChip('25m Pomodoro', 1500, acc, ink, mute),
              const SizedBox(width: 8),
              _buildTimerPresetChip('45m Deep Focus', 2700, acc, ink, mute),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Action Controls: [ Reset | Start / Pause ]
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _timerRemainingSeconds != _timerTotalSeconds
                  ? _resetTimer
                  : null,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                backgroundColor: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                foregroundColor: ink,
                elevation: 0,
              ),
              child: const Text('Reset',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: _timerRunning ? _pauseTimer : _startTimer,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(26),
                backgroundColor: _timerRunning
                    ? const Color(0xFFEF4444)
                    : acc,
                foregroundColor: Colors.black,
                elevation: 4,
              ),
              child: Icon(
                _timerRunning ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: _timerRunning ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerPresetChip(
      String label, int seconds, Color acc, Color ink, Color mute) {
    final isSelected = _timerTotalSeconds == seconds;

    return InkWell(
      onTap: () => _setTimerPreset(seconds),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? acc.withOpacity(0.2)
              : (widget.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? acc
                : (widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? acc : ink,
          ),
        ),
      ),
    );
  }
}
