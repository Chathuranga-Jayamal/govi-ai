/// A specific crop+disease pair to ask the real /advisory endpoint about,
/// plus a human-readable label for chat bubbles/history. The backend only
/// accepts this structured shape (no free-text query field), so every real
/// advisory fetch — seeded from a diagnosis or from a suggested chip — goes
/// through one of these rather than an arbitrary typed question.
class AdvisoryTopic {
  const AdvisoryTopic({
    required this.crop,
    required this.disease,
    required this.label,
  });

  final String crop;
  final String disease;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is AdvisoryTopic &&
      other.crop == crop &&
      other.disease == disease &&
      other.label == label;

  @override
  int get hashCode => Object.hash(crop, disease, label);
}
