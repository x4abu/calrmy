import 'package:audioplayers/audioplayers.dart';

class SoundItem {
  final String filename;
  final String title;
  final String category;
  final String description;

  const SoundItem({
    required this.filename,
    required this.title,
    required this.category,
    required this.description,
  });
}

class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlaying;

  static const List<SoundItem> availableSounds = [
    // Gentle Wake
    SoundItem(
      filename: 'zen_singing_bowl.wav',
      title: 'Zen Singing Bowl',
      category: 'Gentle Wake',
      description: 'Resonant Tibetan bell with deep acoustic shimmer',
    ),
    SoundItem(
      filename: 'gentle_marimba.wav',
      title: 'Gentle Marimba',
      category: 'Gentle Wake',
      description: 'Warm wooden rising pentatonic arpeggio',
    ),
    SoundItem(
      filename: 'dawn_harp.wav',
      title: 'Dawn Harp',
      category: 'Gentle Wake',
      description: 'Ethereal cascading acoustic harp chords',
    ),
    SoundItem(
      filename: 'sunrise_acoustic.wav',
      title: 'Sunrise Acoustic',
      category: 'Gentle Wake',
      description: 'Warm fingerpicked acoustic morning tone',
    ),
    SoundItem(
      filename: 'morning_dew_bells.wav',
      title: 'Morning Dew Bells',
      category: 'Gentle Wake',
      description: 'Crisp crystal glockenspiel morning melody',
    ),
    SoundItem(
      filename: 'peaceful_kalimba.wav',
      title: 'Peaceful Kalimba',
      category: 'Gentle Wake',
      description: 'Delicate African thumb piano tune',
    ),

    // Nature & Ambient
    SoundItem(
      filename: 'forest_birds_stream.wav',
      title: 'Forest Birds & Stream',
      category: 'Nature',
      description: 'Morning songbirds over a crystal babbling brook',
    ),
    SoundItem(
      filename: 'ocean_breeze.wav',
      title: 'Ocean Breeze',
      category: 'Nature',
      description: 'Soothing tide swell with distant morning chime',
    ),
    SoundItem(
      filename: 'bamboo_windchimes.wav',
      title: 'Bamboo Windchimes',
      category: 'Nature',
      description: 'Organic tuned bamboo hollow windchimes',
    ),
    SoundItem(
      filename: 'tibetan_gong.wav',
      title: 'Tibetan Temple Gong',
      category: 'Nature',
      description: 'Deep grounding 108Hz harmonic temple gong',
    ),

    // Soft Melody & Ambient Synth
    SoundItem(
      filename: 'celestial_pad.wav',
      title: 'Celestial Pad',
      category: 'Ambient Synth',
      description: 'Lush ambient synthesizer harmonic sunrise',
    ),
    SoundItem(
      filename: 'golden_hour_chime.wav',
      title: 'Golden Hour Chime',
      category: 'Ambient Synth',
      description: '4-note ascending cathedral harmonic bells',
    ),
    SoundItem(
      filename: 'lofi_sunrise.wav',
      title: 'Lo-Fi Sunrise',
      category: 'Ambient Synth',
      description: 'Vintage Rhodes electric piano Neo-Soul chords',
    ),
    SoundItem(
      filename: 'cosmic_awakening.wav',
      title: 'Cosmic Awakening',
      category: 'Ambient Synth',
      description: 'Spacious reverbed synthesizer with warm delay',
    ),
    SoundItem(
      filename: 'aurora_strings.wav',
      title: 'Aurora Strings',
      category: 'Ambient Synth',
      description: 'Slow-bowed orchestral string chord crescendo',
    ),
    SoundItem(
      filename: 'crystal_cascade.wav',
      title: 'Crystal Cascade',
      category: 'Ambient Synth',
      description: 'Cascading falling star crystal tones',
    ),
    SoundItem(
      filename: 'quantum_vibe.wav',
      title: 'Quantum Vibe',
      category: 'Ambient Synth',
      description: 'Warm sub-bass lift into high resonant ping',
    ),

    // Classic & Modern Alarms
    SoundItem(
      filename: 'digital_pulse.wav',
      title: 'Digital Pulse',
      category: 'Classic & Modern',
      description: 'Sleek minimal triple-pulse electronic chime',
    ),
    SoundItem(
      filename: 'classic_twin_bell.wav',
      title: 'Classic Twin Bell',
      category: 'Classic & Modern',
      description: 'Nostalgic mechanical twin-bell alarm clock',
    ),
    SoundItem(
      filename: 'retro_digital_beep.wav',
      title: 'Retro Digital Beep',
      category: 'Classic & Modern',
      description: 'Iconic 4-beep digital bedside clock cadence',
    ),
    SoundItem(
      filename: 'radar_sonar.wav',
      title: 'Radar Sonar',
      category: 'Classic & Modern',
      description: 'Submarine acoustic sonar ping with deep decay',
    ),
    SoundItem(
      filename: 'energetic_synth.wav',
      title: 'Energetic Synth',
      category: 'Classic & Modern',
      description: 'Upbeat 128 BPM electronic wake-up arpeggio',
    ),
    SoundItem(
      filename: 'arcade_rise.wav',
      title: 'Arcade Rise',
      category: 'Classic & Modern',
      description: 'Joyful 8-bit chip-tune fanfare',
    ),
    SoundItem(
      filename: 'tempo_escalation.wav',
      title: 'Tempo Escalation',
      category: 'Classic & Modern',
      description: 'Accelerating pulse designed for heavy sleepers',
    ),
  ];

  String? get currentlyPlaying => _currentlyPlaying;

  Future<void> previewSound(String filename, {double volume = 0.9}) async {
    if (_currentlyPlaying == filename) {
      await stop();
      return;
    }
    await stop();
    _currentlyPlaying = filename;
    await _player.setVolume(volume);
    await _player.play(AssetSource('sounds/$filename'));
    _player.onPlayerComplete.listen((_) {
      _currentlyPlaying = null;
    });
  }

  Future<void> playLooping(String filename, {double volume = 0.9}) async {
    await stop();
    _currentlyPlaying = filename;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(volume);
    await _player.play(AssetSource('sounds/$filename'));
  }

  Future<void> stop() async {
    _currentlyPlaying = null;
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }
}
