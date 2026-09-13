import 'dart:math' show log;

enum EqPreset {
  custom,
  classical,
  club,
  dance,
  enhanced_bass,
  enhanced_bass_and_tremble,
  enhanced_tremble,
  large_hall,
  live,
  party,
  pop,
  reggae,
  rock,
  ska,
  soft,
  soft_rock,
  techno,
}

Map<EqPreset, List<double>> eqPresets_10_band = {
  EqPreset.classical: //
      [0, 0, 0, 0, 0, 0, -7, -7, -7, -9],
  EqPreset.club: //
      [0, 0, 8, 5, 5, 5, 3, 0, 0, 0],
  EqPreset.dance: //
      [9, 7, 2, 0, 0, -5, -7, -7, 0, 0],
  EqPreset.enhanced_bass: //
      [-8, 9, 9, 5, 1, -4, -8, -10, -11, -11],
  EqPreset.enhanced_bass_and_tremble: //
      [7, 5, 0, -7, -4, 1, 8, 11, 12, 12],
  EqPreset.enhanced_tremble: //
      [-9, -9, -9, -4, 2, 11, 12, 12, 12, 12],
  EqPreset.large_hall: //
      [10, 10, 5, 5, 0, -4, -4, -4, 0, 0],
  EqPreset.live: //
      [-4, 0, 4, 5, 5, 5, 4, 2, 2, 2],
  EqPreset.party: //
      [7, 7, 0, 0, 0, 0, 0, 0, 7, 7],
  EqPreset.pop: //
      [-1, 4, 7, 8, 5, 0, -2, -2, -1, -1],
  EqPreset.reggae: //
      [0, 0, 0, -5, 0, 6, 6, 0, 0, 0],
  EqPreset.rock: //
      [8, 4, -5, -8, -3, 4, 8, 11, 11, 11],
  EqPreset.ska: //
      [-2, -4, -4, 0, 4, 5, 8, 9, 11, 9],
  EqPreset.soft: //
      [4, 1, 0, -2, 0, 4, 8, 9, 11, 12],
  EqPreset.soft_rock: //
      [4, 4, 2, 0, -4, -5, -3, 0, 2, 8],
  EqPreset.techno: //
      [8, 5, 0, -5, -4, 0, 8, 9, 9, 8],
};

Map<EqPreset, List<double>> eqPresets_5_band = {
  EqPreset.classical: //
      [0, 0, 0, -7, -9],
  EqPreset.club: //
      [0, 5, 5, 0, 0],
  EqPreset.dance: //
      [7, 0, -4, -7, 0],
  EqPreset.enhanced_bass: //
      [7, 5, -3, -10, -11],
  EqPreset.enhanced_bass_and_tremble: //
      [5, -6, 0, 11, 12],
  EqPreset.enhanced_tremble: //
      [-9, -5, 10, 12, 12],
  EqPreset.large_hall: //
      [10, 5, -3, -4, 0],
  EqPreset.live: //
      [0, 5, 5, 2, 2],
  EqPreset.party: //
      [7, 0, 0, 0, 7],
  EqPreset.pop: //
      [4, 8, 1, -2, -1],
  EqPreset.reggae: //
      [0, -4, 5, 0, 0],
  EqPreset.rock: //
      [4, -8, 3, 11, 11],
  EqPreset.ska: //
      [-4, 0, 5, 9, 9],
  EqPreset.soft: //
      [1, -2, 3, 9, 12],
  EqPreset.soft_rock: //
      [4, 0, -5, 0, 7],
  EqPreset.techno: //
      [5, -4, -1, 9, 8],
};

/* double interpolateGain(
    double freq, List<double> freqs_10_band, List<double> gains_10) {
  for (int i = 0; i < freqs_10_band.length - 1; i++) {
    final f1 = freqs_10_band[i];
    final f2 = freqs_10_band[i + 1];

    if (f1 <= freq && freq <= f2) {
      final gain1 = gains_10[i];
      final gain2 = gains_10[i + 1];

      if (freq == f1) return gain1;
      if (freq == f2) return gain2;

      // Logarithmic interpolation
      final ratio = (log(freq) - log(f1)) / (log(f2) - log(f1));
      return gain1 + (gain2 - gain1) * ratio;
    }
  }

  return 0.0;
}

    gLogger.log('gains: ');
    for (var key in eqPresets_10_band.keys) {
      final gains = eqPresets_10_band[key]!;
      final gains5 = CONFIG.frequencies_5_band.map((fTarget) {
        return interpolateGain(fTarget, CONFIG.frequencies_10_band, gains)
            .round();
      }).toList();
      gLogger.log('${key}: //    \n$gains5,');
    }

*/
