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
