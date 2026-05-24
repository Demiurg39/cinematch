class GenreHarmonyData {
  final Map<String, double> userWeights;
  final Map<String, double> partnerWeights;
  final Map<String, double> sharedWeights;

  const GenreHarmonyData({
    required this.userWeights,
    required this.partnerWeights,
    required this.sharedWeights,
  });

  Set<String> get allGenres => {
        ...userWeights.keys,
        ...partnerWeights.keys,
        ...sharedWeights.keys,
      };

  bool get isEmpty =>
      userWeights.isEmpty && partnerWeights.isEmpty && sharedWeights.isEmpty;
}